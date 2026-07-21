import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static const smallShadow = <BoxShadow>[
    BoxShadow(
        color: AppColors.shadowFaint, blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const cardShadow = <BoxShadow>[
    BoxShadow(
        color: AppColors.shadowFaint, blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(
        color: AppColors.shadowFaint, blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const buttonShadow = <BoxShadow>[
    BoxShadow(
        color: AppColors.shadowLight, blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const tileShadow = <BoxShadow>[
    BoxShadow(
        color: AppColors.shadowLight, blurRadius: 9, offset: Offset(0, 4)),
  ];
}
