import 'package:flutter_test/flutter_test.dart';
import 'package:numbering/services/auth_service.dart';

void main() {
  group('nickname validation', () {
    test('rejects nicknames shorter than two characters before auth lookup',
        () async {
      final service = AuthService();

      expect(
        await service.updateNickname(' A '),
        '닉네임은 2~24자로 입력해주세요.',
      );
    });

    test('rejects nicknames longer than 24 characters before auth lookup',
        () async {
      final service = AuthService();

      expect(
        await service.updateNickname(List.filled(25, 'a').join()),
        '닉네임은 2~24자로 입력해주세요.',
      );
    });
  });
}
