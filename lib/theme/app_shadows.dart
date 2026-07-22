import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  // App chrome and content surfaces are separated by borders, not elevation.
  static const smallShadow = <BoxShadow>[];
  static const cardShadow = <BoxShadow>[];
  static const buttonShadow = <BoxShadow>[];

  // Gameplay pieces may retain light depth as functional feedback.
  static const tileShadow = <BoxShadow>[
    BoxShadow(
        color: AppColors.shadowLight, blurRadius: 9, offset: Offset(0, 4)),
  ];
}
