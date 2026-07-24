part of '../numbering_game_page.dart';

class _DragDropEditor extends StatefulWidget {
  const _DragDropEditor({
    required this.digits,
    required this.operators,
    required this.parentheses,
    required this.liftedIndices,
    required this.availableOperators,
    required this.accent,
    required this.selectedDigitIndex,
    required this.onDigitTapped,
    required this.onDigitLiftToggled,
    required this.onDigitReordered,
    required this.onOperatorChanged,
    required this.isLandscape,
    required this.visibleHints,
    required this.allowDigitReordering,
  });

  final List<String> digits;
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
  final Set<int> liftedIndices;
  final Set<String> availableOperators;
  final Color accent;
  final int? selectedDigitIndex;
  final ValueChanged<int> onDigitTapped;
  final ValueChanged<int> onDigitLiftToggled;
  final void Function(int fromIndex, int toIndex) onDigitReordered;
  final void Function(int index, InlineOperator? value) onOperatorChanged;
  final bool isLandscape;
  final List<String> visibleHints;
  final bool allowDigitReordering;

  @override
  State<_DragDropEditor> createState() => _DragDropEditorState();
}

class _DragDropEditorState extends State<_DragDropEditor> {
  static const double _exponentLiftFactor = 0.48;

  final GlobalKey _formulaRowKey = GlobalKey();
  late List<GlobalKey> _slotKeys;
  int? _hoveredSlotIndex;
  int? _draggingDigitIndex;
  int? _previewLiftedDigitIndex;

  @override
  void initState() {
    super.initState();
    _slotKeys = _createSlotKeys();
  }

