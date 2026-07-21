import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF8F9FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFF3F5F7);
  static const textPrimary = Color(0xFF4A4A4A);
  static const textSecondary = Color(0xFF777777);
  static const scoreOrange = Color(0xFFFF6A00);
  static const timeBlue = Color(0xFF1769E8);
  static const green = Color(0xFF00D47C);
  static const red = Color(0xFFFF4D4D);
  static const yellow = Color(0xFFFFB300);
  static const blue = Color(0xFF0095FF);
  static const purple = Color(0xFF8F00FF);
  static const borderLight = Color(0xFFE8EAEE);
  static const shadowLight = Color(0x1F64748B);
  static const shadowFaint = Color(0x1464748B);
  static const hexPatternColor = Color(0xFFEFF1F4);
  static const honeyAccent = Color(0xFFFFE7A1);
  static const blueAccentSoft = Color(0xFFDDEBFF);
  static const danger = Color(0xFFEF5350);

  static Color darken(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color lighten(Color color, [double amount = 0.12]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
