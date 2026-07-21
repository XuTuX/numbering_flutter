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
    });
  }

  void _handleSolved() {
    if (_roundLocked) return;
    final isSingleRound =
        widget.session.isDailyMode || widget.session.isTutorialMode;
    setState(() {
      _score++;
      _roundLocked = isSingleRound;
      if (!isSingleRound) {
        _round++;
        _problem = _generateProblem();
        _roundLocked = false;
      }
    });
    widget.callbacks.onScoreChanged(_score);

    if (isSingleRound) {
      unawaited(_finishSingleRound());
    }
  }

  Future<void> _finishSingleRound() async {
    if (widget.session.isTutorialMode) {
      await Get.find<SettingsService>().completeTutorial();
      if (!mounted) return;
    }
    widget.callbacks.onFinished(
      GameResult(
        score: _score,
        detailLabel: '경과 시간'.tr,
        detailValue: _formatElapsed(DateTime.now().difference(_startedAt)),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Text(
            '숫자 순서를 바꾸지 않고 등식을 만드세요.'.tr,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _DragDropEditor(
            digits: widget.problem.digits,
            operators: _operators,
            parentheses: _parentheses,
            accent: widget.accent,
            accentSoft: widget.accentSoft,
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

class _DragDropEditor extends StatelessWidget {
  const _DragDropEditor({
    required this.digits,
    required this.operators,
    required this.parentheses,
    required this.accent,
    required this.accentSoft,
    required this.selectedDigitIndex,
    required this.onDigitTapped,
    required this.onOperatorChanged,
  });

  final List<String> digits;
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
  final Color accent;
  final Color accentSoft;
  final int? selectedDigitIndex;
  final ValueChanged<int> onDigitTapped;
  final void Function(int index, InlineOperator? value) onOperatorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(digits.length, (digitIndex) {
                  final openingCount = parentheses
                      .where((range) =>
                          range.normalized().startDigitIndex == digitIndex)
                      .length;
                  final closingCount = parentheses
                      .where((range) =>
                          range.normalized().endDigitIndex == digitIndex)
                      .length;
                  final digit = GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => onDigitTapped(digitIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '${'(' * openingCount}${digits[digitIndex]}${')' * closingCount}',
                        style: GoogleFonts.blackHanSans(
                          fontSize: 32,
                          color: selectedDigitIndex == digitIndex
                              ? accent
                              : AppColors.textPrimary,
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
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '숫자 두 개를 눌러 괄호를 추가하거나 해제하세요.\n연산자는 넣을 위치의 오른쪽 숫자로 끌어 놓으세요.'.tr,
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _isHovering
              ? widget.accent.withValues(alpha: 0.08)
              : Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.current case final current?)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onRemove,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      current.symbol,
                      style: GoogleFonts.blackHanSans(
                        fontSize: 28,
                        color: widget.accent,
                      ),
                    ),
                  ),
                ),
              widget.digit,
            ],
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.text,
    required this.accent,
    required this.accentSoft,
  });

  final String text;
  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text(
        text.tr,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(
          color: accent,
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
