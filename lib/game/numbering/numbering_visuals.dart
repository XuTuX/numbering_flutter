import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'numbering_models.dart';

@immutable
class NumberingVisuals {
  const NumberingVisuals({
    required this.icon,
    required this.accent,
    required this.accentSoft,
  });

  final IconData icon;
  final Color accent;
  final Color accentSoft;
}

extension NumberingGameVisuals on NumberingGame {
  NumberingVisuals get visuals => switch (this) {
        NumberingGame.formulaWorkshop => const NumberingVisuals(
            icon: Icons.calculate_rounded,
            accent: AppColors.blue,
            accentSoft: Color(0xFFE5F4FF),
          ),
        NumberingGame.sequenceDetective => const NumberingVisuals(
            icon: Icons.manage_search_rounded,
            accent: AppColors.purple,
            accentSoft: Color(0xFFF2E8FF),
          ),
        NumberingGame.numberVault => const NumberingVisuals(
            icon: Icons.lock_rounded,
            accent: AppColors.scoreOrange,
            accentSoft: Color(0xFFFFEFE5),
          ),
      };
}
