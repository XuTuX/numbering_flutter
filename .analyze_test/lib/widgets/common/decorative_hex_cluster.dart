import 'dart:math' as math;

import 'package:flutter/material.dart';

class DecorativeHexCluster extends StatelessWidget {
  const DecorativeHexCluster({
    super.key,
    required this.color,
    this.opacity = 0.12,
    this.size = 64,
    this.count = 4,
  });

  final Color color;
  final double opacity;
  final double size;
  final int count;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _HexClusterPainter(
            color: color.withValues(alpha: opacity.clamp(0, 1)),
            count: count.clamp(1, 5),
          ),
        ),
      ),
    );
  }
}

class _HexClusterPainter extends CustomPainter {
  const _HexClusterPainter({required this.color, required this.count});

  final Color color;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final anchors = <Offset>[
      Offset(size.width * 0.66, size.height * 0.68),
      Offset(size.width * 0.31, size.height * 0.72),
      Offset(size.width * 0.82, size.height * 0.30),
      Offset(size.width * 0.48, size.height * 0.27),
      Offset(size.width * 0.14, size.height * 0.30),
    ];
    final radii = <double>[0.22, 0.16, 0.14, 0.11, 0.09];
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var index = 0; index < count; index++) {
      canvas.drawPath(
        _hexPath(anchors[index], size.shortestSide * radii[index]),
        paint,
      );
    }
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _HexClusterPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.count != count;
}
