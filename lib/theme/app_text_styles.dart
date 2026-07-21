import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const cardLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );
  static const scoreValue = TextStyle(
    color: AppColors.scoreOrange,
    fontSize: 28,
    height: 1,
    fontWeight: FontWeight.w800,
  );
  static const timeValue = TextStyle(
    color: AppColors.timeBlue,
    fontSize: 28,
    height: 1,
    fontWeight: FontWeight.w800,
  );
  static const comboLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
  static const comboValue = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 11,
    height: 1,
    fontWeight: FontWeight.w800,
  );
  static const buttonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const dialogTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const dialogBody = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );
}
