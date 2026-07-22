part of '../numbering_game_page.dart';

class _DailyPlayView extends StatefulWidget {
  const _DailyPlayView({
    super.key,
    required this.session,
    required this.accent,
    required this.onShowLevels,
  });

  final GameSessionConfig session;
  final Color accent;
  final VoidCallback onShowLevels;

  @override
  State<_DailyPlayView> createState() => _DailyPlayViewState();
}

class _DailyPlayViewState extends State<_DailyPlayView> {
  late final String _digits;
  final _editorKey = GlobalKey<_FormulaEditorState>();
  bool _isSubmitting = false;
  String? _submissionError;
  String? _pendingExpression;

  @override
  void initState() {
    super.initState();
    final seed = widget.session.seed ?? 0;
    _digits = generateDailyNumberingPuzzle(seed);
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
    setState(() => _isSubmitting = false);
    final score = serverResult?.verifiedScore ?? clientScore;
    final rank = serverResult?.rank;

    showDialog<void>(
        context: context,
        barrierDismissible: !widget.session.isOfficialScoreSubmission,
        builder: (context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              '성공!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  rank == null
                      ? (widget.session.isOfficialScoreSubmission
                          ? '오늘의 점수가 안전하게 저장되었습니다.'
                          : '연습 기록은 공식 랭킹에 반영되지 않습니다.')
                      : '오늘의 순위: $rank위',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (!widget.session.isOfficialScoreSubmission)
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _editorKey.currentState?.reset();
                  },
                  style: FilledButton.styleFrom(backgroundColor: widget.accent),
                  child: const Text('계속하기'),
                ),
              if (widget.session.isOfficialScoreSubmission)
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Get.to(
                      () => RankingScreen(
                        isDailyOnly: true,
                        dailyDateKey: serverResult?.dateKey,
                      ),
                      transition: Transition.zoom,
                      duration: const Duration(milliseconds: 250),
                    );
                  },
                  style: FilledButton.styleFrom(backgroundColor: widget.accent),
                  child: const Text('오늘의 랭킹'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onShowLevels();
                },
                child: const Text('나가기'),
              )
            ],
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
        _GameHeader(
          title: '오늘의 퍼즐',
          backLabel: '나가기',
          onBack: widget.onShowLevels,
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
          child: _FormulaEditor(
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
            onValidSubmission: _handleSubmission,
          ),
        ),
      ],
    );
  }
}
