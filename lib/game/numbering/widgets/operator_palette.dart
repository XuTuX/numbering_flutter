import 'package:flutter/material.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';

class OperatorPalette extends StatefulWidget {
  const OperatorPalette({
    super.key,
    required this.availableOperators,
    required this.compact,
    required this.scaleFactor,
    required this.parenthesisMode,
    required this.onParenthesisModeToggled,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Set<String> availableOperators;
  final bool compact;
  final double scaleFactor;
  final bool parenthesisMode;
  final VoidCallback onParenthesisModeToggled;
  final ValueChanged<Offset> onDragUpdate;
  final void Function(InlineOperator operator, Offset feedbackCenter) onDragEnd;

  @override
  State<OperatorPalette> createState() => _OperatorPaletteState();
}

class _OperatorPaletteState extends State<OperatorPalette> {
  InlineOperator? _dragging;

  @override
  Widget build(BuildContext context) {
    final operators = InlineOperator.values
        .where(
            (operator) => widget.availableOperators.contains(operator.symbol))
        .toList();
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final baseSize = widget.compact ? (isLandscape ? 52.0 : 44.0) : 58.0;
    final size = baseSize * widget.scaleFactor;
    final baseHorizontalPadding = widget.compact ? 14.0 : 22.0;
    final baseVerticalPadding = widget.compact ? 10.0 : 14.0;
    final palette = Container(
        padding: EdgeInsets.symmetric(
          horizontal: baseHorizontalPadding * widget.scaleFactor,
          vertical: baseVerticalPadding * widget.scaleFactor,
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
                key: ValueKey('operator-drag-${operators[index].symbol}'),
                data: operators[index],
                onDragStarted: () =>
                    setState(() => _dragging = operators[index]),
                dragAnchorStrategy: (_, __, ___) =>
                    Offset(size / 2, size * 1.35),
                onDragUpdate: (details) {
                  const feedbackCenterFactor = 0.5;
                  final anchor = Offset(size / 2, size * 1.35);
                  final feedbackTopLeft = details.globalPosition - anchor;
                  widget.onDragUpdate(
                    feedbackTopLeft +
                        Offset(
                          size * feedbackCenterFactor,
                          size * feedbackCenterFactor,
                        ),
                  );
                },
                onDragEnd: (details) {
                  setState(() => _dragging = null);
                  widget.onDragEnd(
                    operators[index],
                    details.offset + Offset(size / 2, size / 2),
                  );
                },
                feedback: Material(
                  color: Colors.transparent,
                  child: OperatorButton(
                    operator: operators[index],
                    size: size,
                    active: true,
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: OperatorButton(
                    operator: operators[index],
                    size: size,
                    active: false,
                  ),
                ),
                child: OperatorButton(
                  operator: operators[index],
                  size: size,
                  active: _dragging == operators[index],
                ),
              ),
            ],
          ],
        ));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Center(child: palette),
          ),
        );
      },
    );
  }
}

class OperatorButton extends StatelessWidget {
  const OperatorButton({
    super.key,
    required this.operator,
    required this.size,
    required this.active,
  });

  final InlineOperator operator;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.blockCream : AppColors.surfaceSecondary,
        shape: BoxShape.circle,
      ),
      child: Text(
        operator.symbol,
        style: TextStyle(
          fontSize: size * 0.42,
          color: const Color(0xFF253044),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
