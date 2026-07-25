import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/widgets/common/soft_icon_button.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    this.isWide = false,
    this.isCompactLandscape = false,
  });

  final bool isWide;
  final bool isCompactLandscape;

  @override
  Widget build(BuildContext context) {
    final topPadding = isCompactLandscape ? 0.0 : (isWide ? 4.0 : 12.0);
    final bottomPadding = isCompactLandscape ? 12.0 : (isWide ? 24.0 : 16.0);
    final buttonSize = isCompactLandscape ? 42.0 : (isWide ? 48.0 : 44.0);
    final iconSize = isCompactLandscape ? 22.0 : (isWide ? 24.0 : 22.0);

    return Padding(
      padding: isWide
          ? EdgeInsets.fromLTRB(0, topPadding, 0, bottomPadding)
          : EdgeInsets.fromLTRB(20, topPadding, 20, bottomPadding),
      child: Row(
        children: [
          SoftIconButton(
            icon: Icons.arrow_back_rounded,
            label: '뒤로 가기',
            onPressed: Get.back,
            size: buttonSize,
            iconSize: iconSize,
          ),
          if (isWide) ...[
            const SizedBox(width: 14),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'SETTINGS'.tr,
                  maxLines: 1,
                  style: AppTypography.title.copyWith(
                    fontSize: isCompactLandscape ? 20 : 23,
                    letterSpacing: 2.0,
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
                  fontSize: 20,
                  letterSpacing: 2.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: buttonSize),
          ],
        ],
      ),
    );
  }
}
