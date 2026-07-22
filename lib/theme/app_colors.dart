import 'package:flutter/material.dart';

abstract final class AppColors {
  // Figma Core Monochrome
  static const primary = Color(0xFF000000);
  static const onPrimary = Color(0xFFFFFFFF);
  static const ink = Color(0xFF000000);
  static const inverseInk = Color(0xFFFFFFFF);
  
  // Surfaces
  static const canvas = Color(0xFFFFFFFF);
  static const inverseCanvas = Color(0xFF000000);
  static const surfaceSoft = Color(0xFFF7F7F5);
  static const hairline = Color(0xFFE6E6E6);
  static const hairlineSoft = Color(0xFFF1F1F1);
  
  // Figma Pastel Color Blocks
  static const blockLime = Color(0xFFDCEEB1);
  static const blockLilac = Color(0xFFC5B0F4);
  static const blockCream = Color(0xFFF4ECD6);
  static const blockPink = Color(0xFFEFD4D4);
  static const blockMint = Color(0xFFC8E6CD);
  static const blockCoral = Color(0xFFF3C9B6);
  static const blockNavy = Color(0xFF1F1D3D);
  static const accentMagenta = Color(0xFFFF3D8B);

  // Fallbacks for existing code
  static const background = canvas;
  static const surface = canvas;
  static const surfaceSecondary = surfaceSoft;
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF7A7A7A);
  static const borderLight = hairline;
  static const shadowLight = Color(0x1F000000);
  static const shadowFaint = Color(0x0A000000);
  
  // Legacy
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
