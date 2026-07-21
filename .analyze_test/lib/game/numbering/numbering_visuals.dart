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
      };
}
