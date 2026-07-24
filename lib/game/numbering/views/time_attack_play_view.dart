part of '../numbering_game_page.dart';

class _TimeAttackPlayView extends StatefulWidget {
  const _TimeAttackPlayView({
    super.key,
    required this.session,
    required this.accent,
    required this.onShowLevels,
  });

  final GameSessionConfig session;
  final Color accent;
  final VoidCallback onShowLevels;

  @override
  State<_TimeAttackPlayView> createState() => _TimeAttackPlayViewState();
}

class _TimeAttackPlayViewState extends State<_TimeAttackPlayView> {
  static const int _initialTimeSeconds = 180; // 3 minutes

  late String _digits;
  final _editorKey = GlobalKey<_FormulaEditorState>();
  Timer? _timer;
  int _secondsRemaining = _initialTimeSeconds;
  int _highestNumber = 0;
  int _totalScore = 0;
  DateTime? _highestNumberAchievedAt;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _digits = generateDailyNumberingPuzzle(DateTime.now().microsecondsSinceEpoch);
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

  void _nextPuzzle() {
    setState(() {
      _digits = generateDailyNumberingPuzzle(
        DateTime.now().microsecondsSinceEpoch + _secondsRemaining,
      );
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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '종료',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BEST $_highestNumber',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: widget.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '총점: $_totalScore점',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.to(
                  () => const RankingScreen(),
                  transition: Transition.zoom,
                  duration: const Duration(milliseconds: 250),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: widget.accent),
              child: const Text('순위 보기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onShowLevels();
              },
              child: const Text('나가기'),
            ),
          ],
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
        _GameHeader(
          title: 'Time Attack · ${_formatTimer(_secondsRemaining)}',
          backLabel: '나가기',
          onBack: () => widget.onShowLevels(),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BEST $_highestNumber  TOTAL $_totalScore',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: AbsorbPointer(
            absorbing: _isFinished,
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
