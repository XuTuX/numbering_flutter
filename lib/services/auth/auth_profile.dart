part of 'package:numbering/services/auth_service.dart';

const _randomNicknameAttempts = 8;

Future<void> _fetchUserProfile(AuthService service) async {
  final supabase = service._supabase;
  final currentUser = supabase?.auth.currentUser;
  if (supabase == null || currentUser == null) {
    _resetProfileState(service);
    return;
  }

  final userId = currentUser.id;
  final requestId = service._beginProfileLoadRequest();
  service.isProfileLoaded.value = false;
  service.hasProfileLoadError.value = false;

  try {
    final row = await supabase
        .from('profiles')
        .select('nickname')
        .eq('id', userId)
        .maybeSingle();

    var nickname = _normalizedNickname(row?['nickname']);
    if (nickname == null || nickname.isEmpty) {
      nickname = await _ensureRandomNickname(supabase);
    }

    if (!service._canApplyProfileLoad(requestId: requestId, userId: userId)) {
      return;
    }
    service.userNickname.value = _normalizedNickname(nickname);
    service.isProfileLoaded.value = true;
  } catch (error, stackTrace) {
    debugPrint('🔴 [AuthService] Failed to load Supabase nickname: $error');
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
  if (nickname.runes.length < 2 || nickname.runes.length > 24) {
    return '닉네임은 2~24자로 입력해주세요.'.tr;
  }

  try {
    final supabase = service._supabase;
    if (supabase?.auth.currentUser == null) return '로그인이 필요합니다.'.tr;

    final result = await supabase!.rpc(
      'update_my_nickname',
      params: {'p_nickname': nickname},
    );
    service.userNickname.value = _normalizedNickname(result) ?? nickname;
    return null;
  } on PostgrestException catch (error) {
    debugPrint('🔴 [AuthService] Supabase nickname update failed: $error');
    if (_isDuplicateNickname(error)) {
      return '이미 사용 중인 닉네임입니다. \n다른 닉네임을 선택해주세요.'.tr;
    }
    if (error.code == '22023') {
      return '닉네임은 2~24자로 입력해주세요.'.tr;
    }
    if (error.code == '28000') return '로그인이 필요합니다.'.tr;
    return '업데이트 중 오류가 발생했습니다.'.tr;
  } catch (error) {
    debugPrint('🔴 [AuthService] Supabase nickname update failed: $error');
    return '업데이트 중 오류가 발생했습니다.'.tr;
  }
}

Future<String?> _ensureRandomNickname(SupabaseClient supabase) async {
  for (var attempt = 0; attempt < _randomNicknameAttempts; attempt++) {
    final candidate = RandomNicknameGenerator.generate();
    try {
      final result = await supabase.rpc(
        'ensure_my_nickname',
        params: {'p_nickname': candidate},
      );
      final saved = _normalizedNickname(result);
      if (saved != null) return saved;
    } on PostgrestException catch (error) {
      if (_isDuplicateNickname(error)) continue;
      rethrow;
    }
  }

  // Leave the nickname empty so the home screen's required setup dialog can
  // act as a fallback after repeated random collisions.
  return null;
}

String? _normalizedNickname(Object? value) {
  final trimmed = value?.toString().trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

bool _isDuplicateNickname(PostgrestException error) {
  return error.code == '23505' ||
      error.message.contains('nickname_already_exists');
}
