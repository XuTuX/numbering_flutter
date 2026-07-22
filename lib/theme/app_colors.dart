import 'package:flutter/material.dart';

abstract final class AppColors {
  // Quiet minimal core
  static const primary = Color(0xFF171716);
  static const onPrimary = Color(0xFFFFFFFF);
  static const ink = Color(0xFF171716);
  static const inverseInk = Color(0xFFFFFFFF);

  // Surfaces
  static const canvas = Color(0xFFFFFFFF);
  static const inverseCanvas = Color(0xFF000000);
  static const background = Color(0xFFFAF9F6);
  static const surfaceSoft = Color(0xFFF1F0EB);
  static const hairline = Color(0x1A171716);
  static const hairlineSoft = Color(0x0D171716);

  // Low-saturation pastel blocks. Use one dominant tint per card.
  static const blockLime = Color(0xFFEDF1E3);
  static const blockLilac = Color(0xFFEDE9F5);
  static const blockCream = Color(0xFFF2ECE2);
  static const blockPink = Color(0xFFF3E9E7);
  static const blockMint = Color(0xFFE8EFE8);
  static const blockCoral = Color(0xFFF2E8E2);
  static const blockNavy = Color(0xFF1F1D3D);
  static const accentMagenta = Color(0xFFFF3D8B);

  // Semantic aliases
  static const surface = canvas;
  static const surfaceSecondary = surfaceSoft;
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF777570);
  static const borderLight = hairline;
  static const shadowLight = Color(0x12171716);
  static const shadowFaint = Color(0x08171716);

  // Functional gameplay colors. Do not use as decorative UI fills.
  static const scoreOrange = Color(0xFFFF6A00);
  static const timeBlue = Color(0xFF0066CC);
  static const green = Color(0xFF00D47C);
  static const red = Color(0xFFFF4D4D);
  static const danger = Color(0xFFFF4D4D);
  static const yellow = Color(0xFFFFB300);
  static const blue = Color(0xFF0066CC);
  static const blueAccentSoft = Color(0xFFE0E7FF);
  static const purple = Color(0xFF8F00FF);

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
