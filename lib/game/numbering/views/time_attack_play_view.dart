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
  final Set<String> _recentDigitSets = {};
  final _editorKey = GlobalKey<_FormulaEditorState>();
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
    
    if (SimulationMode.isEnabled.value) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _timer?.cancel();
        setState(() {
          _secondsRemaining = 0;
          _highestNumber = 999;
          _totalScore = 12345;
          _isFinished = true;
        });
        unawaited(_handleTimeExpired());
      });
    }
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
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.9, end: 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: ((scale - 0.9) / 0.1).clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onShowLevels();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          padding: const EdgeInsets.all(12),
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _restartGame();
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: widget.accent,
                          padding: const EdgeInsets.all(12),
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onShowLevels();
                          Get.to(
                            () => const RankingScreen(showCloseButton: true),
                            transition: Transition.zoom,
                            duration: const Duration(milliseconds: 250),
                          );
                        },
                        icon: const Icon(
                          Icons.bar_chart_rounded,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          padding: const EdgeInsets.all(12),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        _GameHeader(
          title: 'Time Attack · ${_formatTimer(_secondsRemaining)}',
          leading: Row(
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
          trailing: Text(
            'BEST $_highestNumber  TOTAL $_totalScore',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
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
