import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_typography.dart';

class _SettingIconBadge extends StatelessWidget {
  const _SettingIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 19,
        color: AppColors.ink,
      ),
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData? icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 20 : 16,
        vertical: isWide ? 14 : 10,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            _SettingIconBadge(icon: icon!),
            SizedBox(width: isWide ? 16 : 12),
          ],
          Expanded(
            child: Text(
              title.tr,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.ink,
              activeThumbColor: Colors.white,
              inactiveTrackColor: AppColors.hairline,
              inactiveThumbColor: AppColors.textSecondary,
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
    this.icon,
    required this.title,
    required this.value,
  });

  final IconData? icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 20 : 16,
        vertical: isWide ? 14 : 10,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            _SettingIconBadge(icon: icon!),
            SizedBox(width: isWide ? 16 : 12),
          ],
          Text(
            title.tr,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
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
    this.icon,
    required this.title,
    this.value,
    this.showEditIcon = false,
    this.titleColor = AppColors.ink,
    required this.onTap,
  });

  final IconData? icon;
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
        splashColor: AppColors.hairlineSoft,
        highlightColor: AppColors.hairlineSoft,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 20 : 16,
            vertical: isWide ? 14 : 10,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                _SettingIconBadge(icon: icon!),
                SizedBox(width: isWide ? 16 : 12),
              ],
              Expanded(
                child: Text(
                  title.tr,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                showEditIcon
                    ? Icons.edit_outlined
                    : Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
