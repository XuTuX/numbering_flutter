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
import '../../widgets/common/soft_card.dart';
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
                  padding: const EdgeInsets.only(top: 8),
                  child: _InfoBanner(
                    text: _feedback!,
                    success: _roundLocked,
                    accent: visuals.accent,
                    accentSoft: visuals.accentSoft,
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
      accentSoft: visuals.accentSoft,
      onSolved: _handleSolved,
    );
  }

  Object _generateProblem() {
    final difficulty = difficultyForRound(_round);
    return generateFormulaProblem(_random, difficulty);
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
    _roundLocked = true;
    _score++;
    widget.callbacks.onScoreChanged(_score);
    setState(() => _feedback = '정답입니다!'.tr);

    Future<void>.delayed(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final isSingleRound =
          widget.session.isDailyMode || widget.session.isTutorialMode;
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
    });
  }
}

class FormulaWorkshopRound extends StatefulWidget {
  const FormulaWorkshopRound({
    super.key,
    required this.problem,
    required this.accent,
    required this.accentSoft,
    required this.onSolved,
  });

  final FormulaProblem problem;
  final Color accent;
  final Color accentSoft;
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
    return _PuzzleCard(
      title: '숫자 순서를 바꾸지 않고 등식을 만드세요.'.tr,
      accent: widget.accent,
      child: Column(
        children: [
          _ExpressionPreview(
            expression: _expression,
            accent: widget.accent,
          ),
          const SizedBox(height: 18),
          _DragDropEditor(
            digits: widget.problem.digits,
            operators: _operators,
            accent: widget.accent,
            accentSoft: widget.accentSoft,
            selectedDigitIndex: _selectedDigitIndex,
            onDigitTapped: (index) {
              if (_selectedDigitIndex == null) {
                setState(() => _selectedDigitIndex = index);
              } else if (_selectedDigitIndex == index) {
                setState(() => _selectedDigitIndex = null);
              } else {
                final candidate = ParenthesisRange(
                  id: '${DateTime.now().microsecondsSinceEpoch}',
                  startDigitIndex: _selectedDigitIndex!,
                  endDigitIndex: index,
                );
                final validation = validateParenthesisRange(
                  digitCount: widget.problem.digits.length,
                  candidate: candidate,
                  existing: _parentheses,
                );
                if (validation.valid) {
                  setState(() {
                    _parentheses.add(candidate.normalized());
                    _message = null;
                  });
                  _checkAnswer();
                } else {
                  setState(() => _message = validation.message);
                }
                setState(() => _selectedDigitIndex = null);
              }
            },
            onOperatorChanged: (index, value) {
              setState(() => _operators[index] = value);
              _checkAnswer();
            },
          ),
          const SizedBox(height: 16),
          _ParenthesisChips(
            ranges: _parentheses,
            onChanged: (ranges) {
              setState(() {
                _parentheses
                  ..clear()
                  ..addAll(ranges);
              });
              _checkAnswer();
            },
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
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
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              SoftIconButton(
                icon: Icons.close_rounded,
                label: '홈'.tr,
                onPressed: onExit,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.blackHanSans(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SoftIconButton(
                icon: Icons.refresh_rounded,
                label: '초기화'.tr,
                onPressed: onReset,
                size: 44,
                iconSize: 22,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  difficulty.label,
                  style: AppTypography.label.copyWith(
                    color: accent,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${'라운드'.tr} $round',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${'점수'.tr} $score',
                style: GoogleFonts.blackHanSans(
                  fontSize: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.timer_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatElapsed(elapsed),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PuzzleCard extends StatelessWidget {
  const _PuzzleCard({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class _DragDropEditor extends StatelessWidget {
  const _DragDropEditor({
    required this.digits,
    required this.operators,
    required this.accent,
    required this.accentSoft,
    required this.selectedDigitIndex,
    required this.onDigitTapped,
    required this.onOperatorChanged,
  });

  final List<String> digits;
  final List<InlineOperator?> operators;
  final Color accent;
  final Color accentSoft;
  final int? selectedDigitIndex;
  final ValueChanged<int> onDigitTapped;
  final void Function(int index, InlineOperator? value) onOperatorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(digits.length * 2 - 1, (visualIndex) {
              if (visualIndex.isEven) {
                final digitIndex = visualIndex ~/ 2;
                final isSelected = selectedDigitIndex == digitIndex;
                return GestureDetector(
                  onTap: () => onDigitTapped(digitIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 46,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? accent : accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(
                        color: isSelected
                            ? accent
                            : accent.withValues(alpha: 0.55),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      digits[digitIndex],
                      style: GoogleFonts.blackHanSans(
                        fontSize: 25,
                        color: isSelected
                            ? AppColors.surface
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }
              final slotIndex = visualIndex ~/ 2;
              final current = operators[slotIndex];
              return _OperatorSlotView(
                current: current,
                accent: accent,
                accentSoft: accentSoft,
                onAccept: (op) => onOperatorChanged(slotIndex, op),
                onRemove: () => onOperatorChanged(slotIndex, null),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '숫자를 2개 연속으로 터치하면 괄호가 씌워집니다.\n아래 연산자를 빈칸으로 끌어다 놓으세요.\n잘못 놓은 연산자는 터치하면 지워집니다.'
              .tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _OperatorPalette(accent: accent, accentSoft: accentSoft),
      ],
    );
  }
}

class _OperatorSlotView extends StatefulWidget {
  const _OperatorSlotView({
    required this.current,
    required this.accent,
    required this.accentSoft,
    required this.onAccept,
    required this.onRemove,
  });

  final InlineOperator? current;
  final Color accent;
  final Color accentSoft;
  final ValueChanged<InlineOperator> onAccept;
  final VoidCallback onRemove;

  @override
  State<_OperatorSlotView> createState() => _OperatorSlotViewState();
}

class _OperatorSlotViewState extends State<_OperatorSlotView> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.current != null;
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
        return GestureDetector(
          onTap: hasValue ? widget.onRemove : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: _isHovering || hasValue ? 44 : 20,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasValue || _isHovering
                  ? widget.accentSoft
                  : AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(
                color: _isHovering ? widget.accent : AppColors.borderLight,
                width: _isHovering ? 2 : 1,
              ),
            ),
            child: hasValue
                ? Text(
                    widget.current!.symbol,
                    style: GoogleFonts.blackHanSans(
                      fontSize: 21,
                      color: widget.accent,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _OperatorPalette extends StatelessWidget {
  const _OperatorPalette({
    required this.accent,
    required this.accentSoft,
  });

  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    final operators = [
      InlineOperator.add,
      InlineOperator.subtract,
      InlineOperator.multiply,
      InlineOperator.divide,
      InlineOperator.equals,
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: operators.map((op) {
        final child = Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentSoft,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            op.symbol,
            style: GoogleFonts.blackHanSans(
              fontSize: 26,
              color: accent,
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
    );
  }
}

class _ParenthesisChips extends StatelessWidget {
  const _ParenthesisChips({
    required this.ranges,
    required this.onChanged,
  });

  final List<ParenthesisRange> ranges;
  final ValueChanged<List<ParenthesisRange>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (ranges.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      children: ranges.map((range) {
        final normalized = range.normalized();
        return InputChip(
          label: Text(
            '(${normalized.startDigitIndex + 1}~${normalized.endDigitIndex + 1})',
          ),
          onDeleted: () {
            final next = [...ranges]..remove(range);
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}

class _ExpressionPreview extends StatelessWidget {
  const _ExpressionPreview({
    required this.expression,
    required this.accent,
  });

  final String expression;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.all(AppSpacing.lg),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          expression,
          style: GoogleFonts.blackHanSans(fontSize: 30),
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
