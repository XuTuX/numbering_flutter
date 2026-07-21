import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_service.dart';

class SettingsService extends GetxService {
  final RxBool isHapticsOn = true.obs;
  final RxBool isBgmOn = true.obs;
  final RxBool isSfxOn = true.obs;
  final RxBool hasCompletedTutorial = false.obs;
  final Rx<Locale> locale = const Locale('ko', 'KR').obs;

  static const String _hapticsKey = 'haptics_enabled';
  static const String _bgmKey = 'bgm_enabled';
  static const String _sfxKey = 'sfx_enabled';
  static const String _tutorialKey = 'tutorial_completed';
  static const String _localeKey = 'app_locale';

  static const List<Locale> supportedLocales = [
    Locale('ko', 'KR'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
    Locale('zh', 'CN'),
    Locale('hi', 'IN'),
  ];

  static const Map<String, String> localeNames = {
    'ko_KR': '한국어',
    'en_US': 'English',
    'ja_JP': '日本語',
    'zh_CN': '中文',
    'hi_IN': 'हिन्दी',
  };

  Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isHapticsOn.value = prefs.getBool(_hapticsKey) ?? true;
    isBgmOn.value = prefs.getBool(_bgmKey) ?? true;
    isSfxOn.value = prefs.getBool(_sfxKey) ?? true;
    hasCompletedTutorial.value = prefs.getBool(_tutorialKey) ?? false;

    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      final parts = savedLocale.split('_');
      if (parts.length == 2) {
        locale.value = Locale(parts[0], parts[1]);
      }
    }
    return this;
  }

  Future<void> toggleHaptics() async {
    isHapticsOn.value = !isHapticsOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, isHapticsOn.value);
  }

  Future<void> toggleBgm() async {
    isBgmOn.value = !isBgmOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgmKey, isBgmOn.value);
    await AudioService().setBgmEnabled(isBgmOn.value);
  }

  Future<void> toggleSfx() async {
    isSfxOn.value = !isSfxOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, isSfxOn.value);
    await AudioService().setSfxEnabled(isSfxOn.value);
  }

  Future<void> setAudioEnabled(bool enabled) async {
    isBgmOn.value = enabled;
    isSfxOn.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_bgmKey, enabled),
      prefs.setBool(_sfxKey, enabled),
      AudioService().setBgmEnabled(enabled),
      AudioService().setSfxEnabled(enabled),
    ]);
  }

  Future<void> completeTutorial() async {
    hasCompletedTutorial.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }

  Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    Get.updateLocale(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _localeKey, '${newLocale.languageCode}_${newLocale.countryCode}');
  }
}
