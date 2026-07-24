import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/level_catalog.dart';

const _startMarker = '-- LEVEL_RULE_VALUES_START';
const _endMarker = '-- LEVEL_RULE_VALUES_END';

void main() {
  test('generates migration level rules from LevelCatalog', () {
    _generate(
      File(
        'supabase/migrations/'
        '20260724181919_remove_numbering_division.sql',
      ),
    );
  });
}

void _generate(File file) {
  final source = file.readAsStringSync();
  final start = source.indexOf(_startMarker);
  final end = source.indexOf(_endMarker);
  if (start < 0 || end <= start) {
    stderr.writeln('Level rule markers were not found.');
    fail('Level rule markers were not found.');
  }

  final rows = LevelCatalog.all.map((level) {
    final operators = level.availableOperators
        .where((operator) => operator != '=')
        .toList(growable: false)
      ..sort();
    final operatorSql =
        operators.map((value) => "'${_escape(value)}'").join(', ');
    return "  (${level.id}, '${level.digitString}', array[$operatorSql]::text[], "
        '${level.minimumScore}, ${level.targetScore}, ${level.difficulty})';
  }).join(',\n');

  final generated = '''$_startMarker
-- Generated from lib/game/numbering/level_catalog.dart. Do not edit by hand.
insert into private.numbering_level_rules (
  level_id, digit_string, available_operators,
  minimum_score, target_score, difficulty
)
values
$rows
on conflict (level_id) do update
set digit_string = excluded.digit_string,
    available_operators = excluded.available_operators,
    minimum_score = excluded.minimum_score,
    target_score = excluded.target_score,
    difficulty = excluded.difficulty,
    updated_at = now();
$_endMarker''';

  file.writeAsStringSync(
    source.replaceRange(start, end + _endMarker.length, generated),
  );
}

String _escape(String value) => value.replaceAll("'", "''");
