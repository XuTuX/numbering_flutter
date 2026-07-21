part of 'package:numbering/services/auth_service.dart';

String _nicknameKey(String userId) => 'auth_nickname_$userId';

Future<void> _fetchUserProfile(AuthService service) async {
  final currentUser = service._supabase?.auth.currentUser;
  if (currentUser == null) {
    _resetProfileState(service);
    return;
  }

  final userId = currentUser.id;
  final requestId = service._beginProfileLoadRequest();
  service.isProfileLoaded.value = false;
  service.hasProfileLoadError.value = false;

  try {
    final preferences = await SharedPreferences.getInstance();
    var nickname = preferences.getString(_nicknameKey(userId))?.trim();
    if (nickname == null || nickname.isEmpty) {
      nickname = RandomNicknameGenerator.generate();
      await preferences.setString(_nicknameKey(userId), nickname);
    }

    if (!service._canApplyProfileLoad(requestId: requestId, userId: userId)) {
      return;
    }
    service.userNickname.value = nickname;
    service.isProfileLoaded.value = true;
  } catch (error, stackTrace) {
    debugPrint('🔴 [AuthService] Failed to read local nickname: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (!service._canApplyProfileLoad(requestId: requestId, userId: userId)) {
      return;
    }
    service.hasProfileLoadError.value = true;
    service.isProfileLoaded.value = true;
  }
}

Future<String?> _updateNickname(AuthService service, String newNickname) async {
  final nickname = newNickname.trim();
  if (nickname.isEmpty) return '닉네임을 입력해주세요'.tr;

  try {
    final currentUser = service._supabase?.auth.currentUser;
    if (currentUser == null) return '로그인이 필요합니다.'.tr;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_nicknameKey(currentUser.id), nickname);
    service.userNickname.value = nickname;
    return null;
  } catch (error) {
    debugPrint('🔴 [AuthService] Local nickname update failed: $error');
    return '업데이트 중 오류가 발생했습니다.'.tr;
  }
}
