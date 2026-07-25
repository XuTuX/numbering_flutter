import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_spacing.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/numbering_random.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';
import 'package:numbering/screens/ranking/ranking_screen.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/widgets/dialogs/animated_game_dialog.dart';
import '../widgets/game_header.dart';
import '../widgets/formula_editor.dart';

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
  static const int _initialTimeSeconds = 180; // 3 minutes

  late String _digits;
  final Set<String> _recentDigitSets = {};
  final _editorKey = GlobalKey<FormulaEditorState>();
  Timer? _timer;
  int _secondsRemaining = _initialTimeSeconds;
  int _solvesCount = 0;
  int _highestNumber = 0;
  int _totalScore = 0;
  DateTime? _highestNumberAchievedAt;
  bool _isFinished = false;

  int _getDigitCountForSolves(int solves) {
    if (solves < 2) return 4;
    if (solves < 4) return 5;
    return 6;
  }

  String _generateUniquePuzzle(int digitCount) {
    final puzzle = generateTimeAttackPuzzle(
      digitCount,
      null,
      _recentDigitSets,
    );
    _recentDigitSets.add(puzzle);
    _recentDigitSets.add((puzzle.split('')..sort()).join());
    if (_recentDigitSets.length > 40) {
      _recentDigitSets.removeAll(_recentDigitSets.take(20).toList());
    }
    return puzzle;
  }

  @override
  void initState() {
    super.initState();
    _digits = _generateUniquePuzzle(_getDigitCountForSolves(0));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isFinished = true;
        });
        unawaited(_handleTimeExpired());
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _restartGame() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _initialTimeSeconds;
      _solvesCount = 0;
      _highestNumber = 0;
      _totalScore = 0;
      _highestNumberAchievedAt = null;
      _isFinished = false;
      _digits = _generateUniquePuzzle(_getDigitCountForSolves(0));
    });
    _editorKey.currentState?.reset();
    _startTimer();
  }

  void _nextPuzzle() {
    setState(() {
      _digits = _generateUniquePuzzle(_getDigitCountForSolves(_solvesCount));
    });
    _editorKey.currentState?.reset();
  }

  Future<void> _handleValidSubmission(String expression, int score) async {
    if (_isFinished) return;

    setState(() {
      _totalScore += score;
      if (score > _highestNumber) {
        _highestNumber = score;
        _highestNumberAchievedAt = DateTime.now();
      }
      _solvesCount++;
    });

    _nextPuzzle();
  }

  Future<void> _handleTimeExpired() async {
    final authService = Get.find<AuthService>();
    final nickname = authService.userNickname.value ?? 'Player';
    final scoreService = Get.find<TimeAttackScoreService>();

    await scoreService.submitRecord(
      nickname: nickname,
      highestNumber: _highestNumber,
      totalScore: _totalScore,
      achievedAt: _highestNumberAchievedAt ?? DateTime.now(),
    );

    if (!mounted) return;

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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                  _restartGame();
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
            padding: const EdgeInsets.only(left: 8.0),
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
                onPressed: () => widget.onShowLevels(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: '다시하기',
                onPressed: _restartGame,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: AbsorbPointer(
            absorbing: _isFinished,
            child: FormulaEditor(
              key: _editorKey,
              digits: _digits.split(''),
              availableOperators: const {'+', '-', '×', '÷', '='},
              accent: widget.accent,
              isLandscape: isLandscape,
              visibleHints: const [],
              requiresEquals: true,
              allowDigitReordering: true,
              validateExpression: (expression) => validateDailyPuzzleFormula(
                digitString: _digits,
                expression: expression,
              ),
              onValidSubmission: (expr, score) =>
                  unawaited(_handleValidSubmission(expr, score)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
