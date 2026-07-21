import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/theme/app_colors.dart';
import 'package:hexor/widgets/common/soft_icon_button.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          SoftIconButton(
            icon: Icons.arrow_back_rounded,
            label: '뒤로 가기',
            onPressed: Get.back,
            size: 48,
          ),
          Expanded(
            child: Text(
              'SETTINGS'.tr,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(
                fontSize: 22,
                letterSpacing: 2.0,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
