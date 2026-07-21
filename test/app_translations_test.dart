import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexor/l10n/app_translations.dart';

void main() {
  final translations = AppTranslations().keys;

  test('every supported locale has the complete non-empty key set', () {
    final englishKeys = translations['en_US']!.keys.toSet();
    const intentionallyBlankKeys = {'위'};

    for (final locale in ['ko_KR', 'ja_JP', 'zh_CN', 'hi_IN']) {
      final values = translations[locale]!;
      expect(values.keys.toSet(), englishKeys, reason: '$locale key mismatch');
      expect(
        values.entries.where(
          (entry) =>
              entry.value.trim().isEmpty &&
              !intentionallyBlankKeys.contains(entry.key),
        ),
        isEmpty,
        reason: '$locale contains a blank translation',
      );
    }
  });

  test('every literal tr lookup in lib has a translation key', () {
    final knownKeys = translations['en_US']!.keys.toSet();
    final missingKeys = <String>{};
    final lookupPattern = RegExp(r"'((?:\\.|[^'])*)'\.tr\b");

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final source = entity.readAsStringSync();
      for (final match in lookupPattern.allMatches(source)) {
        final key = match
            .group(1)!
            .replaceAll(r'\n', '\n')
            .replaceAll(r"\'", "'")
            .replaceAll(r'\\', r'\');
        if (!knownKeys.contains(key)) missingKeys.add(key);
      }
    }

    expect(missingKeys, isEmpty, reason: 'Missing translation keys');
  });

  test('game HUD and result copy is localized in every non-Korean locale', () {
    const gameKeys = {
      '오늘의 퍼즐',
      '점수',
      '시간',
      '다시 시작하기',
      '게임 나가기',
      '최종 점수',
      '최고 기록',
      '최고 콤보',
      '매치 수',
      '홈',
      '랭킹',
      '리플레이',
      '공유하기',
    };
    final english = translations['en_US']!;

    for (final locale in ['ja_JP', 'zh_CN', 'hi_IN']) {
      final localized = translations[locale]!;
      for (final key in gameKeys) {
        expect(
          localized[key],
          isNot(english[key]),
          reason: '$locale still falls back to English for "$key"',
        );
      }
    }
  });
}
