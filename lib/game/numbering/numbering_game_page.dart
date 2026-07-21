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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visuals = widget.game.visuals;
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Column(
      children: [
        _GameHeader(
          accent: visuals.accent,
          round: _round,
          score: _score,
          onExit: widget.callbacks.onExit,
          isLandscape: isLandscape,
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.session.isTutorialMode)
          _InfoBanner(
            text: widget.game.description,
            accent: visuals.accent,
            accentSoft: visuals.accentSoft,
          ),
        if (widget.session.isTutorialMode)
          const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              key: ValueKey('${widget.game.id}-$_round-$_roundVersion'),
              ignoring: _roundLocked,
              child: _buildRound(isLandscape),
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

  Widget _buildRound(bool isLandscape) {
    final visuals = widget.game.visuals;
    return FormulaWorkshopRound(
      problem: _problem as FormulaProblem,
      accent: visuals.accent,
      onSolved: _handleSolved,
      onReset: _resetCurrentRound,
      isLandscape: isLandscape,
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

  void _handleSolved(int scoreGained) {
    if (_roundLocked) return;
    setState(() {
      _score += scoreGained;
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
    required this.onReset,
    this.isLandscape = false,
  });

  final FormulaProblem problem;
  final Color accent;
  final ValueChanged<int> onSolved;
  final VoidCallback onReset;
  final bool isLandscape;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 620;
        final topGap = widget.isLandscape
            ? (constraints.maxHeight * 0.05).clamp(16.0, 40.0)
            : (constraints.maxHeight * 0.08).clamp(28.0, 72.0);
        final horizontalPadding = constraints.maxWidth < 600 ? 0.0 : 24.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: topGap),
              _DragDropEditor(
                digits: widget.problem.digits,
                operators: _operators,
                parentheses: _parentheses,
                accent: widget.accent,
                selectedDigitIndex: _selectedDigitIndex,
                isLandscape: widget.isLandscape,
                onDigitTapped: _handleDigitTap,
                onOperatorChanged: (index, value) {
                  setState(() => _operators[index] = value);
                  _checkAnswer();
                },
              ),
              if (_message != null) ...[
                SizedBox(height: isCompactHeight ? 16 : 28),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isCompactHeight ? 12 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const Spacer(),
              _GameActionButtons(
                onHint: _showHint,
                onReset: widget.onReset,
                isCompact: isCompactHeight,
              ),
              SizedBox(height: isCompactHeight ? 4 : 16),
            ],
          ),
        );
      },
    );
  }

  void _showHint() {
    setState(() {
      _message = '${'힌트'.tr}: ${widget.problem.knownSolution}';
      _selectedDigitIndex = null;
    });
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
      widget.onSolved(result.value!);
    } else {
      setState(() => _message = result.message);
    }
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.accent,
    required this.round,
    required this.score,
    required this.onExit,
    this.isLandscape = false,
  });

  final Color accent;
  final int round;
  final int score;
  final VoidCallback onExit;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final buttonSize = isLandscape ? 36.0 : 40.0;
    final iconSize = isLandscape ? 18.0 : 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          SoftIconButton(
            icon: Icons.arrow_back_rounded,
            label: '뒤로 가기'.tr,
            onPressed: onExit,
            size: buttonSize,
            iconSize: iconSize,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${'라운드'.tr} $round',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isLandscape ? 12 : 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 1,
                  height: 12,
                  color: AppColors.borderLight,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${'점수'.tr} $score',
                  style: GoogleFonts.blackHanSans(
                    fontSize: isLandscape ? 14 : 16,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: buttonSize.clamp(44, 64)),
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
    this.isLandscape = false,
  });

  final List<String> digits;
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
  final Color accent;
  final int? selectedDigitIndex;
  final ValueChanged<int> onDigitTapped;
  final void Function(int index, InlineOperator? value) onOperatorChanged;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context);
        final isMobile = constraints.maxWidth < 600 || viewport.height < 500;
        final isTablet = !isMobile && constraints.maxWidth < 1000;
        final digitFontSize = isMobile
            ? (constraints.maxWidth / (digits.length * 1.05)).clamp(48.0, 68.0)
            : isTablet
                ? (constraints.maxWidth * 0.105).clamp(72.0, 92.0)
                : (constraints.maxWidth * 0.07).clamp(96.0, 120.0);
        final digitPadding = isMobile
            ? (digits.length >= 6 ? 6.0 : 10.0)
            : isTablet
                ? 16.0
                : 22.0;
        final digitVerticalPadding = isMobile ? 8.0 : 12.0;
        final operatorGap = isLandscape && viewport.height < 600
            ? 32.0
            : isMobile
                ? 48.0
                : 64.0;
        final operatorFontSize = (digitFontSize * 0.46).clamp(26.0, 52.0);

        final digitItems = List<Widget>.generate(digits.length, (digitIndex) {
          final openingCount = parentheses
              .where(
                  (range) => range.normalized().startDigitIndex == digitIndex)
              .length;
          final closingCount = parentheses
              .where((range) => range.normalized().endDigitIndex == digitIndex)
              .length;
          final isSelected = selectedDigitIndex == digitIndex;
          final digit = MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onDigitTapped(digitIndex),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: digitPadding,
                  vertical: digitVerticalPadding,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    fontSize: digitFontSize,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? accent : const Color(0xFF17191D),
                  ),
                  child: Text(
                    '${'(' * openingCount}${digits[digitIndex]}${')' * closingCount}',
                  ),
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
            operatorFontSize: operatorFontSize,
            horizontalPadding: digitPadding * 0.65,
            verticalPadding: digitVerticalPadding,
            onAccept: (op) => onOperatorChanged(slotIndex, op),
            onRemove: () => onOperatorChanged(slotIndex, null),
          );
        });

        return Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: digitItems,
                  ),
                ),
              ),
            ),
            SizedBox(height: operatorGap),
            _OperatorPalette(
              accent: accent,
              isCompact: isMobile,
              isDense: isLandscape && viewport.height < 600,
            ),
          ],
        );
      },
    );
  }
}

