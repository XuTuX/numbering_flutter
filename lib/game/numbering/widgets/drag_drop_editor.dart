import 'package:flutter/material.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/game/numbering/widgets/operator_palette.dart';

class DragDropEditor extends StatefulWidget {
  const DragDropEditor({
    super.key,
    required this.digits,
    required this.operators,
    required this.parentheses,
    required this.availableOperators,
    required this.accent,
    required this.selectedDigitIndex,
    required this.parenthesisMode,
    required this.onDigitTapped,
    required this.onParenthesisModeToggled,
    required this.onDigitReordered,
    required this.onOperatorChanged,
    required this.isLandscape,
    required this.visibleHints,
    required this.allowDigitReordering,
    required this.wrongAnswerProgress,
  });

  final List<String> digits;
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
  final Set<String> availableOperators;
  final Color accent;
  final int? selectedDigitIndex;
  final bool parenthesisMode;
  final ValueChanged<int> onDigitTapped;
  final VoidCallback onParenthesisModeToggled;
  final void Function(int fromIndex, int toIndex) onDigitReordered;
  final void Function(int index, InlineOperator? value) onOperatorChanged;
  final bool isLandscape;
  final List<String> visibleHints;
  final bool allowDigitReordering;
  final double wrongAnswerProgress;

  @override
  State<DragDropEditor> createState() => _DragDropEditorState();
}

class _DragDropEditorState extends State<DragDropEditor> {
  final GlobalKey _formulaRowKey = GlobalKey();
  late List<GlobalKey> _slotKeys;
  int? _hoveredSlotIndex;
  int? _draggingDigitIndex;

  @override
  void initState() {
    super.initState();
    _slotKeys = _createSlotKeys();
  }

  @override
  void didUpdateWidget(covariant DragDropEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final slotCount = widget.digits.length - 1;
    if (_slotKeys.length != slotCount) {
      _slotKeys = _createSlotKeys();
      _hoveredSlotIndex = null;
      _draggingDigitIndex = null;
    }
  }

