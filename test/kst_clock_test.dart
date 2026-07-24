import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/utils/kst_clock.dart';

void main() {
  test('daily challenge period changes at noon KST', () {
    expect(
      KstClock.challengePeriodKeyFor(DateTime(2026, 7, 24, 11, 59)),
      '2026-07-24-00',
    );
    expect(
      KstClock.challengePeriodKeyFor(DateTime(2026, 7, 24, 12)),
      '2026-07-24-12',
    );
  });

  test('challenge labels identify the morning and afternoon windows', () {
    expect(KstClock.compactDateLabel('2026-07-24-00'), '07.24 오전');
    expect(KstClock.compactDateLabel('2026-07-24-12'), '07.24 오후');
  });
}
