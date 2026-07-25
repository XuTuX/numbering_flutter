import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/screens/ranking/ranking_screen.dart';
import 'package:numbering/services/time_attack_score_service.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_spacing.dart';
import 'package:numbering/widgets/dialogs/animated_game_dialog.dart';

import '../widgets/formula_editor.dart';
import '../widgets/game_header.dart';

class TimeAttackPlayView extends StatefulWidget {
  const TimeAttackPlayView({
    super.key,
    required this.session,
    required this.accent,
    required this.onShowLevels,
  });

  final GameSessionConfig session;
  final Color accent;
  final VoidCallback onShowLevels;

  @override
  State<TimeAttackPlayView> createState() => _TimeAttackPlayViewState();
}

class _TimeAttackPlayViewState extends State<TimeAttackPlayView> {
  String _digits = '';
  final _editorKey = GlobalKey<FormulaEditorState>();
  Timer? _timer;
  Timer? _finishRetryTimer;
  final Stopwatch _countdownStopwatch = Stopwatch();
  TimeAttackSession? _session;
  int _secondsRemaining = 180;
  int _highestNumber = 0;
  int _totalScore = 0;
  bool _isStarting = true;
  bool _isSubmitting = false;
  bool _isFinishing = false;
  bool _isFinished = false;
  String? _startError;
  int _startRequestId = 0;
  int _finishRetryAttempt = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_startNewSession());
  }

  Future<void> _startNewSession() async {
    final requestId = ++_startRequestId;
    _timer?.cancel();
    _finishRetryTimer?.cancel();
    _countdownStopwatch
      ..stop()
      ..reset();
    setState(() {
      _session = null;
      _isStarting = true;
      _isSubmitting = false;
      _isFinishing = false;
      _isFinished = false;
      _secondsRemaining = 180;
      _highestNumber = 0;
      _totalScore = 0;
      _startError = null;
      _digits = '';
      _finishRetryAttempt = 0;
    });

    try {
      final session = await Get.find<TimeAttackScoreService>().startSession();
      if (!mounted || requestId != _startRequestId) return;
      setState(() {
        _session = session;
        _digits = session.digits;
        _highestNumber = session.highestNumber;
        _totalScore = session.totalScore;
        _isStarting = false;
      });
      _startTimer(session.remainingMilliseconds);
    } on TimeAttackServiceException catch (error) {
      if (!mounted || requestId != _startRequestId) return;
      setState(() {
        _isStarting = false;
        _startError = error.userMessage;
      });
    }
  }

  void _startTimer(int remainingMilliseconds) {
    _timer?.cancel();
    _countdownStopwatch
      ..reset()
      ..start();
    final countdownMilliseconds = remainingMilliseconds.clamp(0, 180000);

    void syncRemaining() {
      final milliseconds =
          countdownMilliseconds - _countdownStopwatch.elapsedMilliseconds;
      final remaining = milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
      if (!mounted) return;
      if (_secondsRemaining != remaining) {
        setState(() => _secondsRemaining = remaining);
      }
      if (remaining == 0) {
        _timer?.cancel();
        _countdownStopwatch.stop();
        if (!_isFinished) {
          setState(() => _isFinished = true);
          unawaited(_handleTimeExpired());
        }
      }
    }

    syncRemaining();
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => syncRemaining(),
    );
  }

  Future<void> _handleValidSubmission(String expression, int score) async {
    final session = _session;
    if (_isFinished || _isSubmitting || session == null) return;

    setState(() => _isSubmitting = true);
    try {
      final updated = await Get.find<TimeAttackScoreService>().submitSolution(
        sessionId: session.id,
        puzzleIndex: session.puzzleIndex,
        expression: expression,
      );
      if (!mounted) return;
      setState(() {
        _session = updated;
        _digits = updated.digits;
        _highestNumber = updated.highestNumber;
        _totalScore = updated.totalScore;
      });
      _startTimer(updated.remainingMilliseconds);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editorKey.currentState?.reset();
      });
    } on TimeAttackServiceException catch (error) {
      if (!mounted) return;
      if (error.code == 'session_expired') {
        _timer?.cancel();
        _countdownStopwatch.stop();
        setState(() => _isFinished = true);
        unawaited(_handleTimeExpired());
      } else {
        _editorKey.currentState?.showMessage(error.userMessage);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleTimeExpired() async {
    final session = _session;
    if (session == null || _isFinishing) return;
    _finishRetryTimer?.cancel();
    _isFinishing = true;

    try {
      final result =
          await Get.find<TimeAttackScoreService>().finishSession(session.id);
      _highestNumber = result.highestNumber;
      _totalScore = result.totalScore;
      _finishRetryAttempt = 0;
    } on TimeAttackServiceException catch (error) {
      _isFinishing = false;
      if (!mounted) return;
      if (error.code == 'session_active' ||
          error.code == 'network_error' ||
          error.code == 'server_error') {
        const retryDelays = <Duration>[
          Duration(milliseconds: 250),
          Duration(milliseconds: 500),
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 5),
        ];
        final retryIndex = _finishRetryAttempt.clamp(0, retryDelays.length - 1);
        _finishRetryAttempt++;
        _finishRetryTimer = Timer(
          retryDelays[retryIndex],
          () => unawaited(_handleTimeExpired()),
        );
        return;
      }
      _editorKey.currentState?.showMessage(error.userMessage);
      return;
    }

    if (!mounted) return;
    _isFinishing = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: AnimatedGameDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: widget.accent,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_highestNumber',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: widget.accent,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalScore',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              GameDialogButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onShowLevels();
                },
                icon: Icons.close_rounded,
              ),
              GameDialogButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(_startNewSession());
                },
                icon: Icons.refresh_rounded,
                backgroundColor: widget.accent,
                iconColor: Colors.white,
              ),
              GameDialogButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onShowLevels();
                  Get.to(
                    () => const RankingScreen(showCloseButton: true),
                    transition: Transition.zoom,
                    duration: const Duration(milliseconds: 250),
                  );
                },
                icon: Icons.bar_chart_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimer(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_startError != null || _digits.isEmpty) {
      return Center(
        child: IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: _startError,
          onPressed: () => unawaited(_startNewSession()),
        ),
      );
    }

    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        GameHeader(
          title: 'BEST $_highestNumber  TOTAL $_totalScore',
          titleWidget: Text(
            'BEST $_highestNumber  TOTAL $_totalScore',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              _formatTimer(_secondsRemaining),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: '나가기',
                onPressed: widget.onShowLevels,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: '다시하기',
                onPressed: () => unawaited(_startNewSession()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: AbsorbPointer(
            absorbing: _isFinished || _isSubmitting,
            child: FormulaEditor(
              key: _editorKey,
              digits: _digits.split(''),
              availableOperators: const {'+', '-', '×', '÷', '='},
              accent: widget.accent,
              isLandscape: isLandscape,
              visibleHints: const [],
              requiresEquals: true,
              allowDigitReordering: true,
              validateExpression: (expression) => validateReorderableEquality(
                digitString: _digits,
                expression: expression,
              ),
              onValidSubmission: (expression, score) =>
                  unawaited(_handleValidSubmission(expression, score)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _startRequestId++;
    _timer?.cancel();
    _finishRetryTimer?.cancel();
    _countdownStopwatch.stop();
    super.dispose();
  }
}
