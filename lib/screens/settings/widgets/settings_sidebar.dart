import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';
import 'package:numbering/theme/app_typography.dart';

enum SettingsSection { profile, general, account }

class SettingsSidebar extends StatelessWidget {
  const SettingsSidebar({
    super.key,
    required this.selectedSection,
    required this.showProfile,
    required this.onSectionSelected,
    this.isCompactLandscape = false,
  });

  final SettingsSection selectedSection;
  final bool showProfile;
  final ValueChanged<SettingsSection> onSectionSelected;
  final bool isCompactLandscape;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '설정 메뉴',
      child: Column(
        key: const ValueKey('settings-side-navigation'),
        children: [
          if (showProfile)
            _SettingsSidebarItem(
              label: '프로필'.tr,
              isSelected: selectedSection == SettingsSection.profile,
              isCompactLandscape: isCompactLandscape,
              onTap: () => onSectionSelected(SettingsSection.profile),
            ),
          _SettingsSidebarItem(
            label: '일반'.tr,
            isSelected: selectedSection == SettingsSection.general,
            isCompactLandscape: isCompactLandscape,
            onTap: () => onSectionSelected(SettingsSection.general),
          ),
          _SettingsSidebarItem(
            label: '계정'.tr,
            isSelected: selectedSection == SettingsSection.account,
            isCompactLandscape: isCompactLandscape,
            onTap: () => onSectionSelected(SettingsSection.account),
          ),
        ],
      ),
    );
  }
}

class _SettingsSidebarItem extends StatelessWidget {
  const _SettingsSidebarItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCompactLandscape = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompactLandscape;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isCompactLandscape ? 4 : 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isSelected ? AppColors.hairline : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Container(
              height: isCompactLandscape ? 42 : 48,
              padding: EdgeInsets.symmetric(
                horizontal: isCompactLandscape ? 14 : 18,
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  fontSize: isCompactLandscape ? 14 : 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.ink : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
