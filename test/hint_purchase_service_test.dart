import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/services/hint_purchase_service.dart';

void main() {
  test('defines the three consumable hint packs for both stores', () {
    expect(
      hintPacks.map((pack) => pack.productId),
      orderedEquals(const [
        'numbering_hints_11',
        'numbering_hints_50',
        'numbering_hints_100',
      ]),
    );
    expect(
      hintPacks.map((pack) => pack.hintCount),
      orderedEquals(const [11, 50, 100]),
    );
    expect(
      hintPacks.map((pack) => pack.fallbackPrice),
      orderedEquals(const ['₩1,100', '₩3,300', '₩5,500']),
    );
  });
}
