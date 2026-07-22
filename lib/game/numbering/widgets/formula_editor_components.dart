part of '../numbering_game_page.dart';

class _DragDropEditor extends StatelessWidget {
  const _DragDropEditor({
    required this.digits,
    required this.operators,
    required this.parentheses,
    required this.availableOperators,
    required this.accent,
    required this.selectedDigitIndex,
    required this.onDigitTapped,
    required this.onOperatorChanged,
    required this.isLandscape,
  });

  final List<String> digits;
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
  final Set<String> availableOperators;
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
        final isLandscape = viewport.width > viewport.height;
        final compact = constraints.maxWidth < 600 || viewport.height < 560;
        final digitFontSize = compact
            ? (constraints.maxWidth / (digits.length * 1.12))
                .clamp(isLandscape ? 56.0 : 34.0, isLandscape ? 78.0 : 58.0)
            : (constraints.maxWidth * 0.08).clamp(62.0, 96.0);
        final digitPadding = compact
            ? (digits.length >= 8 ? 3.0 : (isLandscape ? 14.0 : 7.0))
            : 13.0;
        final operatorFontSize = (digitFontSize * 0.55).clamp(24.0, 48.0);
        final items = List<Widget>.generate(digits.length, (digitIndex) {
          final openingCount = parentheses
              .where(
                  (range) => range.normalized().startDigitIndex == digitIndex)
              .length;
          final closingCount = parentheses
              .where((range) => range.normalized().endDigitIndex == digitIndex)
              .length;
          final selected = selectedDigitIndex == digitIndex;
          final digit = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onDigitTapped(digitIndex),
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: digitPadding, vertical: 8),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: digitFontSize,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: selected ? accent : const Color(0xFF17191D),
                ),
                child: Text(
                  '${'(' * openingCount}${digits[digitIndex]}${')' * closingCount}',
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
            onAccept: (operator) => onOperatorChanged(slotIndex, operator),
            onRemove: () => onOperatorChanged(slotIndex, null),
          );
        });

        return Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            ),
            const Spacer(),
            _OperatorPalette(
              accent: accent,
              availableOperators: availableOperators,
              compact: compact,
            ),
          ],
        );
      },
    );
  }
}

// ─── 인라인 연산자 타겟 ─────────────────────────────────────

class _InlineOperatorTarget extends StatefulWidget {
  const _InlineOperatorTarget({
    required this.current,
    required this.digit,
    required this.accent,
    required this.operatorFontSize,
    required this.horizontalPadding,
    required this.onAccept,
    required this.onRemove,
  });

  final InlineOperator? current;
  final Widget digit;
  final Color accent;
  final double operatorFontSize;
  final double horizontalPadding;
  final ValueChanged<InlineOperator> onAccept;
  final VoidCallback onRemove;

  @override
  State<_InlineOperatorTarget> createState() => _InlineOperatorTargetState();
}

class _InlineOperatorTargetState extends State<_InlineOperatorTarget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<InlineOperator>(
      onWillAcceptWithDetails: (_) {
        if (!_hovering) setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) {
        if (_hovering) setState(() => _hovering = false);
      },
      onAcceptWithDetails: (details) {
        if (_hovering) setState(() => _hovering = false);
        widget.onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            curve: Curves.easeOutCubic,
            width: _hovering && widget.current == null
                ? widget.operatorFontSize * 0.75
                : 0,
          ),
          if (widget.current case final current?)
            GestureDetector(
              onTap: widget.onRemove,
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
                child: Text(
                  current.symbol,
                  style: TextStyle(
                    fontSize: widget.operatorFontSize,
                    fontWeight: FontWeight.w700,
                    color: _hovering ? widget.accent : const Color(0xFF253044),
                  ),
                ),
              ),
            ),
          widget.digit,
        ],
      ),
    );
  }
}

// ─── 연산자 팔레트 ─────────────────────────────────────────

class _OperatorPalette extends StatefulWidget {
  const _OperatorPalette({
    required this.accent,
    required this.availableOperators,
    required this.compact,
  });

  final Color accent;
  final Set<String> availableOperators;
  final bool compact;

  @override
  State<_OperatorPalette> createState() => _OperatorPaletteState();
}

class _OperatorPaletteState extends State<_OperatorPalette> {
  InlineOperator? _dragging;

  @override
  Widget build(BuildContext context) {
    final operators = InlineOperator.values
        .where(
            (operator) => widget.availableOperators.contains(operator.symbol))
        .toList();
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final size = widget.compact ? (isLandscape ? 52.0 : 44.0) : 58.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 14 : 22,
        vertical: widget.compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < operators.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Draggable<InlineOperator>(
              data: operators[index],
              onDragStarted: () => setState(() => _dragging = operators[index]),
              onDragEnd: (_) => setState(() => _dragging = null),
              feedback: Material(
                color: Colors.transparent,
                child: _OperatorButton(
                  operator: operators[index],
                  accent: widget.accent,
                  size: size,
                  active: true,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _OperatorButton(
                  operator: operators[index],
                  accent: widget.accent,
                  size: size,
                  active: false,
                ),
              ),
              child: _OperatorButton(
                operator: operators[index],
                accent: widget.accent,
                size: size,
                active: _dragging == operators[index],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 연산자 버튼 ─────────────────────────────────────────

class _OperatorButton extends StatelessWidget {
  const _OperatorButton({
    required this.operator,
    required this.accent,
    required this.size,
    required this.active,
  });

  final InlineOperator operator;
  final Color accent;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? accent : AppColors.surfaceSecondary,
        shape: BoxShape.circle,
      ),
      child: Text(
        operator.symbol,
        style: TextStyle(
          fontSize: size * 0.42,
          color: active ? Colors.white : const Color(0xFF253044),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
