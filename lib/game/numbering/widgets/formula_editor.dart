part of '../numbering_game_page.dart';

// ─── 수식 편집기 ────────────────────────────────────────────

class _FormulaEditor extends StatefulWidget {
  const _FormulaEditor({
    super.key,
    required this.digits,
    required this.availableOperators,
    required this.accent,
    required this.isLandscape,
    required this.visibleHints,
    required this.requiresEquals,
    this.allowDigitReordering = false,
    this.initialProgress,
    this.onProgressChanged,
    required this.validateExpression,
    required this.onValidSubmission,
  });

  final List<String> digits;
  final Set<String> availableOperators;
  final Color accent;
  final bool isLandscape;
  final List<String> visibleHints;
  final bool requiresEquals;
  final bool allowDigitReordering;
  final DailyPuzzleProgress? initialProgress;
  final ValueChanged<DailyPuzzleProgress>? onProgressChanged;
  final ValidationResult Function(String expression) validateExpression;
  final void Function(String expression, int score) onValidSubmission;

  @override
  State<_FormulaEditor> createState() => _FormulaEditorState();
}

class _EditorSnapshot {
  _EditorSnapshot(this.operators, this.parentheses, this.liftedIndices);
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
  final Set<int> liftedIndices;
}

class _FormulaEditorState extends State<_FormulaEditor> {
  late List<String> _digits;
  late List<InlineOperator?> _operators;
  final List<ParenthesisRange> _parentheses = [];
  final Set<int> _liftedIndices = {};
  final List<_EditorSnapshot> _history = [];
  int? _selectedDigitIndex;
  String? _message;

  String get _expression => assembleInlineExpression(
        digits: _digits,
        operators: _operators,
        parentheses: _parentheses,
        liftedIndices: _liftedIndices,
      );

