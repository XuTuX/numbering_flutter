import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/level_catalog.dart';

void main() {
  test('migration contains one authoritative rule for every app level', () {
    final sql = File(
      'supabase/migrations/20260722200417_add_numbering_rankings.sql',
    ).readAsStringSync();
    final generatedBlock = sql
        .split('-- LEVEL_RULE_VALUES_START')[1]
        .split('-- LEVEL_RULE_VALUES_END')[0];
    final rowCount =
        RegExp(r'^  \(\d+,', multiLine: true).allMatches(generatedBlock).length;

    expect(LevelCatalog.all, hasLength(160));
    expect(rowCount, LevelCatalog.all.length);
    for (final level in LevelCatalog.all) {
      expect(
        generatedBlock,
        contains("(${level.id}, '${level.digitString}',"),
      );
    }
  });
}
