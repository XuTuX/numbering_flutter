part of 'package:numbering/widgets/home_screen/login_sheet.dart';

/// A quiet, non-interactive loop of Numbering's core arithmetic gesture.
class _LoginNumberMotion extends StatefulWidget {
  const _LoginNumberMotion();

  @override
  State<_LoginNumberMotion> createState() => _LoginNumberMotionState();
}

class _LoginNumberMotionState extends State<_LoginNumberMotion>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  late final AnimationController _controller;
  late List<_MotionExpression> _expressions;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addStatusListener(_handleAnimationStatus);
    _expressions = _createExpressionPair();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !mounted ||
        (_reduceMotion ?? false)) {
      return;
    }

    setState(() => _expressions = _createExpressionPair());
    _controller.forward(from: 0);
  }

  List<_MotionExpression> _createExpressionPair() {
    final first = _createExpression();
    var second = _createExpression();
    while (second.values.join() == first.values.join()) {
      second = _createExpression();
    }
    return [first, second];
  }

  _MotionExpression _createExpression() {
    final addition = _random.nextBool();
    if (addition) {
      final left = _random.nextInt(9) + 1;
      final right = _random.nextInt(9) + 1;
      return _MotionExpression(
          ['$left', '+', '$right', '=', '${left + right}']);
    }

    final left = _random.nextInt(15) + 4;
    final right = _random.nextInt(left - 1) + 1;
    return _MotionExpression(['$left', '−', '$right', '=', '${left - right}']);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;

    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0.7;
    } else if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        key: const ValueKey('login-number-motion'),
        child: SizedBox(
          height: 84,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = Curves.easeInOut.transform(_controller.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  _MotionEquation(
                    progress: progress,
                    start: 0,
                    exitStart: 0.38,
                    values: _expressions[0].values,
                  ),
                  _MotionEquation(
                    progress: progress,
                    start: 0.46,
                    exitStart: 0.86,
                    values: _expressions[1].values,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MotionExpression {
  const _MotionExpression(this.values);

  final List<String> values;
}

class _MotionEquation extends StatelessWidget {
  const _MotionEquation({
    required this.progress,
    required this.start,
    required this.values,
    this.exitStart,
  });

  final double progress;
  final double start;
  final double? exitStart;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final local = ((progress - start) / 0.32).clamp(0.0, 1.0);
    final exit = exitStart == null
        ? 0.0
        : ((progress - exitStart!) / 0.14).clamp(0.0, 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(values.length, (index) {
        final delay = index * 0.12;
        final entrance = Curves.easeOutBack.transform(
          ((local - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        final opacity = (entrance * (1 - exit)).clamp(0.0, 1.0);
        final value = values[index];
        final isDigit = index.isEven;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isDigit ? 4 : 2),
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, (1 - entrance) * 16 - exit * 12),
              child: Transform.rotate(
                angle: (1 - entrance) * (index.isEven ? -0.05 : 0.05),
                child: _MotionTile(
                  value: value,
                  isOperator: !isDigit,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MotionTile extends StatelessWidget {
  const _MotionTile({
    required this.value,
    required this.isOperator,
  });

  final String value;
  final bool isOperator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isOperator ? 28 : 48,
      height: isOperator ? 40 : 56,
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isOperator ? 22 : 27,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
      ),
    );
  }
}
