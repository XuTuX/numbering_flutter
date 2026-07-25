// Regenerates the Numbering level-rule values block that the server uses to
// re-score submissions, so `private.numbering_level_rules` can never drift away
// from `LevelCatalog`.
//
// Run it after any change to lib/game/numbering/level_catalog.dart:
//
//   flutter test tool/generate_numbering_level_rules.dart
//
// It rewrites everything between the LEVEL_RULE_VALUES_START/END markers of
// [_targetMigration]. It is a test only so that it can import Flutter-backed
// catalog code; it asserts nothing about gameplay.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/game/numbering/level_catalog.dart';
import 'package:numbering/game/numbering/level_models.dart';

const _targetMigration =
    'supabase/migrations/20260726120000_sync_numbering_level_rules.sql';

const _startMarker = '-- LEVEL_RULE_VALUES_START';
const _endMarker = '-- LEVEL_RULE_VALUES_END';

/// `=` is a structural token, not an operator the server validates against.
const _structuralTokens = {'='};

void main() {
  test('every catalog level clears its own official answer', () {
    // The server re-scores submissions against the rules this tool emits, so a
    // level whose own answer does not clear its minimum would be unwinnable
    // once the rules are synced.
    for (final level in LevelCatalog.all) {
      final result = validateLevelFormula(
        digitString: level.digitString,
        expression: level.officialAnswer,
        availableOperators: level.availableOperators,
      );
      expect(
        result.valid,
        isTrue,
        reason: 'Level ${level.id} (${level.officialAnswer}): ${result.message}',
      );
      expect(
        result.value,
        greaterThanOrEqualTo(level.minimumScore),
        reason: 'Level ${level.id} scores below its own minimum',
      );
    }
  });

  test('numbering level rules migration matches LevelCatalog', () {
    final file = File(_targetMigration);
    if (!file.existsSync()) {
      fail('Migration not found: $_targetMigration');
    }

    final source = file.readAsStringSync();
    final start = source.indexOf(_startMarker);
    final end = source.indexOf(_endMarker);
    if (start < 0 || end < 0 || end < start) {
      fail('Missing $_startMarker / $_endMarker markers in $_targetMigration');
    }

    final updated = source.replaceRange(
      start,
      end + _endMarker.length,
      _buildValuesBlock(LevelCatalog.all),
    );
    if (updated != source) {
      file.writeAsStringSync(updated);
      // ignore: avoid_print
      print('Rewrote ${LevelCatalog.all.length} level rules in '
          '$_targetMigration');
    } else {
      // ignore: avoid_print
      print('$_targetMigration already matches LevelCatalog');
    }
  });
}

String _buildValuesBlock(List<LevelData> levels) {
  final rows = <String>[];
  for (final level in levels) {
    final operators = level.availableOperators
        .where((operator) => !_structuralTokens.contains(operator))
        .toList()
      ..sort();
    final operatorLiteral =
        operators.map((operator) => "'$operator'").join(', ');
    rows.add(
      "  (${level.id}, '${level.digitString}', "
      'array[$operatorLiteral]::text[], '
      '${level.minimumScore}, ${level.targetScore}, ${level.difficulty})',
    );
  }

  return '''
$_startMarker
-- Generated from lib/game/numbering/level_catalog.dart. Do not edit by hand.
-- Regenerate with: flutter test tool/generate_numbering_level_rules.dart
insert into private.numbering_level_rules (
  level_id, digit_string, available_operators,
  minimum_score, target_score, difficulty
)
values
${rows.join(',\n')}
on conflict (level_id) do update
set digit_string = excluded.digit_string,
    available_operators = excluded.available_operators,
    minimum_score = excluded.minimum_score,
    target_score = excluded.target_score,
    difficulty = excluded.difficulty,
    updated_at = now();
$_endMarker''';
}
