part of '../numbering_game_page.dart';

class _DailyFormulaEditor extends StatefulWidget {
  const _DailyFormulaEditor({
    super.key,
    required this.digits,
    required this.accent,
    required this.onValidSubmission,
  });

  final List<String> digits;
  final Color accent;
  final void Function(String expression, int score) onValidSubmission;

  @override
  State<_DailyFormulaEditor> createState() => _DailyFormulaEditorState();
}

class _DailyFormulaEditorState extends State<_DailyFormulaEditor> {
  String _expression = '';
  String? _message;
  late List<bool> _usedDigits;

  @override
  void initState() {
    super.initState();
    _usedDigits = List.filled(widget.digits.length, false);
  }

  void _append(String char, {int? digitIndex}) {
    setState(() {
      _expression += char;
      if (digitIndex != null) {
        _usedDigits[digitIndex] = true;
      }
      _message = null;
    });
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    
    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
      _recalculateUsedDigits();
      _message = null;
    });
  }
  
  void _recalculateUsedDigits() {
    _usedDigits = List.filled(widget.digits.length, false);
    final exprDigits = _expression.replaceAll(RegExp(r'[^0-9]'), '').split('');
    for (final d in exprDigits) {
      for (int i = 0; i < widget.digits.length; i++) {
        if (!_usedDigits[i] && widget.digits[i] == d) {
          _usedDigits[i] = true;
          break;
        }
      }
    }
  }

  void _submit() {
    final result = validateDailyPuzzleFormula(
      digitString: widget.digits.join(''),
      expression: _expression,
    );
    if (!result.valid) {
      setState(() => _message = result.message);
      return;
    }
    widget.onValidSubmission(_expression, result.value!);
  }
  
  void reset() {
    setState(() {
      _expression = '';
      _usedDigits = List.filled(widget.digits.length, false);
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Expression Display
        Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.centerRight,
          child: Text(
            _expression.isEmpty ? '수식을 입력하세요' : _expression,
            style: TextStyle(
              fontSize: _expression.isEmpty ? 20 : 32,
              fontWeight: FontWeight.bold,
              color: _expression.isEmpty ? AppColors.textSecondary : widget.accent,
            ),
            maxLines: 1,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Validation Message
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          child: _message == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Digits
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(widget.digits.length, (i) {
                    final isUsed = _usedDigits[i];
                    return _CalcButton(
                      label: widget.digits[i],
                      isUsed: isUsed,
                      onTap: isUsed ? null : () => _append(widget.digits[i], digitIndex: i),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                // Operators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CalcOpButton(label: '+', onTap: () => _append('+')),
                    _CalcOpButton(label: '-', onTap: () => _append('-')),
                    _CalcOpButton(label: '×', onTap: () => _append('×')),
                    _CalcOpButton(label: '÷', onTap: () => _append('÷')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CalcOpButton(label: '(', onTap: () => _append('(')),
                    _CalcOpButton(label: ')', onTap: () => _append(')')),
                    _CalcOpButton(
                      label: '⌫', 
                      onTap: _backspace,
                      color: AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      '제출',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({required this.label, required this.isUsed, required this.onTap});
  final String label;
  final bool isUsed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isUsed ? const Color(0xFFF0F1F3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUsed ? Colors.transparent : AppColors.borderLight,
            width: 1.5,
          ),
          boxShadow: isUsed ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: isUsed ? AppColors.textSecondary.withValues(alpha: 0.3) : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CalcOpButton extends StatelessWidget {
  const _CalcOpButton({required this.label, required this.onTap, this.color});
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
