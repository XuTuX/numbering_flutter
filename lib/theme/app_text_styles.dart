import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const hero = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 36,
    height: 1.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.6,
  );
  static const screenTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );
  static const cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );
  static const labelSmall = TextStyle(
    color: Color(0x8F171716),
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );
  static const buttonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const dialogBody = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );
}
