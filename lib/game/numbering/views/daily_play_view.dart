import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_spacing.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/numbering_random.dart';
import 'package:numbering/services/numbering_score_service.dart';
import 'package:numbering/controllers/daily_puzzle_controller.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/screens/ranking/ranking_screen.dart';
import 'package:numbering/widgets/dialogs/animated_game_dialog.dart';
import '../widgets/game_header.dart';
import '../widgets/formula_editor.dart';

class DailyPlayView extends StatefulWidget {
  const DailyPlayView({
    super.key,
    required this.session,
    required this.accent,
    required this.onShowLevels,
  });

  final GameSessionConfig session;
  final Color accent;
  final VoidCallback onShowLevels;

  @override
  State<DailyPlayView> createState() => _DailyPlayViewState();
}

class _DailyPlayViewState extends State<DailyPlayView> {
  late final String _digits;
  final _editorKey = GlobalKey<FormulaEditorState>();
  DailyPuzzleProgress? _restoredProgress;
  DailyPuzzleProgress? _pendingProgress;
  Timer? _progressSaveTimer;
  Future<void> _progressSaveQueue = Future<void>.value();
  bool _isLoadingProgress = false;
  bool _isCompleted = false;
  bool _isSubmitting = false;
  String? _submissionError;
  String? _pendingExpression;

  @override
  void initState() {
    super.initState();
    final seed = widget.session.seed ?? 0;
    _digits = generateDailyNumberingPuzzle(seed);
    if (widget.session.isOfficialScoreSubmission) {
      _isLoadingProgress = true;
      unawaited(_loadProgress());
    }
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await Get.find<NumberingScoreService>().getDailyProgress(
        periodKey: widget.session.dateKey ?? '',
        seed: widget.session.seed ?? 0,
      );
      if (!mounted) return;
      setState(() {
        _restoredProgress = progress;
        _isLoadingProgress = false;
      });
    } on NumberingServiceException {
      if (!mounted) return;
      setState(() => _isLoadingProgress = false);
    }
  }

  void _handleProgressChanged(DailyPuzzleProgress progress) {
    if (!widget.session.isOfficialScoreSubmission || _isCompleted) return;
    _pendingProgress = progress;
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_flushProgress()),
    );
  }

  Future<void> _flushProgress() async {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    final progress = _pendingProgress;
    if (progress == null || _isCompleted) return;
    _pendingProgress = null;
    _progressSaveQueue = _progressSaveQueue.then((_) async {
      try {
        await Get.find<NumberingScoreService>().saveDailyProgress(
          periodKey: widget.session.dateKey ?? '',
          seed: widget.session.seed ?? 0,
          progress: progress,
        );
      } on NumberingServiceException {
        _pendingProgress ??= progress;
      }
    });
    await _progressSaveQueue;
  }

  Future<void> _handleExit() async {
    await _flushProgress();
    widget.onShowLevels();
  }

  Future<void> _handleSubmission(String expression, int clientScore) async {
    if (_isSubmitting) return;
    _pendingExpression = expression;
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    NumberingSubmissionResult? serverResult;
    if (widget.session.isOfficialScoreSubmission) {
      try {
        serverResult =
            await Get.find<NumberingScoreService>().submitDailyResult(
          seed: widget.session.seed ?? 0,
          expression: expression,
        );
      } on NumberingServiceException catch (error) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _submissionError = error.userMessage;
        });
        return;
      }
    } else {
      final dateKey = widget.session.dateKey ?? '';
      Get.find<DailyPuzzleController>().submitDailyScore(dateKey, clientScore);
    }

    if (!mounted) return;
    _isCompleted = true;
    _pendingProgress = null;
    _progressSaveTimer?.cancel();
    if (widget.session.isOfficialScoreSubmission) {
      unawaited(
        Get.find<NumberingScoreService>().clearDailyProgress(
          periodKey: widget.session.dateKey ?? '',
        ),
      );
    }
    setState(() => _isSubmitting = false);
    final score = serverResult?.verifiedScore ?? clientScore;

    showDialog<void>(
        context: context,
        barrierDismissible: !widget.session.isOfficialScoreSubmission,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(24),
            child: AnimatedGameDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '성공!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '점수: $score',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: widget.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.session.isOfficialScoreSubmission
                        ? '점수가 저장되었습니다. 참가자들의 순위를 확인해 보세요.'
                        : '연습 기록은 공식 랭킹에 반영되지 않습니다.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                GameDialogButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    unawaited(_handleExit());
                  },
                  icon: Icons.close_rounded,
                ),
                if (!widget.session.isOfficialScoreSubmission)
                  GameDialogButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _editorKey.currentState?.reset();
                    },
                    icon: Icons.refresh_rounded,
                    backgroundColor: widget.accent,
                    iconColor: Colors.white,
                  ),
                if (widget.session.isOfficialScoreSubmission)
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
                    backgroundColor: widget.accent,
                    iconColor: Colors.white,
                  ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        GameHeader(
          title: '오늘의 퍼즐',
          backLabel: '나가기',
          onBack: () => unawaited(_handleExit()),
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isSubmitting)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (_submissionError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Text(
                  _submissionError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pendingExpression == null
                      ? null
                      : () => _handleSubmission(
                            _pendingExpression!,
                            validateDailyPuzzleFormula(
                              digitString: _digits,
                              expression: _pendingExpression!,
                            ).value!,
                          ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('제출 다시 시도'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _isLoadingProgress
              ? const Center(child: CircularProgressIndicator())
              : FormulaEditor(
                  key: _editorKey,
                  digits: _digits.split(''),
                  availableOperators: const {'+', '-', '×', '^', '='},
                  accent: widget.accent,
                  isLandscape: isLandscape,
                  visibleHints: const [],
                  requiresEquals: true,
                  allowDigitReordering: true,
                  initialProgress: _restoredProgress,
                  onProgressChanged: _handleProgressChanged,
                  validateExpression: (expression) =>
                      validateDailyPuzzleFormula(
                    digitString: _digits,
                    expression: expression,
                  ),
                  onValidSubmission: _handleSubmission,
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    if (_pendingProgress != null && !_isCompleted) {
      unawaited(_flushProgress());
    }
    super.dispose();
  }
}
