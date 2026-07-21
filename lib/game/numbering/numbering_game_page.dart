import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/soft_icon_button.dart';
import '../game_module.dart';
import 'expression_engine.dart';
import 'numbering_models.dart';
import 'numbering_visuals.dart';
import 'problem_generators.dart';

class NumberingGamePage extends StatefulWidget {
  const NumberingGamePage({
    super.key,
    required this.game,
    required this.session,
    required this.callbacks,
  });

  final NumberingGame game;
  final GameSessionConfig session;
  final GameCallbacks callbacks;

  @override
  State<NumberingGamePage> createState() => _NumberingGamePageState();
}

class _NumberingGamePageState extends State<NumberingGamePage> {
  late final Random _random;
  late final DateTime _startedAt;
  late final Timer _clock;
  int _round = 1;
  int _score = 0;
  int _roundVersion = 0;
  bool _roundLocked = false;
  String? _feedback;
  late Object _problem;

  @override
  void initState() {
    super.initState();
    _random = Random(widget.session.seed);
    _startedAt = DateTime.now();
    _problem = _generateProblem();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = difficultyForRound(_round);
    final visuals = widget.game.visuals;
    return Column(
      children: [
        _GameHeader(
          title: widget.game.title,
          icon: visuals.icon,
          accent: visuals.accent,
          accentSoft: visuals.accentSoft,
          round: _round,
          score: _score,
          difficulty: difficulty,
          elapsed: DateTime.now().difference(_startedAt),
          onReset: _resetCurrentRound,
          onExit: widget.callbacks.onExit,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (widget.session.isTutorialMode)
          _InfoBanner(
            text: widget.game.description,
            accent: visuals.accent,
            accentSoft: visuals.accentSoft,
          ),
        if (widget.session.isTutorialMode)
          const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                key: ValueKey('${widget.game.id}-$_round-$_roundVersion'),
                ignoring: _roundLocked,
                child: _buildRound(),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: _feedback == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _InfoBanner(
                    text: _feedback!,
                    accent: visuals.accent,
                    accentSoft: visuals.accentSoft,
                    success: true,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRound() {
    final visuals = widget.game.visuals;
    return FormulaWorkshopRound(
      problem: _problem as FormulaProblem,
      accent: visuals.accent,
      onSolved: _handleSolved,
    );
  }

  Object _generateProblem() {
    return generateFormulaProblem(_random, _round);
  }

  void _resetCurrentRound() {
    if (_roundLocked) return;
    setState(() {
      _roundVersion++;
      _feedback = null;
    });
  }

  void _handleSolved() {
    if (_roundLocked) return;
    setState(() {
      _score++;
      _roundLocked = true;
      _feedback = '정답입니다!'.tr;
    });
    widget.callbacks.onScoreChanged(_score);
    unawaited(_advanceAfterSuccess());
  }

  Future<void> _advanceAfterSuccess() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final isSingleRound = widget.session.isDailyMode ||
        widget.session.isTutorialMode ||
        _round >= 200;
    if (widget.session.isTutorialMode) {
      await Get.find<SettingsService>().completeTutorial();
      if (!mounted) return;
    }
    if (isSingleRound) {
      widget.callbacks.onFinished(
        GameResult(
          score: _score,
          detailLabel: '경과 시간'.tr,
          detailValue: _formatElapsed(DateTime.now().difference(_startedAt)),
        ),
      );
      return;
    }

    setState(() {
      _round++;
      _problem = _generateProblem();
      _roundLocked = false;
      _feedback = null;
    });
  }
}

class FormulaWorkshopRound extends StatefulWidget {
  const FormulaWorkshopRound({
    super.key,
    required this.problem,
    required this.accent,
    required this.onSolved,
  });

  final FormulaProblem problem;
  final Color accent;
  final VoidCallback onSolved;

  @override
  State<FormulaWorkshopRound> createState() => _FormulaWorkshopRoundState();
}

class _FormulaWorkshopRoundState extends State<FormulaWorkshopRound> {
  late final List<InlineOperator?> _operators;
  final List<ParenthesisRange> _parentheses = [];
  int? _selectedDigitIndex;
  String? _message;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _operators = List.filled(widget.problem.digits.length - 1, null);
  }

  String get _expression => assembleInlineExpression(
        digits: widget.problem.digits,
        operators: _operators,
        parentheses: _parentheses,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          _DragDropEditor(
            digits: widget.problem.digits,
            operators: _operators,
            parentheses: _parentheses,
            accent: widget.accent,
            selectedDigitIndex: _selectedDigitIndex,
            onDigitTapped: _handleDigitTap,
            onOperatorChanged: (index, value) {
              setState(() => _operators[index] = value);
              _checkAnswer();
            },
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleDigitTap(int index) {
    if (_selectedDigitIndex == null) {
      setState(() => _selectedDigitIndex = index);
      return;
    }
    if (_selectedDigitIndex == index) {
      setState(() => _selectedDigitIndex = null);
      return;
    }

    final candidate = ParenthesisRange(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      startDigitIndex: _selectedDigitIndex!,
      endDigitIndex: index,
    ).normalized();
    final existingIndex = _parentheses.indexWhere((range) {
      final normalized = range.normalized();
      return normalized.startDigitIndex == candidate.startDigitIndex &&
          normalized.endDigitIndex == candidate.endDigitIndex;
    });

    if (existingIndex >= 0) {
      setState(() {
        _parentheses.removeAt(existingIndex);
        _selectedDigitIndex = null;
        _message = null;
      });
      _checkAnswer();
      return;
    }

    final validation = validateParenthesisRange(
      digitCount: widget.problem.digits.length,
      candidate: candidate,
      existing: _parentheses,
    );
    if (validation.valid) {
      setState(() {
        _parentheses.add(candidate);
        _message = null;
        _selectedDigitIndex = null;
      });
      _checkAnswer();
    } else {
      setState(() {
        _message = validation.message;
        _selectedDigitIndex = null;
      });
    }
  }

  void _checkAnswer() {
    if (_solved) return;
    final hasEquals = _operators.contains(InlineOperator.equals);
    if (!hasEquals) {
      setState(() => _message = null);
      return;
    }
    final result = validateFormulaWorkshop(
      digitString: widget.problem.digitString,
      expression: _expression,
    );
    if (result.valid) {
      _solved = true;
      widget.onSolved();
    } else {
      setState(() => _message = result.message);
    }
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.title,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.round,
    required this.score,
    required this.difficulty,
    required this.elapsed,
    required this.onReset,
    required this.onExit,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final int round;
  final int score;
  final NumberingDifficulty difficulty;
  final Duration elapsed;
  final VoidCallback onReset;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Controls & Title
          Row(
            children: [
              SoftIconButton(
                icon: Icons.arrow_back_rounded,
                label: '뒤로 가기'.tr,
                onPressed: onExit,
                size: 40,
                iconSize: 20,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accent, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        title.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.blackHanSans(
                          fontSize: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SoftIconButton(
                icon: Icons.refresh_rounded,
                label: '초기화'.tr,
                onPressed: onReset,
                size: 40,
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Bottom Row: Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                // Difficulty & Round
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        difficulty.label,
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${'라운드'.tr} $round',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                // Score & Time
                Row(
                  children: [
                    Text(
                      '${'점수'.tr} $score',
                      style: GoogleFonts.blackHanSans(
                        fontSize: 16,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatElapsed(elapsed),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DragDropEditor extends StatelessWidget {
  const _DragDropEditor({
    required this.digits,
    required this.operators,
    required this.parentheses,
    required this.accent,
    required this.selectedDigitIndex,
    required this.onDigitTapped,
    required this.onOperatorChanged,
  });

  final List<String> digits;
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
  final Color accent;
  final int? selectedDigitIndex;
  final ValueChanged<int> onDigitTapped;
  final void Function(int index, InlineOperator? value) onOperatorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 12,
            children: List.generate(digits.length, (digitIndex) {
              final openingCount = parentheses
                  .where((range) =>
                      range.normalized().startDigitIndex == digitIndex)
                  .length;
              final closingCount = parentheses
                  .where(
                      (range) => range.normalized().endDigitIndex == digitIndex)
                  .length;

              final isSelected = selectedDigitIndex == digitIndex;
              final digit = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onDigitTapped(digitIndex),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Text(
                    '${'(' * openingCount}${digits[digitIndex]}${')' * closingCount}',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? accent : AppColors.textPrimary,
                    ),
                  ),
                ),
              );

              if (digitIndex == 0) return digit;
              final slotIndex = digitIndex - 1;
              return _InlineOperatorTarget(
                current: operators[slotIndex],
                digit: digit,
                accent: accent,
                onAccept: (op) => onOperatorChanged(slotIndex, op),
                onRemove: () => onOperatorChanged(slotIndex, null),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _OperatorPalette(accent: accent),
      ],
    );
  }
}

class _InlineOperatorTarget extends StatefulWidget {
  const _InlineOperatorTarget({
    required this.current,
    required this.digit,
    required this.accent,
    required this.onAccept,
    required this.onRemove,
  });

  final InlineOperator? current;
  final Widget digit;
  final Color accent;
  final ValueChanged<InlineOperator> onAccept;
  final VoidCallback onRemove;

  @override
  State<_InlineOperatorTarget> createState() => _InlineOperatorTargetState();
}

class _InlineOperatorTargetState extends State<_InlineOperatorTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<InlineOperator>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _isHovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: _isHovering && widget.current == null ? 36 : 0,
            ),
            if (widget.current case final current?)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onRemove,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Text(
                    current.symbol,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            widget.digit,
          ],
        );
      },
    );
  }
}

class _OperatorPalette extends StatelessWidget {
  const _OperatorPalette({
    required this.accent,
  });

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final operators = [
      InlineOperator.add,
      InlineOperator.subtract,
      InlineOperator.multiply,
      InlineOperator.divide,
      InlineOperator.equals,
    ];

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: operators.map((op) {
            final child = Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  op.symbol,
                  style: const TextStyle(
                    fontSize: 24,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );

            return Draggable<InlineOperator>(
              data: op,
              feedback: Material(
                color: Colors.transparent,
                child: Opacity(opacity: 0.8, child: child),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: child),
              child: child,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.text,
    required this.accent,
    required this.accentSoft,
    this.success = false,
  });

  final String text;
  final Color accent;
  final Color accentSoft;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: success ? AppColors.green.withValues(alpha: 0.16) : accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text(
        text.tr,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(
          color: success ? AppColors.green : accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
