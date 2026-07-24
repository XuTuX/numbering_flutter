import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('moves existing London and Paris progress after inserted Sydney pack',
      () async {
    SharedPreferences.setMockInitialValues({
      'numbering_last_level_v1': 81,
      'numbering_level_progress_v1': jsonEncode({
        for (var id = 1; id <= 80; id++)
          '$id': {
            'levelId': id,
            'cleared': true,
            'bestScore': 8,
            'stars': 3,
            'perfect': false,
            'usedHints': 0,
          },
        '81': {
          'levelId': 81,
          'cleared': true,
          'bestScore': 11,
          'stars': 3,
          'perfect': false,
          'usedHints': 0,
        },
        '160': {
          'levelId': 160,
          'cleared': true,
          'bestScore': 21,
          'stars': 3,
          'perfect': true,
          'usedHints': 0,
        },
      }),
    });

    final firstLoad = await LevelProgressService().init();
    expect(firstLoad.progress[80]?.cleared, isTrue);
    expect(firstLoad.progress[81], isNull);
    expect(firstLoad.progress[121]?.bestScore, 11);
    expect(firstLoad.progress[200]?.perfect, isTrue);
    expect(firstLoad.lastPlayedLevel.value, 121);
    expect(firstLoad.highestUnlockedLevel, 81);

    final secondLoad = await LevelProgressService().init();
    expect(secondLoad.progress[121]?.bestScore, 11);
    expect(secondLoad.progress[161], isNull);
    expect(secondLoad.lastPlayedLevel.value, 121);
  });
}
