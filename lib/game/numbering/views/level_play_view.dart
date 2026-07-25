import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_spacing.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/game/numbering/level_catalog.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/services/hint_purchase_service.dart';
import 'package:numbering/services/settings_service.dart';
import 'package:numbering/utils/app_snackbar.dart';
import 'package:numbering/screens/hints/hint_store_screen.dart';
import 'package:numbering/widgets/dialogs/animated_game_dialog.dart';
import 'package:numbering/game/numbering/widgets/game_header.dart';
import 'package:numbering/game/numbering/widgets/formula_editor.dart';

// ─── 레벨 플레이 뷰 ─────────────────────────────────────────

class LevelPlayView extends StatefulWidget {
  const LevelPlayView({
    super.key,
    required this.level,
    required this.progress,
    required this.accent,
    required this.onShowLevels,
    required this.onNext,
    this.isTutorial = false,
  });

  final LevelData level;
  final LevelProgressService progress;
  final Color accent;
  final VoidCallback onShowLevels;
  final ValueChanged<int> onNext;
  final bool isTutorial;

  @override
  State<LevelPlayView> createState() => _LevelPlayViewState();
}

class _LevelPlayViewState extends State<LevelPlayView> {
  final _editorKey = GlobalKey<FormulaEditorState>();
  int _usedHints = 0;
  LevelEvaluation? _completedEvaluation;
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        GameHeader(
          title: 'LEVEL ${widget.level.id}',
          backLabel: '레벨 목록',
          onBack: widget.onShowLevels,
          trailing: Obx(() {
            final remaining = Get.isRegistered<HintService>()
                ? Get.find<HintService>().hints.value
                : (3 - _usedHints);
            return HintButton(
              remainingHints: remaining,
              accent: widget.accent,
              onPressed: _showHint,
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: FormulaEditor(
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
    if (widget.isTutorial) {
      unawaited(Get.find<SettingsService>().completeTutorial());
    }
    if (!mounted) return;
    setState(() {
      _completedEvaluation = evaluation;
      _isCompleting = false;
    });
    _showResultOverlay();
  }

  void _showResultOverlay() {
    final evaluation = _completedEvaluation;
    if (evaluation == null) return;
    Navigator.of(context, rootNavigator: true).push<void>(_LevelResultRoute(
      evaluation: evaluation,
      onReplay: () {
        setState(() {
          _usedHints = 0;
          _completedEvaluation = null;
        });
      },
      onShowLevels: widget.onShowLevels,
      hasNext: widget.level.id < LevelCatalog.all.length,
      onNextIfAny: () => widget.onNext(widget.level.id + 1),
    ));
  }
}

// ─── PopupRoute ────────────────────────────────────────────

class _LevelResultRoute extends PopupRoute<void> {
  _LevelResultRoute({
    required this.evaluation,
    required this.onReplay,
    required this.onShowLevels,
    required this.hasNext,
    required this.onNextIfAny,
  });

  final LevelEvaluation evaluation;
  final VoidCallback onReplay;
  final VoidCallback onShowLevels;
  final bool hasNext;
  final VoidCallback onNextIfAny;

  @override
  Color? get barrierColor => AppColors.ink.withValues(alpha: 0.55);

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _LevelResultContent(
      evaluation: evaluation,
      onReplay: () {
        Navigator.of(context).pop();
        onReplay();
      },
      onShowLevels: () {
        Navigator.of(context).pop();
        onShowLevels();
      },
      onNext: hasNext
          ? () {
              Navigator.of(context).pop();
              onNextIfAny();
            }
          : null,
    );
  }
}

// ─── 레벨 결과 내용 ─────────────────────────────────────────

class _LevelResultContent extends StatelessWidget {
  const _LevelResultContent({
    required this.evaluation,
    required this.onReplay,
    required this.onShowLevels,
    required this.onNext,
  });

  final LevelEvaluation evaluation;
  final VoidCallback onReplay;
  final VoidCallback onShowLevels;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AnimatedGameDialog(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isLit = index < evaluation.stars;
              final size = index == 1 ? 48.0 : 36.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isLit ? Icons.star_rounded : Icons.star_border_rounded,
                  size: size,
                  color:
                      isLit ? const Color(0xFFFFB800) : AppColors.borderLight,
                ),
              );
            }),
          ),
          actions: [
            GameDialogButton(
              onPressed: onReplay,
              icon: Icons.replay_rounded,
            ),
            GameDialogButton(
              onPressed: onShowLevels,
              icon: Icons.grid_view_rounded,
            ),
            GameDialogButton(
              onPressed: onNext,
              icon: onNext == null
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              backgroundColor: const Color(0xFF0095FF),
              iconColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
