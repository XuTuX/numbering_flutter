import 'package:flutter/material.dart';
import 'package:numbering/theme/app_colors.dart';

/// Unified typography system for NUMBERING and the shared app shell.
///
/// Shared typography for the active NUMBERING screens.
class AppTypography {
  AppTypography._(); // prevent instantiation

  // ─── Titles ────────────────────────────────────────────
  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.ink,
  );

  // ─── Body ──────────────────────────────────────────────
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.ink,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.ink,
  );

  // ─── Buttons ───────────────────────────────────────────
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
    color: AppColors.ink,
  );

  // ─── Small ─────────────────────────────────────────────
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
}
