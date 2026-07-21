part of 'package:hexor/services/auth_service.dart';

Future<void> _signOut(AuthService service) async {
  service._invalidateProfileLoadRequests();
  await _signOutSocialProviders(service);
  await service._supabase?.auth.signOut();
  _resetProfileState(service);
}

Future<void> _signOutSocialProviders(AuthService service) async {
  final provider = _currentAuthProvider(service);
  if (provider != 'google') return;

  try {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut().timeout(const Duration(seconds: 2));
  } catch (_) {
    debugPrint('🟡 [AuthService] Social sign out timeout or error ignored.');
  }
}

String? _currentAuthProvider(AuthService service) {
  final provider = service._supabase?.auth.currentUser?.appMetadata['provider'];
  return provider is String ? provider : null;
}
