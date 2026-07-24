import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/game/numbering/level_catalog.dart';

void main() {
  test('every arcade level has a distinct equation shape', () {
    final shapes = <String>{};
    final operatorSequences = <String>{};

    for (final level in LevelCatalog.all) {
      shapes.add(_shape(level.officialAnswer));
      operatorSequences.add(_operators(level.officialAnswer));
    }

    expect(shapes, hasLength(LevelCatalog.all.length));
    expect(operatorSequences.length, greaterThanOrEqualTo(195));
  });
}

String _shape(String expression) {
  final sides = expression
      .split('=')
      .map((side) => side.replaceAll(RegExp(r'\d+'), '#'))
      .toList()
    ..sort();
  return sides.join('=');
}

String _operators(String expression) =>
    expression.replaceAll(RegExp(r'[0-9()]'), '');
