part of '../numbering_game_page.dart';

// ─── 수식 편집기 ────────────────────────────────────────────

class _FormulaEditor extends StatefulWidget {
  const _FormulaEditor({
    super.key,
    required this.level,
    required this.accent,
    required this.isLandscape,
    required this.visibleHint,
    required this.onValidSubmission,
  });

  final LevelData level;
  final Color accent;
  final bool isLandscape;
  final String? visibleHint;
  final void Function(String expression, int score) onValidSubmission;

  @override
  State<_FormulaEditor> createState() => _FormulaEditorState();
}

class _EditorSnapshot {
  _EditorSnapshot(this.operators, this.parentheses);
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
}

class _FormulaEditorState extends State<_FormulaEditor> {
  late List<InlineOperator?> _operators;
  final List<ParenthesisRange> _parentheses = [];
  final List<_EditorSnapshot> _history = [];
  int? _selectedDigitIndex;
  String? _message;

  String get _expression => assembleInlineExpression(
        digits: widget.level.digits,
        operators: _operators,
        parentheses: _parentheses,
      );

  @override
  void initState() {
    super.initState();
    _operators = List.filled(widget.level.digits.length - 1, null);
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
                digits: widget.level.digits,
                operators: _operators,
                parentheses: _parentheses,
                availableOperators: widget.level.availableOperators,
                accent: widget.accent,
                selectedDigitIndex: _selectedDigitIndex,
                isLandscape: widget.isLandscape,
                visibleHint: widget.visibleHint,
                onDigitTapped: _handleDigitTap,
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
    _history.add(_EditorSnapshot(List.of(_operators), List.of(_parentheses)));
  }

  void _changeOperator(int index, InlineOperator? value) {
    _saveSnapshot();
    setState(() {
      _operators[index] = value;
      _message = null;
    });
    _previewValidation();
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
      _saveSnapshot();
      setState(() {
        _parentheses.removeAt(existingIndex);
        _selectedDigitIndex = null;
        _message = null;
      });
      return;
    }
    final validation = validateParenthesisRange(
      digitCount: widget.level.digits.length,
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
  }

  void _previewValidation() {
    if (!_operators.contains(InlineOperator.equals)) return;

    // Only auto-submit if all operators are filled
    if (_operators.contains(null)) {
      // Still show preview message if they somehow filled an equals but not everything
      // Wait, in this game, all operator slots must be filled.
      return;
    }

    final result = validateLevelFormula(
      digitString: widget.level.digitString,
      expression: _expression,
      availableOperators: widget.level.availableOperators,
    );

    if (!result.valid && mounted) {
      setState(() => _message = result.message);
    } else if (result.valid) {
      // Show success briefly before completing
      setState(() => _message = '정답입니다! 🎉');
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          widget.onValidSubmission(_expression, result.value!);
        }
      });
    }
  }

  void reset() {
    setState(() {
      _operators = List.filled(widget.level.digits.length - 1, null);
      _parentheses.clear();
      _history.clear();
      _selectedDigitIndex = null;
      _message = null;
    });
  }

  void showMessage(String message) => setState(() => _message = message);
}

// ─── 드래그 드롭 편집기 ──────────────────────────────────────
