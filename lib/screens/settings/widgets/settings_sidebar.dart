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
  });

  final SettingsSection selectedSection;
  final bool showProfile;
  final ValueChanged<SettingsSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '설정 메뉴',
      child: Column(
        key: const ValueKey('settings-side-navigation'),
        children: [
          if (showProfile)
            _SettingsSidebarItem(
              icon: Icons.person_outline_rounded,
              label: '프로필'.tr,
              isSelected: selectedSection == SettingsSection.profile,
              onTap: () => onSectionSelected(SettingsSection.profile),
            ),
          _SettingsSidebarItem(
            icon: Icons.tune_rounded,
            label: '일반'.tr,
            isSelected: selectedSection == SettingsSection.general,
            onTap: () => onSectionSelected(SettingsSection.general),
          ),
          _SettingsSidebarItem(
            icon: Icons.manage_accounts_outlined,
            label: '계정'.tr,
            isSelected: selectedSection == SettingsSection.account,
            onTap: () => onSectionSelected(SettingsSection.account),
          ),
        ],
      ),
    );
  }
}

class _SettingsSidebarItem extends StatelessWidget {
  const _SettingsSidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? AppColors.surfaceSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 25,
                  color: isSelected ? AppColors.ink : AppColors.textSecondary,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: AppTypography.body.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.ink : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