class _InlineOperatorTarget extends StatefulWidget {
  const _InlineOperatorTarget({
    required this.current,
    required this.digit,
    required this.accent,
    required this.operatorFontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.onAccept,
    required this.onRemove,
  });

  final InlineOperator? current;
  final Widget digit;
  final Color accent;
  final double operatorFontSize;
  final double horizontalPadding;
  final double verticalPadding;
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
              width: _isHovering && widget.current == null
                  ? widget.operatorFontSize * 0.8
                  : 0,
            ),
            if (widget.current case final current?)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onRemove,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.horizontalPadding,
                    vertical: widget.verticalPadding,
                  ),
                  child: Text(
                    current.symbol,
                    style: TextStyle(
                      fontSize: widget.operatorFontSize,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color:
                          _isHovering ? widget.accent : const Color(0xFF253044),
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

class _OperatorPalette extends StatefulWidget {
  const _OperatorPalette({
    required this.accent,
    required this.isCompact,
    required this.isDense,
  });

  final Color accent;
  final bool isCompact;
  final bool isDense;

  @override
  State<_OperatorPalette> createState() => _OperatorPaletteState();
}

class _OperatorPaletteState extends State<_OperatorPalette> {
  InlineOperator? _draggingOperator;

  @override
  Widget build(BuildContext context) {
    const operators = [
      InlineOperator.add,
      InlineOperator.subtract,
      InlineOperator.multiply,
      InlineOperator.divide,
      InlineOperator.equals,
    ];
    final buttonSize = widget.isDense
        ? 46.0
        : widget.isCompact
            ? 52.0
            : 68.0;
    final buttonGap = widget.isDense
        ? 8.0
        : widget.isCompact
            ? 8.0
            : 16.0;
    final horizontalPadding = widget.isDense
        ? 16.0
        : widget.isCompact
            ? 20.0
            : 32.0;
    final verticalPadding = widget.isDense
        ? 12.0
        : widget.isCompact
            ? 16.0
            : 20.0;

    final children = <Widget>[];
    for (var index = 0; index < operators.length; index++) {
      final op = operators[index];
      final child = _OperatorButton(
        operator: op,
        accent: widget.accent,
        size: buttonSize,
        isActive: _draggingOperator == op,
      );

      if (index > 0) children.add(SizedBox(width: buttonGap));
      children.add(
        Draggable<InlineOperator>(
          data: op,
          onDragStarted: () => setState(() => _draggingOperator = op),
          onDragCompleted: _clearDraggingOperator,
          onDraggableCanceled: (_, __) => _clearDraggingOperator(),
          onDragEnd: (_) => _clearDraggingOperator(),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: _OperatorButton(
                operator: op,
                accent: widget.accent,
                size: buttonSize,
                isActive: true,
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: child),
          child: child,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF334155).withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  void _clearDraggingOperator() {
    if (mounted && _draggingOperator != null) {
      setState(() => _draggingOperator = null);
    }
  }
}

class _OperatorButton extends StatefulWidget {
  const _OperatorButton({
    required this.operator,
    required this.accent,
    required this.size,
    required this.isActive,
  });

  final InlineOperator operator;
  final Color accent;
  final double size;
  final bool isActive;

  @override
  State<_OperatorButton> createState() => _OperatorButtonState();
}

class _OperatorButtonState extends State<_OperatorButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isActive
        ? widget.accent
        : _isHovered
            ? const Color(0xFFEAF3FF)
            : const Color(0xFFF5F7F9);
    final foregroundColor = widget.isActive
        ? Colors.white
        : _isHovered
            ? widget.accent
            : const Color(0xFF253044);

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered || widget.isActive ? 1.05 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.operator.symbol,
            style: TextStyle(
              fontSize: widget.size * 0.42,
              height: 1,
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameActionButtons extends StatelessWidget {
  const _GameActionButtons({
    required this.onHint,
    required this.onReset,
    required this.isCompact,
  });

  final VoidCallback onHint;
  final VoidCallback onReset;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final height = isCompact ? 48.0 : 56.0;

    Widget buildButton(String label, VoidCallback onPressed) {
      return Expanded(
        child: SizedBox(
          height: height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF253044),
              backgroundColor: Colors.white.withValues(alpha: 0.72),
              elevation: 0,
              side: const BorderSide(color: AppColors.borderLight, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              textStyle: GoogleFonts.notoSans(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(label),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Row(
          children: [
            buildButton('힌트'.tr, onHint),
            SizedBox(width: isCompact ? 10 : 16),
            buildButton('초기화'.tr, onReset),
          ],
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
