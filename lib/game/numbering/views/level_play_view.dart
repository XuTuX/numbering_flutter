part of '../numbering_game_page.dart';

// ─── 레벨 플레이 뷰 ─────────────────────────────────────────

class _LevelPlayView extends StatefulWidget {
  const _LevelPlayView({
    super.key,
    required this.level,
    required this.progress,
    required this.accent,
    required this.onShowLevels,
    required this.onNext,
  });

  final LevelData level;
  final LevelProgressService progress;
  final Color accent;
  final VoidCallback onShowLevels;
  final ValueChanged<int> onNext;

  @override
  State<_LevelPlayView> createState() => _LevelPlayViewState();
}

class _LevelPlayViewState extends State<_LevelPlayView> {
  final _editorKey = GlobalKey<_FormulaEditorState>();
  int _usedHints = 0;
  _CompletedAttempt? _completed;
  OverlayEntry? _resultOverlay;
  bool _isCompleting = false;

  @override
  void dispose() {
    _removeResultOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        _GameHeader(
          title: 'LEVEL ${widget.level.id}',
          backLabel: '레벨 목록',
          onBack: widget.onShowLevels,
          trailing: Obx(() {
            final remaining = Get.isRegistered<HintService>()
                ? Get.find<HintService>().hints.value
                : (3 - _usedHints);
            return _HintButton(
              remainingHints: remaining,
              accent: widget.accent,
              onPressed: _showHint,
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: _FormulaEditor(
            key: _editorKey,
            digits: widget.level.digits,
            availableOperators: widget.level.availableOperators,
            accent: widget.accent,
            isLandscape: isLandscape,
            visibleHints: List.generate(
              _usedHints,
              widget.level.hints.at,
              growable: false,
            ),
            requiresEquals: true,
            validateExpression: (expression) => validateLevelFormula(
              digitString: widget.level.digitString,
              expression: expression,
              availableOperators: widget.level.availableOperators,
            ),
            onValidSubmission: _handleSubmission,
          ),
        ),
      ],
    );
  }

  Future<void> _showHint() async {
    if (_usedHints >= 3) {
      if (mounted) {
        showAppSnackBar(
          title: '힌트 사용',
          message: '이 문제의 힌트를 모두 사용했습니다.',
          icon: Icons.lightbulb_outline_rounded,
        );
      }
      return;
    }
    if (Get.isRegistered<HintService>()) {
      final hintService = Get.find<HintService>();
      if (!hintService.hasHints) {
        if (mounted) {
          if (Get.isRegistered<HintPurchaseService>()) {
            await Get.to(() => const HintStoreScreen());
          } else {
            showAppSnackBar(
              title: '힌트 부족',
              message: '보유한 힌트가 없습니다. 매일 출석 시 힌트 3개가 지급됩니다!',
              icon: Icons.lightbulb_outline_rounded,
            );
          }
        }
        return;
      }
      final used = await hintService.useHint();
      if (used && mounted) {
        setState(() => _usedHints++);
      }
    } else {
      if (_usedHints < 3) setState(() => _usedHints++);
    }
  }

  Future<void> _handleSubmission(String _, int score) async {
    if (_isCompleting) return;
    _isCompleting = true;
    final evaluation =
        evaluateLevelScore(widget.level, score, usedHints: _usedHints);
    await widget.progress.recordResult(
      level: widget.level,
      score: score,
      evaluation: evaluation,
      usedHints: _usedHints,
    );
    if (!mounted) return;
    setState(() {
      _completed = _CompletedAttempt(
        evaluation: evaluation,
      );
      _isCompleting = false;
    });
    _showResultOverlay();
  }

  void _showResultOverlay() {
    final completed = _completed;
    if (completed == null || _resultOverlay != null) return;

    _resultOverlay = OverlayEntry(
      builder: (context) => _LevelResultOverlay(
        attempt: completed,
        onReplay: _replay,
        onShowLevels: () {
          _removeResultOverlay();
          widget.onShowLevels();
        },
        onNext: widget.level.id < LevelCatalog.all.length
            ? () {
                _removeResultOverlay();
                widget.onNext(widget.level.id + 1);
              }
            : null,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_resultOverlay!);
  }

  void _removeResultOverlay() {
    _resultOverlay?.remove();
    _resultOverlay = null;
  }

  void _replay() {
    _removeResultOverlay();
    setState(() {
      _usedHints = 0;
      _completed = null;
    });
    _editorKey.currentState?.reset();
  }
}

// ─── 레벨 헤더 ────────────────────────────────────────────

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.title,
    required this.backLabel,
    required this.onBack,
    required this.trailing,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SoftIconButton(
          icon: Icons.arrow_back_rounded,
          label: backLabel,
          onPressed: onBack,
          size: 44,
          iconSize: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: trailing,
            ),
          ),
        ),
      ],
    );
  }
}

class _HintButton extends StatelessWidget {
  const _HintButton({
    required this.remainingHints,
    required this.accent,
    required this.onPressed,
  });

  final int remainingHints;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '힌트, $remainingHints회 남음',
      child: SizedBox(
        key: const ValueKey('level-hint-button'),
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.borderLight),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 20,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: remainingHints == 0 ? AppColors.surfaceSoft : accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Text(
                  '$remainingHints',
                  style: TextStyle(
                    color: remainingHints == 0
                        ? AppColors.textSecondary
                        : AppColors.onPrimary,
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 완료 시도 데이터 ────────────────────────────────────────

class _CompletedAttempt {
  const _CompletedAttempt({
    required this.evaluation,
  });

  final LevelEvaluation evaluation;
}

// ─── 레벨 결과 오버레이 ──────────────────────────────────────

class _LevelResultOverlay extends StatelessWidget {
  const _LevelResultOverlay({
    required this.attempt,
    required this.onReplay,
    required this.onShowLevels,
    required this.onNext,
  });

  final _CompletedAttempt attempt;
  final VoidCallback onReplay;
  final VoidCallback onShowLevels;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final evaluation = attempt.evaluation;
    return Stack(
      children: [
        Positioned.fill(
          child: ModalBarrier(
            dismissible: false,
            color: const Color(0xFF17191D).withValues(alpha: 0.55),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: (scale - 0.9) / 0.1 + 0.0,
                    child: child,
                  ),
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isLit = index < evaluation.stars;
                        final size = index == 1 ? 48.0 : 36.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            isLit
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: size,
                            color: isLit
                                ? const Color(0xFFFFB800)
                                : AppColors.borderLight,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: onReplay,
                          icon: const Icon(
                            Icons.replay_rounded,
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
                          onPressed: onShowLevels,
                          icon: const Icon(
                            Icons.grid_view_rounded,
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
                          onPressed: onNext,
                          icon: Icon(
                            onNext == null
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0095FF),
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
          ),
        ),
      ],
    );
  }
}
