import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/services/database_models.dart';

void main() {
  test('score based season tiers include the Jesus threshold', () {
    expect(SeasonTier.fromScore(69999), SeasonTier.diamond);
    expect(SeasonTier.fromScore(70000), SeasonTier.master);
    expect(SeasonTier.fromScore(99999), SeasonTier.master);
    expect(SeasonTier.fromScore(100000), SeasonTier.challenger);
    expect(SeasonTier.fromScore(499999), SeasonTier.challenger);
    expect(SeasonTier.fromScore(500000), SeasonTier.jesus);
    expect(SeasonTier.fromValue('jesus'), SeasonTier.jesus);
    expect(SeasonTier.jesus.label, 'JESUS');
  });
}
