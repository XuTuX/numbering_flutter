import 'package:flutter_test/flutter_test.dart';
import 'package:hexor/services/auth_service.dart';

void main() {
  test('auth service supports offline guest mode without Supabase', () async {
    final service = AuthService();

    service.onInit();

    expect(service.isAuthAvailable, isFalse);
    expect(service.user.value, isNull);
    expect(service.isProfileLoaded.value, isTrue);
    expect(await service.signInWithGoogle(), contains('Supabase'));
    await service.signOut();

    service.onClose();
  });
}
