part of 'package:numbering/services/auth_service.dart';

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

/// Deletes the signed-in NEOREO GAMES account and every linked game record.
///
/// The `delete-account` Edge Function removes the owned rows with the service
/// role and then deletes the auth user, so the client only has to clear the
/// local session afterwards. Returns `null` on success, or a translated error
/// message to show the user.
Future<String?> _deleteAccount(AuthService service) async {
  final supabase = service._supabase;
  if (supabase == null) {
    return '로그인 기능을 사용하려면 Supabase 설정이 필요합니다.'.tr;
  }
  if (supabase.auth.currentUser == null) {
    return '로그인이 필요합니다.'.tr;
  }

  service.isLoading.value = true;
  try {
    final response = await supabase.functions.invoke('delete-account');
    final result = response.data;
    final succeeded = result is Map && result['success'] == true;
    if (!succeeded) {
      debugPrint('🔴 [AuthService] Account deletion rejected: $result');
      return '계정 삭제 중 오류가 발생했습니다. 다시 시도해주세요.'.tr;
    }

    // The auth user is gone, so the refresh token is already invalid. Clear the
    // local session directly and ignore the expected server-side sign-out
    // failure rather than leaving the app on a dangling session.
    service._invalidateProfileLoadRequests();
    await _signOutSocialProviders(service);
    try {
      await supabase.auth.signOut();
    } catch (error) {
      debugPrint('🟡 [AuthService] Sign out after deletion ignored: $error');
    }
    service.user.value = null;
    _resetProfileState(service);
    return null;
  } catch (error, stackTrace) {
    debugPrint('🔴 [AuthService] Account deletion failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    return '계정 삭제 중 오류가 발생했습니다. 다시 시도해주세요.'.tr;
  } finally {
    service.isLoading.value = false;
  }
}

String? _currentAuthProvider(AuthService service) {
  final provider = service._supabase?.auth.currentUser?.appMetadata['provider'];
  return provider is String ? provider : null;
}
