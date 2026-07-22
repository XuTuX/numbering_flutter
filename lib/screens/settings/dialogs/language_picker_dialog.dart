import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/services/settings_service.dart';
import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';
import 'package:numbering/theme/app_shadows.dart';

class LanguagePickerDialog extends StatelessWidget {
  const LanguagePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();
    final currentLocale = settingsService.locale.value;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 440,
          maxHeight: 340, // Constrain height in landscape to prevent overflow
        ),
        decoration: BoxDecoration(
          color: AppColors.canvas,
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
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: SettingsService.supportedLocales.map((locale) {
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
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.surfaceSoft
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.hairline
                                    : Colors.transparent,
                                width: 1.0,
                              ),
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
                                          ? AppColors.ink
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 20,
                                    color: AppColors.ink,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: Get.back,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.hairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    '취소'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
