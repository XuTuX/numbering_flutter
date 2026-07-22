import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/theme/app_typography.dart';

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 18,
        vertical: isWide ? 19 : 14,
      ),
      child: Row(
        children: [
          Icon(icon, size: 25, color: charcoalBlack.withValues(alpha: 0.56)),
          SizedBox(width: isWide ? 18 : 14),
          Expanded(
            child: Text(
              title.tr,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: charcoalBlack,
              activeThumbColor: Colors.white,
              inactiveTrackColor: charcoalBlack.withValues(alpha: 0.1),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsInfoRow extends StatelessWidget {
  const SettingsInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 18,
        vertical: isWide ? 21 : 16,
      ),
      child: Row(
        children: [
          Icon(icon, size: 25, color: charcoalBlack.withValues(alpha: 0.56)),
          SizedBox(width: isWide ? 18 : 14),
          Text(
            title.tr,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: charcoalBlack.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTapRow extends StatelessWidget {
  const SettingsTapRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.showEditIcon = false,
    this.titleColor = charcoalBlack,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final bool showEditIcon;
  final Color titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 24 : 18,
            vertical: isWide ? 20 : 16,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 25,
                color: charcoalBlack.withValues(alpha: 0.56),
              ),
              SizedBox(width: isWide ? 18 : 14),
              Expanded(
                child: Text(
                  title.tr,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ),
              if (value != null) ...[
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                showEditIcon
                    ? Icons.edit_outlined
                    : Icons.chevron_right_rounded,
                size: 20,
                color: charcoalBlack.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
