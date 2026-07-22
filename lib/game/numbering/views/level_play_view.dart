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

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            _LevelHeader(
              levelId: widget.level.id,
              remainingHints: 3 - _usedHints,
              accent: widget.accent,
              onBack: widget.onShowLevels,
              onHint: _showHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _FormulaEditor(
                key: _editorKey,
                level: widget.level,
                accent: widget.accent,
                isLandscape: isLandscape,
                onValidSubmission: _handleSubmission,
              ),
            ),
          ],
        ),
        if (_completed case final completed?)
          Positioned.fill(
            child: _LevelResultOverlay(
              level: widget.level,
              attempt: completed,
              usedHints: _usedHints,
              accent: widget.accent,
              onReplay: _replay,
              onShowLevels: widget.onShowLevels,
              onNext: widget.level.id < 160
                  ? () => widget.onNext(widget.level.id + 1)
                  : null,
            ),
          ),
      ],
    );
  }

  void _showHint() {
    if (_usedHints < 3) setState(() => _usedHints++);
    final visibleCount = _usedHints;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.16),
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('힌트', style: AppTypography.subtitle),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '$visibleCount / 3',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (var index = 0; index < visibleCount; index++) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Text(
                        widget.level.hints.at(index),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (index + 1 < visibleCount)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmission(String expression, int score) {
    final evaluation =
        evaluateLevelScore(widget.level, score, usedHints: _usedHints);
    unawaited(
      widget.progress.recordResult(
        level: widget.level,
        score: score,
        evaluation: evaluation,
        usedHints: _usedHints,
      ),
    );
    setState(() {
      _completed = _CompletedAttempt(
        expression: expression,
        score: score,
        evaluation: evaluation,
      );
    });
  }

  void _replay() {
    setState(() {
      _usedHints = 0;
      _completed = null;
    });
    _editorKey.currentState?.reset();
  }
}

// ─── 레벨 헤더 ────────────────────────────────────────────

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.levelId,
    required this.remainingHints,
    required this.accent,
    required this.onBack,
    required this.onHint,
  });

  final int levelId;
  final int remainingHints;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SoftIconButton(
          icon: Icons.arrow_back_rounded,
          label: '레벨 목록',
          onPressed: onBack,
          size: 44,
          iconSize: 20,
        ),
        Expanded(
          child: Text(
            'LEVEL $levelId',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _HintButton(
          remainingHints: remainingHints,
          accent: accent,
          onPressed: onHint,
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
    required this.expression,
    required this.score,
    required this.evaluation,
  });

  final String expression;
  final int score;
  final LevelEvaluation evaluation;
}

// ─── 레벨 결과 오버레이 ──────────────────────────────────────

class _LevelResultOverlay extends StatelessWidget {
  const _LevelResultOverlay({
    required this.level,
    required this.attempt,
    required this.usedHints,
    required this.accent,
    required this.onReplay,
    required this.onShowLevels,
    required this.onNext,
  });

  final LevelData level;
  final _CompletedAttempt attempt;
  final int usedHints;
  final Color accent;
  final VoidCallback onReplay;
  final VoidCallback onShowLevels;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final evaluation = attempt.evaluation;
    return ColoredBox(
      color: const Color(0xFF17191D).withValues(alpha: 0.55),
      child: Center(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                  const SizedBox(height: 28),
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
    );
  }
}
