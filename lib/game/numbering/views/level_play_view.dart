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
            _LevelHeader(
              levelId: widget.level.id,
              remainingHints: 3 - _usedHints,
              accent: widget.accent,
              onBack: widget.onShowLevels,
              onHint: _showHint,
              isLandscape: isLandscape,
            ),
            const SizedBox(height: AppSpacing.sm),
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
              onNext: widget.level.id < 200
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
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppColors.yellow),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '힌트 $visibleCount/3',
                    style: AppTypography.subtitle,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (var index = 0; index < visibleCount; index++) ...[
                Text(
                  '${index + 1}. ${widget.level.hints.at(index)}',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                if (index + 1 < visibleCount)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmission(String expression, int score) {
    final evaluation = evaluateLevelScore(widget.level, score, usedHints: _usedHints);
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
    required this.isLandscape,
  });

  final int levelId;
  final int remainingHints;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback onHint;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SoftIconButton(
          icon: Icons.arrow_back_rounded,
          label: '레벨 목록',
          onPressed: onBack,
          size: isLandscape ? 36 : 40,
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
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHint,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        size: 18, color: AppColors.yellow),
                    const SizedBox(width: 4),
                    Text(
                      '$remainingHints',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: remainingHints == 0
                            ? AppColors.textSecondary
                            : accent,
                      ),
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
                          isLit ? Icons.star_rounded : Icons.star_border_rounded,
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
                          onNext == null ? Icons.check_rounded : Icons.arrow_forward_rounded,
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
