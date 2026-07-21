import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/services/settings_service.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/theme/app_colors.dart';
import 'package:hexor/theme/app_radius.dart';
import 'package:hexor/theme/app_shadows.dart';

class LanguagePickerDialog extends StatelessWidget {
  const LanguagePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();
    final currentLocale = settingsService.locale.value;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '언어 설정'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 20),
              ...SettingsService.supportedLocales.map((locale) {
                final localeKey =
                    '${locale.languageCode}_${locale.countryCode}';
                final isSelected = locale == currentLocale;
                final localeName =
                    SettingsService.localeNames[localeKey] ?? localeKey;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      settingsService.setLocale(locale);
                      Get.back();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blueAccentSoft.withValues(alpha: 0.55)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              localeName,
                              style: AppTypography.body.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: AppColors.timeBlue,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: Get.back,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '취소'.tr,
                      style: AppTypography.button.copyWith(fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
