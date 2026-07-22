import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/widgets/home_screen/nickname_sticker_card.dart';

void main() {
  testWidgets('shows the loaded nickname and allows editing', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NicknameStickerCard(
            nickname: 'SavedPlayer',
            score: 1234,
            onTapNickname: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('SavedPlayer'), findsOneWidget);

    await tester.tap(find.text('SavedPlayer'));
    expect(tapped, isTrue);
  });
}
