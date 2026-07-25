part of 'package:numbering/widgets/home_screen/login_sheet.dart';

/// A quiet, non-interactive stream of Numbering equations.
class _LoginNumberMotion extends StatefulWidget {
  const _LoginNumberMotion();

  @override
  State<_LoginNumberMotion> createState() => _LoginNumberMotionState();
}

class _LoginNumberMotionState extends State<_LoginNumberMotion>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  late final AnimationController _controller;
  late _MotionScene _currentScene;
  late _MotionScene _nextScene;
  bool? _reduceMotion;
  int _expressionsUntilWordmark = 0;
  String? _lastExpressionKey;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener(_handleAnimationStatus);

    _expressionsUntilWordmark = _nextWordmarkGap();
    _currentScene = _MotionScene.expression(_createExpression());
    _expressionsUntilWordmark--;
    _nextScene = _createNextScene();
  }

  int _nextWordmarkGap() => _random.nextInt(4) + 3;

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !mounted ||
        (_reduceMotion ?? false)) {
      return;
    }

    setState(() {
      _currentScene = _nextScene;
      _nextScene = _createNextScene();
    });
    _controller.forward(from: 0);
  }

  _MotionScene _createNextScene() {
    if (_expressionsUntilWordmark == 0) {
      _expressionsUntilWordmark = _nextWordmarkGap();
      return const _MotionScene.wordmark();
    }

    _expressionsUntilWordmark--;
    return _MotionScene.expression(_createExpression());
  }

  _MotionExpression _createExpression() {
    late List<String> values;
    String key;

    do {
      values = switch (_random.nextInt(6)) {
        0 => _addition(),
        1 => _subtraction(),
        2 => _multiplication(),
        3 => _division(),
        4 => _addSubtractChain(),
        _ => _multiplyAddChain(),
      };
      key = values.join();
    } while (key == _lastExpressionKey);

    _lastExpressionKey = key;
    return _MotionExpression(values);
  }

  List<String> _addition() {
    final left = _random.nextInt(12) + 1;
    final right = _random.nextInt(9) + 1;
    return ['$left', '+', '$right', '=', '${left + right}'];
  }

  List<String> _subtraction() {
    final left = _random.nextInt(20) + 5;
    final right = _random.nextInt(left - 1) + 1;
    return ['$left', '−', '$right', '=', '${left - right}'];
  }

  List<String> _multiplication() {
    final left = _random.nextInt(8) + 2;
    final right = _random.nextInt(8) + 2;
    return ['$left', '×', '$right', '=', '${left * right}'];
  }

  List<String> _division() {
    final divisor = _random.nextInt(8) + 2;
    final result = _random.nextInt(8) + 2;
    return ['${divisor * result}', '÷', '$divisor', '=', '$result'];
  }

  List<String> _addSubtractChain() {
    final first = _random.nextInt(9) + 1;
    final second = _random.nextInt(9) + 1;
    final third = _random.nextInt(first + second - 1) + 1;
    return [
      '$first',
      '+',
      '$second',
      '−',
      '$third',
      '=',
      '${first + second - third}',
    ];
  }

  List<String> _multiplyAddChain() {
    final first = _random.nextInt(5) + 2;
    final second = _random.nextInt(5) + 2;
    final third = _random.nextInt(9) + 1;
    return [
      '$first',
      '×',
      '$second',
      '+',
      '$third',
      '=',
      '${first * second + third}',
    ];
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
        ..value = 0;
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
              final slide = Curves.easeInOutCubic.transform(
                ((_controller.value - 0.48) / 0.52).clamp(0.0, 1.0),
              );

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.hardEdge,
                children: [
                  _MotionSceneView(
                    scene: _currentScene,
                    reveal: 1,
                    offset: Offset(0, 72 * slide),
                  ),
                  _MotionSceneView(
                    scene: _nextScene,
                    reveal: 1,
                    offset: Offset(0, -72 * (1 - slide)),
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

class _MotionScene {
  const _MotionScene.expression(this.expression) : isWordmark = false;
  const _MotionScene.wordmark()
      : expression = null,
        isWordmark = true;

  final _MotionExpression? expression;
  final bool isWordmark;
}

class _MotionSceneView extends StatelessWidget {
  const _MotionSceneView({
    required this.scene,
    required this.reveal,
    required this.offset,
  });

  final _MotionScene scene;
  final double reveal;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: scene.isWordmark
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'NUMBERING',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                ),
              ),
            )
          : _MotionEquation(
              values: scene.expression!.values,
              reveal: reveal,
            ),
    );
  }
}

class _MotionExpression {
  const _MotionExpression(this.values);

  final List<String> values;
}

class _MotionEquation extends StatelessWidget {
  const _MotionEquation({required this.values, required this.reveal});

  final List<String> values;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(values.length, (index) {
        final delay = index * 0.035;
        final pieceReveal = Curves.easeOutCubic.transform(
          ((reveal - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        final isDigit = index.isEven;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isDigit ? 4 : 2),
          child: Opacity(
            opacity: pieceReveal,
            child: Transform.translate(
              offset: Offset(0, (1 - pieceReveal) * 5),
              child: _MotionTile(
                value: values[index],
                isOperator: !isDigit,
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
      width: isOperator ? 24 : 42,
      height: isOperator ? 40 : 56,
      child: Center(
        child: Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary,
            fontSize: isOperator ? 21 : 28,
            height: 1,
            fontWeight: isOperator ? FontWeight.w500 : FontWeight.w700,
            letterSpacing: isOperator ? 0 : -0.4,
          ),
        ),
      ),
    );
  }
}