  List<GlobalKey> _createSlotKeys() =>
      List.generate(widget.digits.length - 1, (_) => GlobalKey());

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context);
        final isLandscape = viewport.width > viewport.height;
        final isTabletPortrait = !isLandscape && viewport.shortestSide >= 600;
        final compact = constraints.maxWidth < 600 || viewport.height < 560;
        final digitFontSize = compact
            ? (constraints.maxWidth / (widget.digits.length * 1.12))
                .clamp(isLandscape ? 56.0 : 34.0, isLandscape ? 78.0 : 58.0)
            : (constraints.maxWidth * 0.08).clamp(62.0, 96.0);
        final digitPadding = compact
            ? (widget.digits.length >= 8 ? 4.0 : (isLandscape ? 14.0 : 7.0))
            : 13.0;
        final operatorFontSize = (digitFontSize * 0.55).clamp(24.0, 48.0);

        final items = List<Widget>.generate(widget.digits.length, (digitIndex) {
          final openingCount = widget.parentheses
              .where(
                  (range) => range.normalized().startDigitIndex == digitIndex)
              .length;
          final closingCount = widget.parentheses
              .where((range) => range.normalized().endDigitIndex == digitIndex)
              .length;
          final selected = widget.selectedDigitIndex == digitIndex;
          final textContent =
              '${'(' * openingCount}${widget.digits[digitIndex]}${')' * closingCount}';
          final normalTextStyle = TextStyle(
            fontSize: digitFontSize,
            height: 1,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          );
          final normalTextPainter = TextPainter(
            text: TextSpan(text: textContent, style: normalTextStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final reservedSize = Size(
            normalTextPainter.width + digitPadding * 2,
            normalTextPainter.height + 16,
          );
          normalTextPainter.dispose();

          Widget digitSurface({
            Key? key,
            bool feedback = false,
            bool dropHighlighted = false,
            bool isFeedback = false,
          }) {
            return SizedBox(
              width: reservedSize.width,
              height: reservedSize.height,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    key: key,
                    behavior: HitTestBehavior.opaque,
                    onTap: feedback
                        ? null
                        : () => widget.onDigitTapped(digitIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      padding: EdgeInsets.symmetric(
                        horizontal: digitPadding,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: dropHighlighted
                            ? widget.accent.withValues(alpha: 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: widget.wrongAnswerProgress > 0
                            ? Duration.zero
                            : const Duration(milliseconds: 150),
                        style: TextStyle(
                          fontSize:
                              isFeedback ? digitFontSize * 0.7 : digitFontSize,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Color.lerp(
                            selected ? widget.accent : AppColors.ink,
                            AppColors.wrongAnswer,
                            widget.wrongAnswerProgress,
                          ),
                        ),
                        child: Text(
                          textContent,
                          key: feedback
                              ? null
                              : ValueKey('formula-digit-text-$digitIndex'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final Widget digit;

          Widget draggableDigit(Widget surface) => Draggable<int>(
                key: ValueKey('formula-digit-drag-$digitIndex'),
                data: digitIndex,
                onDragStarted: () {
                  setState(() => _draggingDigitIndex = digitIndex);
                },
                onDragCompleted: _finishDigitDrag,
                onDraggableCanceled: (_, __) => _finishDigitDrag(),
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 0.88,
                    child: digitSurface(feedback: true, isFeedback: true),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.24, child: surface),
                child: surface,
              );

          if (widget.allowDigitReordering) {
            digit = DragTarget<int>(
              key: ValueKey('formula-digit-$digitIndex'),
              onWillAcceptWithDetails: (details) => details.data != digitIndex,
              onAcceptWithDetails: (details) =>
                  widget.onDigitReordered(details.data, digitIndex),
              builder: (context, candidateData, rejectedData) {
                final highlighted = candidateData.any(
                  (sourceIndex) => sourceIndex != digitIndex,
                );
                final surface = digitSurface(
                  dropHighlighted: highlighted,
                );
                return draggableDigit(surface);
              },
            );
          } else {
            digit = KeyedSubtree(
              key: ValueKey('formula-digit-$digitIndex'),
              child: digitSurface(),
            );
          }

          if (digitIndex == 0) {
            return digit;
          }

          final slotIndex = digitIndex - 1;

          return InlineOperatorTarget(
            key: _slotKeys[slotIndex],
            current: widget.operators[slotIndex],
            digit: digit,
            accent: widget.accent,
            operatorFontSize: operatorFontSize,
            horizontalPadding: digitPadding * 0.65,
            hovering: _hoveredSlotIndex == slotIndex,
            onRemove: () => widget.onOperatorChanged(slotIndex, null),
          );
        });

        final formulaBody = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: _formulaRowKey,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: items,
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: widget.visibleHints.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            key: const ValueKey('inline-level-hint'),
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.visibleHints.length,
                              (index) => Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: widget.accent.withValues(
                                          alpha: 0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          height: 1,
                                          fontWeight: FontWeight.w800,
                                          color: widget.accent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Flexible(
                                      child: Text(
                                        widget.visibleHints[index],
                                        key: ValueKey(
                                            'inline-level-hint-$index'),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
        final formulaScroller = SingleChildScrollView(child: formulaBody);
        final operatorPalette = OperatorPalette(
          availableOperators: widget.availableOperators,
          compact: compact,
          parenthesisMode: widget.parenthesisMode,
          onParenthesisModeToggled: widget.onParenthesisModeToggled,
          onDragUpdate: _updateOperatorHover,
          onDragEnd: _placeOperator,
        );

        if (isTabletPortrait) {
          return Center(
            child: KeyedSubtree(
              key: const ValueKey('tablet-portrait-game-controls'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  formulaBody,
                  const SizedBox(height: 48),
                  operatorPalette,
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(child: formulaScroller),
            operatorPalette,
          ],
        );
      },
    );
  }

  void _updateOperatorHover(Offset feedbackCenter) {
    final slotIndex = _slotIndexAt(feedbackCenter);
    if (slotIndex == _hoveredSlotIndex) return;
    setState(() => _hoveredSlotIndex = slotIndex);
  }

  void _finishDigitDrag() {
    if (!mounted || _draggingDigitIndex == null) return;
    setState(() => _draggingDigitIndex = null);
  }

  void _placeOperator(InlineOperator operator, Offset feedbackCenter) {
    final slotIndex = _slotIndexAt(feedbackCenter);
    if (_hoveredSlotIndex != null) {
      setState(() => _hoveredSlotIndex = null);
    }
    if (slotIndex != null) {
      widget.onOperatorChanged(slotIndex, operator);
    }
  }

  int? _slotIndexAt(Offset globalFeedbackCenter) {
    final editorBox =
        _formulaRowKey.currentContext?.findRenderObject() as RenderBox?;
    if (editorBox == null || !editorBox.hasSize) return null;

    final localFeedbackCenter = editorBox.globalToLocal(globalFeedbackCenter);
    for (var index = 0; index < _slotKeys.length; index++) {
      final slotBox =
          _slotKeys[index].currentContext?.findRenderObject() as RenderBox?;
      if (slotBox == null || !slotBox.hasSize) continue;

      final topLeft = slotBox.localToGlobal(Offset.zero, ancestor: editorBox);
      final bottomRight = slotBox.localToGlobal(
        slotBox.size.bottomRight(Offset.zero),
        ancestor: editorBox,
      );
      final slotRect = Rect.fromPoints(topLeft, bottomRight);
      final dropRect = Rect.fromLTRB(
        slotRect.left,
        slotRect.top - 12,
        slotRect.right,
        slotRect.bottom + 12,
      );
      if (dropRect.contains(localFeedbackCenter)) return index;
    }
    return null;
  }
}

class InlineOperatorTarget extends StatelessWidget {
  const InlineOperatorTarget({
    super.key,
    required this.current,
    required this.digit,
    required this.accent,
    required this.operatorFontSize,
    required this.horizontalPadding,
    required this.hovering,
    required this.onRemove,
  });

  final InlineOperator? current;
  final Widget digit;
  final Color accent;
  final double operatorFontSize;
  final double horizontalPadding;
  final bool hovering;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final opticalVerticalOffset = switch (current) {
      InlineOperator.add || InlineOperator.subtract => -operatorFontSize * 0.15,
      _ => 0.0,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOutCubic,
          width: hovering && current == null ? operatorFontSize * 0.75 : 0,
        ),
        if (current case final current?)
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Transform.translate(
                offset: Offset(0, opticalVerticalOffset),
                child: Text(
                  current.symbol,
                  style: TextStyle(
                    fontSize: operatorFontSize,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: hovering ? accent : const Color(0xFF253044),
                  ),
                ),
              ),
            ),
          ),
        digit,
      ],
    );
  }
}