  @override
  void initState() {
    super.initState();
    final restored = _validatedProgress(widget.initialProgress);
    _digits =
        restored == null ? List.of(widget.digits) : List.of(restored.digits);
    _operators = restored == null
        ? List.filled(widget.digits.length - 1, null)
        : restored.operators.map(_operatorForSymbol).toList(growable: false);
    if (restored != null) {
      _parentheses.addAll(
        restored.parentheses.map(
          (range) => ParenthesisRange(
            id: '${range.start}:${range.end}',
            startDigitIndex: range.start,
            endDigitIndex: range.end,
          ),
        ),
      );
      _liftedIndices.addAll(restored.liftedIndices);
      _clearExponentTransitionOperators();
    }
    _message = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 470;
        return Column(
          children: [
            SizedBox(height: compact ? 18 : 32),
            Expanded(
              child: _DragDropEditor(
                digits: _digits,
                operators: _operators,
                parentheses: _parentheses,
                liftedIndices: _liftedIndices,
                availableOperators: widget.availableOperators,
                accent: widget.accent,
                selectedDigitIndex: _selectedDigitIndex,
                isLandscape: widget.isLandscape,
                visibleHints: widget.visibleHints,
                allowDigitReordering: widget.allowDigitReordering,
                onDigitTapped: _handleDigitTap,
                onDigitLiftToggled: _toggleLiftDigit,
                onDigitReordered: _reorderDigit,
                onOperatorChanged: _changeOperator,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              child: _message == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: compact ? 4 : 10),
          ],
        );
      },
    );
  }

  void _saveSnapshot() {
    _history.add(_EditorSnapshot(
        List.of(_operators), List.of(_parentheses), Set.of(_liftedIndices)));
  }

  void _toggleLiftDigit(int index) {
    if (index == 0 && !_liftedIndices.contains(0)) {
      // First digit cannot be lifted as an exponent (needs a base before it)
      return;
    }
    _saveSnapshot();
    setState(() {
      if (_liftedIndices.contains(index)) {
        _liftedIndices.remove(index);
      } else {
        _liftedIndices.add(index);
      }
      _clearExponentTransitionOperators();
      _selectedDigitIndex = null;
      _message = null;
    });
    _notifyProgressChanged();
    _previewValidation();
  }

  void _changeOperator(int index, InlineOperator? value) {
    _saveSnapshot();
    setState(() {
      _operators[index] = _isExponentTransition(index) ? null : value;
      _message = null;
    });
    _notifyProgressChanged();
    _previewValidation();
  }

  void _reorderDigit(int fromIndex, int toIndex) {
    if (!widget.allowDigitReordering || fromIndex == toIndex) return;
    _saveSnapshot();
    setState(() {
      final digit = _digits.removeAt(fromIndex);
      _digits.insert(toIndex, digit);

      // Re-map lifted indices after reordering
      final wasLifted = _liftedIndices.contains(fromIndex);
      final newLifted = <int>{};
      for (final idx in _liftedIndices) {
        var newIdx = idx;
        if (idx == fromIndex) continue;
        if (fromIndex < toIndex && idx > fromIndex && idx <= toIndex) {
          newIdx--;
        } else if (fromIndex > toIndex && idx >= toIndex && idx < fromIndex) {
          newIdx++;
        }
        newLifted.add(newIdx);
      }
      if (wasLifted) {
        newLifted.add(toIndex);
      }
      // Ensure index 0 is not lifted
      newLifted.remove(0);
      _liftedIndices
        ..clear()
        ..addAll(newLifted);
      _clearExponentTransitionOperators();

      _selectedDigitIndex = null;
      _message = null;
    });
    _notifyProgressChanged();
    _previewValidation();
  }

  void _handleDigitTap(int index) {
    if (_liftedIndices.contains(index)) {
      // Tapping a lifted digit unlifts it (brings it down)
      _toggleLiftDigit(index);
      return;
    }

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
      _saveSnapshot();
      setState(() {
        _parentheses.removeAt(existingIndex);
        _selectedDigitIndex = null;
        _message = null;
      });
      _notifyProgressChanged();
      return;
    }
    final validation = validateParenthesisRange(
      digitCount: _digits.length,
      candidate: candidate,
      existing: _parentheses,
    );
    if (!validation.valid) {
      setState(() {
        _selectedDigitIndex = null;
        _message = validation.message;
      });
      return;
    }
    _saveSnapshot();
    setState(() {
      _parentheses.add(candidate);
      _selectedDigitIndex = null;
      _message = null;
    });
    _notifyProgressChanged();
  }

  void _previewValidation() {
    if (widget.requiresEquals && !_operators.contains(InlineOperator.equals)) {
      if (mounted && _message != null) setState(() => _message = null);
      return;
    }

    final expression = _expression;
    final result = widget.validateExpression(expression);

    if (!result.valid && mounted) {
      setState(() => _message = result.message);
    } else if (result.valid) {
      // Show success briefly before completing
      setState(() => _message = '정답입니다! 🎉');
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _expression == expression) {
          widget.onValidSubmission(expression, result.value!);
        }
      });
    }
  }

  void reset() {
    setState(() {
      _digits = List.of(widget.digits);
      _operators = List.filled(widget.digits.length - 1, null);
      _parentheses.clear();
      _liftedIndices.clear();
      _history.clear();
      _selectedDigitIndex = null;
      _message = null;
    });
    _notifyProgressChanged();
  }

  void showMessage(String message) => setState(() => _message = message);

  DailyPuzzleProgress? _validatedProgress(DailyPuzzleProgress? progress) {
    if (progress == null || !widget.allowDigitReordering) return null;
    if (progress.digits.length != widget.digits.length ||
        progress.operators.length != widget.digits.length - 1) {
      return null;
    }
    final expectedDigits = List.of(widget.digits)..sort();
    final restoredDigits = List.of(progress.digits)..sort();
    if (!listEquals(expectedDigits, restoredDigits)) return null;
    if (progress.operators.any(
      (symbol) => symbol != null && _operatorForSymbol(symbol) == null,
    )) {
      return null;
    }

    final acceptedRanges = <ParenthesisRange>[];
    for (final range in progress.parentheses) {
      final candidate = ParenthesisRange(
        id: '${range.start}:${range.end}',
        startDigitIndex: range.start,
        endDigitIndex: range.end,
      ).normalized();
      final validation = validateParenthesisRange(
        digitCount: progress.digits.length,
        candidate: candidate,
        existing: acceptedRanges,
      );
      if (!validation.valid) return null;
      acceptedRanges.add(candidate);
    }
    return progress;
  }

  InlineOperator? _operatorForSymbol(String? symbol) {
    for (final operator in InlineOperator.values) {
      if (operator.symbol == symbol) return operator;
    }
    return null;
  }

  bool _isExponentTransition(int operatorIndex) {
    return !_liftedIndices.contains(operatorIndex) &&
        _liftedIndices.contains(operatorIndex + 1);
  }

  void _clearExponentTransitionOperators() {
    for (var index = 0; index < _operators.length; index++) {
      if (_isExponentTransition(index)) _operators[index] = null;
    }
  }

  void _notifyProgressChanged() {
    widget.onProgressChanged?.call(
      DailyPuzzleProgress(
        digits: List.unmodifiable(_digits),
        operators: List.unmodifiable(
          _operators.map((operator) => operator?.symbol),
        ),
        parentheses: List.unmodifiable(
          _parentheses.map(
            (range) {
              final normalized = range.normalized();
              return DailyPuzzleParenthesis(
                start: normalized.startDigitIndex,
                end: normalized.endDigitIndex,
              );
            },
          ),
        ),
        liftedIndices: List.unmodifiable(_liftedIndices.toList()..sort()),
      ),
    );
  }
}

// ─── 드래그 드롭 편집기 ──────────────────────────────────────
