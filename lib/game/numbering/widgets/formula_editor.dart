import 'package:flutter/material.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/game/numbering/widgets/drag_drop_editor.dart';
import 'package:numbering/services/app_haptics.dart';

// ─── 수식 편집기 ────────────────────────────────────────────

class FormulaEditor extends StatefulWidget {
  const FormulaEditor({
    super.key,
    required this.digits,
    required this.availableOperators,
    required this.accent,
    required this.isLandscape,
    required this.visibleHints,
    required this.requiresEquals,
    this.allowDigitReordering = false,
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
  final ValidationResult Function(String expression) validateExpression;
  final void Function(String expression, int score) onValidSubmission;

  @override
  State<FormulaEditor> createState() => FormulaEditorState();
}

class _EditorSnapshot {
  _EditorSnapshot(this.operators, this.parentheses);
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
}

class FormulaEditorState extends State<FormulaEditor>
    with SingleTickerProviderStateMixin {
  late List<String> _digits;
  late List<InlineOperator?> _operators;
  late final AnimationController _wrongAnswerController;
  late final Animation<double> _wrongAnswerProgress;
  final List<ParenthesisRange> _parentheses = [];
  final List<_EditorSnapshot> _history = [];
  int? _selectedDigitIndex;
  bool _parenthesisMode = false;
  String? _message;

  String get _expression => assembleInlineExpression(
        digits: _digits,
        operators: _operators,
        parentheses: _parentheses,
      );

  @override
  void initState() {
    super.initState();
    _digits = List.of(widget.digits);
    _operators = List.filled(widget.digits.length - 1, null);
    _wrongAnswerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _wrongAnswerProgress = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 350,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 100,
      ),
    ]).animate(_wrongAnswerController);
    _message = null;
  }

  @override
  void dispose() {
    _wrongAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 470;
        return AnimatedBuilder(
          animation: _wrongAnswerProgress,
          builder: (context, _) {
            final wrongAnswerProgress = _wrongAnswerProgress.value;
            return KeyedSubtree(
              key: const ValueKey('wrong-answer-flash'),
              child: Column(
                children: [
                  SizedBox(height: compact ? 18 : 32),
                  Expanded(
                    child: DragDropEditor(
                      digits: _digits,
                      operators: _operators,
                      parentheses: _parentheses,
                      availableOperators: widget.availableOperators,
                      accent: widget.accent,
                      selectedDigitIndex: _selectedDigitIndex,
                      parenthesisMode: _parenthesisMode,
                      isLandscape: widget.isLandscape,
                      visibleHints: widget.visibleHints,
                      allowDigitReordering: widget.allowDigitReordering,
                      wrongAnswerProgress: wrongAnswerProgress,
                      onDigitTapped: _handleDigitTap,
                      onParenthesisModeToggled: _toggleParenthesisMode,
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
              ),
            );
          },
        );
      },
    );
  }

  void _saveSnapshot() {
    _history.add(_EditorSnapshot(List.of(_operators), List.of(_parentheses)));
  }

  void _changeOperator(int index, InlineOperator? value) {
    AppHaptics.selection();
    _saveSnapshot();
    setState(() {
      _operators[index] = value;
      _parenthesisMode = false;
      _selectedDigitIndex = null;
      _message = null;
    });
    _previewValidation();
  }

  void _reorderDigit(int fromIndex, int toIndex) {
    if (!widget.allowDigitReordering || fromIndex == toIndex) return;
    AppHaptics.selection();
    _saveSnapshot();
    setState(() {
      final sourceDigit = _digits[fromIndex];
      _digits[fromIndex] = _digits[toIndex];
      _digits[toIndex] = sourceDigit;

      _selectedDigitIndex = null;
      _parenthesisMode = false;
      _message = null;
    });
    _previewValidation();
  }

  void _handleDigitTap(int index) {
    if (_selectedDigitIndex == null) {
      setState(() {
        _selectedDigitIndex = index;
        _message = null;
      });
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
        _parenthesisMode = false;
        _message = null;
      });
      _previewValidation();
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
      _parenthesisMode = false;
      _message = null;
    });
    _previewValidation();
  }

  void _previewValidation() {
    if (widget.requiresEquals && !_operators.contains(InlineOperator.equals)) {
      if (mounted && _message != null) setState(() => _message = null);
      return;
    }

    final expression = _expression;
    final result = widget.validateExpression(expression);

    if (!result.valid && mounted) {
      if (_message != null) setState(() => _message = null);
      _wrongAnswerController.forward(from: 0);
    } else if (result.valid) {
      AppHaptics.success();
      setState(() => _message = '정답입니다!');
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
      _history.clear();
      _selectedDigitIndex = null;
      _parenthesisMode = false;
      _message = null;
    });
  }

  void showMessage(String message) => setState(() => _message = message);

  void _toggleParenthesisMode() {
    setState(() {
      _parenthesisMode = !_parenthesisMode;
      _selectedDigitIndex = null;
      _message = null;
    });
  }
}
