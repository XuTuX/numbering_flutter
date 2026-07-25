import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/controllers/score/score_merge_service.dart';

void main() {
  const service = ScoreMergeService();

  test('storage key is scoped per user id', () {
    expect(service.storageKeyFor('abc123'), equals('high_score_abc123'));
    expect(service.storageKeyFor(null), equals('high_score_guest'));
  });

  group('mergeOnLogin', () {
    test('keeps the existing user score when it is already the highest', () {
      final merged = service.mergeOnLogin(
        userLocalScore: 500,
        legacyScore: 100,
        guestScore: 200,
      );
      expect(merged, equals(500));
    });

    test('carries over a guest score earned before signing in', () {
      final merged = service.mergeOnLogin(
        userLocalScore: 100,
        legacyScore: 0,
        guestScore: 900,
      );
      expect(merged, equals(900));
    });

    test('migrates a pre-migration legacy score', () {
      final merged = service.mergeOnLogin(
        userLocalScore: 0,
        legacyScore: 300,
        guestScore: 0,
      );
      expect(merged, equals(300));
    });

    test('defaults to zero when nothing has been recorded', () {
      final merged = service.mergeOnLogin(
        userLocalScore: 0,
        legacyScore: 0,
        guestScore: 0,
      );
      expect(merged, equals(0));
    });
  });
}
