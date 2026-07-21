import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:numbering/theme/app_colors.dart';

/// A quiet honeycomb texture shared by the app backgrounds.
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const radius = 25.0;
    final horizontalStep = math.sqrt(3) * radius * 2.7;
    const verticalStep = radius * 2.35;
    final linePaint = Paint()
      ..color = AppColors.hexPatternColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    var row = 0;
    for (double y = -radius; y < size.height + radius; y += verticalStep) {
      final offsetX = row.isOdd ? horizontalStep / 2 : 0.0;
      for (double x = -radius + offsetX;
          x < size.width + radius;
          x += horizontalStep) {
        canvas.drawPath(_hexPath(Offset(x, y), radius), linePaint);
      }
      row++;
    }

    final accentPaint = Paint()
      ..color = AppColors.honeyAccent.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_hexPath(const Offset(34, 74), 28), accentPaint);
    canvas.drawPath(
      _hexPath(Offset(size.width - 26, size.height - 70), 34),
      accentPaint,
    );
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index++) {
      final angle = -math.pi / 2 + index * math.pi / 3;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
