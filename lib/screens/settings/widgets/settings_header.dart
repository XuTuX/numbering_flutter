import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/widgets/common/soft_icon_button.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    this.isWide = false,
  });

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isWide
          ? const EdgeInsets.fromLTRB(0, 4, 0, 32)
          : const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          SoftIconButton(
            icon: Icons.arrow_back_rounded,
            label: '뒤로 가기',
            onPressed: Get.back,
            size: isWide ? 52 : 46,
            iconSize: isWide ? 27 : 24,
          ),
          if (isWide) ...[
            const SizedBox(width: 20),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'SETTINGS'.tr,
                  maxLines: 1,
                  style: AppTypography.title.copyWith(
                    fontSize: 25,
                    letterSpacing: 2.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                'SETTINGS'.tr,
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(
                  fontSize: 21,
                  letterSpacing: 2.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 46),
          ],
        ],
      ),
    );
  }
}
