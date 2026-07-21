import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/services/settings_service.dart';

import 'settings_rows.dart';
import 'settings_surface.dart';
import '../dialogs/language_picker_dialog.dart';

class SettingsProfileSection extends StatelessWidget {
  const SettingsProfileSection({
    super.key,
    required this.email,
    required this.nickname,
    required this.onEditNickname,
  });

  final String email;
  final String nickname;
  final VoidCallback onEditNickname;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionLabel('프로필'.tr),
        SettingsCard(
          child: Column(
            children: [
              SettingsInfoRow(
                icon: Icons.email_outlined,
                title: '이메일'.tr,
                value: email,
              ),
              const SettingsDivider(),
              SettingsTapRow(
                icon: Icons.badge_outlined,
                title: '닉네임'.tr,
                value: nickname,
                showEditIcon: true,
                onTap: onEditNickname,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsGeneralSection extends StatelessWidget {
  const SettingsGeneralSection({
    super.key,
    required this.settingsService,
    required this.onShowTutorial,
    required this.onContact,
  });

  final SettingsService settingsService;
  final VoidCallback onShowTutorial;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionLabel('일반'.tr),
        SettingsCard(
          child: Column(
            children: [
              Obx(() {
                return SettingsSwitchRow(
                  icon: Icons.music_note_rounded,
                  title: '배경음악'.tr,
                  value: settingsService.isBgmOn.value,
                  onChanged: (_) => settingsService.toggleBgm(),
                );
              }),
              const SettingsDivider(),
              Obx(() {
                return SettingsSwitchRow(
                  icon: Icons.graphic_eq_rounded,
                  title: '효과음'.tr,
                  value: settingsService.isSfxOn.value,
                  onChanged: (_) => settingsService.toggleSfx(),
                );
              }),
              const SettingsDivider(),
              Obx(() {
                return SettingsSwitchRow(
                  icon: Icons.vibration_rounded,
                  title: '진동 피드백'.tr,
                  value: settingsService.isHapticsOn.value,
                  onChanged: (_) => settingsService.toggleHaptics(),
                );
              }),
              const SettingsDivider(),
              Obx(() {
                final locale = settingsService.locale.value;
                final localeKey =
                    '${locale.languageCode}_${locale.countryCode}';
                return SettingsTapRow(
                  icon: Icons.language_rounded,
                  title: '언어'.tr,
                  value: SettingsService.localeNames[localeKey] ?? localeKey,
                  onTap: () {
                    Get.dialog(const LanguagePickerDialog());
                  },
                );
              }),
              const SettingsDivider(),
              SettingsTapRow(
                icon: Icons.help_outline_rounded,
                title: '게임 방법'.tr,
                onTap: onShowTutorial,
              ),
              const SettingsDivider(),
              SettingsTapRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: '문의하기'.tr,
                onTap: onContact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({
    super.key,
    required this.isLoggedIn,
    required this.onLogout,
    required this.onLogin,
  });

  final bool isLoggedIn;
  final VoidCallback onLogout;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionLabel('계정'.tr),
        if (isLoggedIn)
          SettingsCard(
            child: SettingsTapRow(
              icon: Icons.logout_rounded,
              title: '로그아웃'.tr,
              onTap: onLogout,
            ),
          )
        else
          SettingsCard(
            child: SettingsTapRow(
              icon: Icons.login_rounded,
              title: '로그인'.tr,
              onTap: onLogin,
            ),
          ),
      ],
    );
  }
}