  @override
  void didUpdateWidget(covariant _DragDropEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final slotCount = widget.digits.length - 1;
    if (_slotKeys.length != slotCount) {
      _slotKeys = _createSlotKeys();
      _hoveredSlotIndex = null;
      _draggingDigitIndex = null;
      _previewLiftedDigitIndex = null;
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
        final compact = constraints.maxWidth < 600 || viewport.height < 560;
        final digitFontSize = compact
            ? (constraints.maxWidth / (widget.digits.length * 1.12))
                .clamp(isLandscape ? 56.0 : 34.0, isLandscape ? 78.0 : 58.0)
            : (constraints.maxWidth * 0.08).clamp(62.0, 96.0);
        final digitPadding = compact
            ? (widget.digits.length >= 8 ? 4.0 : (isLandscape ? 14.0 : 7.0))
            : 13.0;
        final operatorFontSize = (digitFontSize * 0.55).clamp(24.0, 48.0);
        final exponentAvailable =
            widget.availableOperators.contains(InlineOperator.exponent.symbol);
        final exponentTargetHeight =
            exponentAvailable ? (digitFontSize * 0.58).clamp(32.0, 48.0) : 0.0;
        final exponentFontSize = (digitFontSize * 0.52).clamp(18.0, 42.0);
        final exponentHorizontalPadding = (digitPadding * 0.18).clamp(1.5, 2.0);

        final items = List<Widget>.generate(widget.digits.length, (digitIndex) {
          final isLifted = widget.liftedIndices.contains(digitIndex);
          final isLiftPreview = _previewLiftedDigitIndex == digitIndex;
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
            color: const Color(0xFF17191D),
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
          final exponentTextPainter = TextPainter(
            text: TextSpan(
              text: textContent,
              style: TextStyle(
                fontSize: exponentFontSize,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final exponentReservedWidth =
              exponentTextPainter.width + exponentHorizontalPadding * 2;
          exponentTextPainter.dispose();

          Widget digitSurface({
            Key? key,
            bool feedback = false,
            bool dropHighlighted = false,
            bool isGhost = false,
            bool isFeedback = false,
          }) {
            final effectiveIsLifted = isGhost || isLifted;

            return SizedBox(
              width: effectiveIsLifted
                  ? exponentReservedWidth
                  : reservedSize.width,
              height: reservedSize.height,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Transform.translate(
                    offset: Offset(
                      0,
                      effectiveIsLifted
                          ? -digitFontSize * _exponentLiftFactor
                          : 0,
                    ),
                    child: GestureDetector(
                      key: key,
                      behavior: HitTestBehavior.opaque,
                      onTap: feedback || isGhost
                          ? null
                          : () {
                              if (isLifted) {
                                widget.onDigitLiftToggled(digitIndex);
                              } else {
                                widget.onDigitTapped(digitIndex);
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: EdgeInsets.symmetric(
                          horizontal: effectiveIsLifted
                              ? exponentHorizontalPadding
                              : digitPadding,
                          vertical: effectiveIsLifted ? 4 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: dropHighlighted
                              ? widget.accent.withValues(alpha: 0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Opacity(
                          opacity: isGhost ? 0.45 : 1.0,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: TextStyle(
                              fontSize: isFeedback
                                  ? digitFontSize * 0.7
                                  : (effectiveIsLifted
                                      ? exponentFontSize
                                      : digitFontSize),
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: isGhost
                                  ? widget.accent
                                  : (selected
                                      ? widget.accent
                                      : const Color(0xFF17191D)),
                            ),
                            child: Text(
                              textContent,
                              key: isGhost
                                  ? ValueKey(
                                      'formula-digit-preview-$digitIndex')
                                  : (feedback
                                      ? null
                                      : ValueKey(
                                          'formula-digit-text-$digitIndex')),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final Widget digit;
          final canLiftAsExponent = exponentAvailable && digitIndex > 0;
          final canDrag = widget.allowDigitReordering || canLiftAsExponent;

          Widget draggableDigit(Widget surface) => Draggable<int>(
                key: ValueKey('formula-digit-drag-$digitIndex'),
                data: digitIndex,
                onDragStarted: () {
                  setState(() {
                    _draggingDigitIndex = digitIndex;
                    _previewLiftedDigitIndex = null;
                  });
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
                childWhenDragging: isLiftPreview
                    ? digitSurface(isGhost: true)
                    : Opacity(opacity: 0.24, child: surface),
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
          } else if (canDrag) {
            digit = KeyedSubtree(
              key: ValueKey('formula-digit-$digitIndex'),
              child: draggableDigit(
                digitSurface(),
              ),
            );
          } else {
            digit = KeyedSubtree(
              key: ValueKey('formula-digit-$digitIndex'),
              child: digitSurface(),
            );
          }

          Widget digitWithTopLiftTarget;
          if (canLiftAsExponent) {
            digitWithTopLiftTarget = Stack(
              clipBehavior: Clip.none,
              children: [
                digit,
                // Top lift drag target (invisible area above digit)
                if (_draggingDigitIndex == digitIndex)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: exponentTargetHeight,
                    child: DragTarget<int>(
                      key: const ValueKey('exponent-lift-target'),
                      onWillAcceptWithDetails: (details) {
                        final accepts = details.data == digitIndex;
                        if (accepts) _showLiftPreview(digitIndex);
                        return accepts;
                      },
                      onLeave: (data) {
                        if (data == digitIndex) _hideLiftPreview(digitIndex);
                      },
                      onAcceptWithDetails: (_) {
                        _hideLiftPreview(digitIndex);
                        widget.onDigitLiftToggled(digitIndex);
                      },
                      builder: (_, __, ___) => const SizedBox.expand(),
                    ),
                  ),
              ],
            );
          } else {
            digitWithTopLiftTarget = digit;
          }

          if (digitIndex == 0) {
            return Padding(
              padding: EdgeInsets.only(top: exponentTargetHeight),
              child: digitWithTopLiftTarget,
            );
          }

          final slotIndex = digitIndex - 1;
          final isLeftLifted = widget.liftedIndices.contains(slotIndex);
          final isRightLifted = widget.liftedIndices.contains(digitIndex) ||
              _previewLiftedDigitIndex == digitIndex;

          return _InlineOperatorTarget(
            key: _slotKeys[slotIndex],
            current: widget.operators[slotIndex],
            digit: digitWithTopLiftTarget,
            accent: widget.accent,
            digitFontSize: digitFontSize,
            exponentFontSize: exponentFontSize,
            operatorFontSize: operatorFontSize,
            horizontalPadding: digitPadding * 0.65,
            hovering: _hoveredSlotIndex == slotIndex,
            exponentAvailable: exponentAvailable,
            exponentTargetHeight: exponentTargetHeight,
            isExponentZone: isLeftLifted && isRightLifted,
            isExponentTransition: !isLeftLifted && isRightLifted,
            onRemove: () => widget.onOperatorChanged(slotIndex, null),
          );
        });

        return Column(
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
                                      key: ValueKey('inline-level-hint-$index'),
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
            const Spacer(),
            _OperatorPalette(
              availableOperators: widget.availableOperators,
              compact: compact,
              onDragUpdate: _updateOperatorHover,
              onDragEnd: _placeOperator,
            ),
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
    if (!mounted) return;
    if (_draggingDigitIndex == null && _previewLiftedDigitIndex == null) return;
    setState(() {
      _draggingDigitIndex = null;
      _previewLiftedDigitIndex = null;
    });
  }

  void _showLiftPreview(int digitIndex) {
    if (!mounted || _previewLiftedDigitIndex == digitIndex) return;
    setState(() => _previewLiftedDigitIndex = digitIndex);
  }

  void _hideLiftPreview(int digitIndex) {
    if (!mounted || _previewLiftedDigitIndex != digitIndex) return;
    setState(() => _previewLiftedDigitIndex = null);
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

// ─── 인라인 연산자 타겟 ─────────────────────────────────────

class _InlineOperatorTarget extends StatelessWidget {
  const _InlineOperatorTarget({
    super.key,
    required this.current,
    required this.digit,
    required this.accent,
    required this.digitFontSize,
    required this.exponentFontSize,
    required this.operatorFontSize,
    required this.horizontalPadding,
    required this.hovering,
    required this.exponentAvailable,
    required this.exponentTargetHeight,
    required this.isExponentZone,
    required this.isExponentTransition,
    required this.onRemove,
  });

  final InlineOperator? current;
  final Widget digit;
  final Color accent;
  final double digitFontSize;
  final double exponentFontSize;
  final double operatorFontSize;
  final double horizontalPadding;
  final bool hovering;
  final bool exponentAvailable;
  final double exponentTargetHeight;
  final bool isExponentZone;
  final bool isExponentTransition;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: exponentTargetHeight),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                curve: Curves.easeOutCubic,
                width:
                    hovering && current == null ? operatorFontSize * 0.75 : 0,
              ),
              if (isExponentTransition)
                SizedBox(width: horizontalPadding * 0.2)
              else if (current case final current?)
                GestureDetector(
                  onTap: onRemove,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isExponentZone
                          ? horizontalPadding * 0.4
                          : horizontalPadding,
                    ),
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        isExponentZone
                            ? -digitFontSize *
                                    _DragDropEditorState._exponentLiftFactor +
                                (digitFontSize - exponentFontSize + 8) / 2
                            : 0,
                      ),
                      child: Text(
                        current.symbol,
                        style: TextStyle(
                          fontSize: isExponentZone
                              ? operatorFontSize * 0.6
                              : operatorFontSize,
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
          ),
        ),
      ],
    );
  }
}

// ─── 연산자 팔레트 ─────────────────────────────────────────

class _OperatorPalette extends StatefulWidget {
  const _OperatorPalette({
    required this.availableOperators,
    required this.compact,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Set<String> availableOperators;
  final bool compact;
  final ValueChanged<Offset> onDragUpdate;
  final void Function(InlineOperator operator, Offset feedbackCenter) onDragEnd;

  @override
  State<_OperatorPalette> createState() => _OperatorPaletteState();
}

class _OperatorPaletteState extends State<_OperatorPalette> {
  InlineOperator? _dragging;

  @override
  Widget build(BuildContext context) {
    final operators = InlineOperator.values
        .where((operator) =>
            operator != InlineOperator.exponent &&
            widget.availableOperators.contains(operator.symbol))
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
              key: ValueKey('operator-drag-${operators[index].symbol}'),
              data: operators[index],
              onDragStarted: () => setState(() => _dragging = operators[index]),
              dragAnchorStrategy: (_, __, ___) => Offset(size / 2, size * 1.35),
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
                child: _OperatorButton(
                  operator: operators[index],
                  size: size,
                  active: true,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _OperatorButton(
                  operator: operators[index],
                  size: size,
                  active: false,
                ),
              ),
              child: _OperatorButton(
                operator: operators[index],
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
