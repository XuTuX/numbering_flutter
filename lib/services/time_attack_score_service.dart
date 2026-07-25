import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class TimeAttackSession {
  const TimeAttackSession({
    required this.id,
    required this.digits,
    required this.puzzleIndex,
    required this.highestNumber,
    required this.totalScore,
    required this.expiresAt,
    this.remainingMilliseconds = 180000,
    this.serverNow,
  });

  final String id;
  final String digits;
  final int puzzleIndex;
  final int highestNumber;
  final int totalScore;
  final DateTime expiresAt;
  final int remainingMilliseconds;
  final DateTime? serverNow;

  factory TimeAttackSession.fromJson(Map<String, Object?> json) {
    final expiresAt =
        DateTime.parse(_requiredString(json, 'expires_at')).toUtc();
    final serverNowValue = json['server_now']?.toString();
    final remainingValue = json['remaining_ms'];
    final fallbackRemaining =
        expiresAt.difference(DateTime.now().toUtc()).inMilliseconds;
    return TimeAttackSession(
      id: _requiredString(json, 'session_id'),
      digits: _requiredString(json, 'digits'),
      puzzleIndex: _requiredInt(json, 'puzzle_index'),
      highestNumber: _requiredInt(json, 'highest_number'),
      totalScore: _requiredInt(json, 'total_score'),
      expiresAt: expiresAt,
      remainingMilliseconds: remainingValue == null
          ? fallbackRemaining.clamp(0, 180000)
          : _requiredInt(json, 'remaining_ms').clamp(0, 180000),
      serverNow: serverNowValue == null
          ? null
          : DateTime.parse(serverNowValue).toUtc(),
    );
  }
}

@immutable
class TimeAttackResult {
  const TimeAttackResult({
    required this.highestNumber,
    required this.totalScore,
  });

  final int highestNumber;
  final int totalScore;

  factory TimeAttackResult.fromJson(Map<String, Object?> json) {
    return TimeAttackResult(
      highestNumber: _requiredInt(json, 'highest_number'),
      totalScore: _requiredInt(json, 'total_score'),
    );
  }
}

@immutable
class TimeAttackRecord {
  const TimeAttackRecord({
    required this.userId,
    required this.nickname,
    required this.highestNumber,
    required this.totalScore,
    required this.highestAchievedAt,
    required this.achievedAt,
    required this.rank,
    required this.isMe,
    this.avatarUrl,
  });

  final String userId;
  final String nickname;
  final int highestNumber;
  final int totalScore;
  final DateTime highestAchievedAt;
  final DateTime achievedAt;
  final int rank;
  final bool isMe;
  final String? avatarUrl;

  factory TimeAttackRecord.fromJson(Map<String, Object?> json) {
    return TimeAttackRecord(
      userId: _requiredString(json, 'user_id'),
      nickname: json['nickname']?.toString() ?? 'Player',
      highestNumber: _requiredInt(json, 'highest_number'),
      totalScore: _requiredInt(json, 'total_score'),
      highestAchievedAt:
          DateTime.parse(_requiredString(json, 'highest_achieved_at')).toUtc(),
      achievedAt: DateTime.parse(_requiredString(json, 'achieved_at')).toUtc(),
      rank: _requiredInt(json, 'rank'),
      isMe: json['is_me'] == true,
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

class TimeAttackServiceException implements Exception {
  const TimeAttackServiceException(this.code, this.userMessage);

  final String code;
  final String userMessage;

  @override
  String toString() => userMessage;
}

class TimeAttackScoreService extends GetxService {
  TimeAttackScoreService({SupabaseClient? supabase}) : _supabase = supabase;

  final SupabaseClient? _supabase;
  StreamSubscription<AuthState>? _authSubscription;
  int _leaderboardRequestId = 0;

  final RxList<TimeAttackRecord> records = <TimeAttackRecord>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();
  final RxnInt myRank = RxnInt();

  bool get isAvailable => _supabase != null;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _supabase?.auth.onAuthStateChange.listen((state) {
      if (state.session == null) {
        _leaderboardRequestId++;
        records.clear();
        myRank.value = null;
        loadError.value = null;
        return;
      }
      unawaited(refreshLeaderboard());
    });
    unawaited(refreshLeaderboard());
  }

  @override
  void onClose() {
    unawaited(_authSubscription?.cancel());
    super.onClose();
  }

  Future<TimeAttackSession> startSession() async {
    final response = await _rpc('start_numbering_time_attack');
    return TimeAttackSession.fromJson(_asMap(response));
  }

  Future<TimeAttackSession> submitSolution({
    required String sessionId,
    required int puzzleIndex,
    required String expression,
  }) async {
    final response = await _rpc(
      'submit_numbering_time_attack_solution',
      <String, Object?>{
        'p_session_id': sessionId,
        'p_puzzle_index': puzzleIndex,
        'p_expression': expression,
      },
    );
    return TimeAttackSession.fromJson(_asMap(response));
  }

  Future<TimeAttackResult> finishSession(String sessionId) async {
    final response = await _rpc(
      'finish_numbering_time_attack',
      <String, Object?>{'p_session_id': sessionId},
    );
    final result = TimeAttackResult.fromJson(_asMap(response));
    await refreshLeaderboard();
    return result;
  }

  Future<void> refreshLeaderboard({int limit = 100}) async {
    final userId = _supabase?.auth.currentUser?.id;
    final requestId = ++_leaderboardRequestId;
    if (userId == null) {
      records.clear();
      myRank.value = null;
      return;
    }

    isLoading.value = true;
    loadError.value = null;
    try {
      final response = await _rpc(
        'get_numbering_time_attack_leaderboard',
        <String, Object?>{'p_limit': limit},
      );
      final rows = response is List<Object?> ? response : const <Object?>[];
      final loaded = rows
          .map(_asMap)
          .map(TimeAttackRecord.fromJson)
          .toList(growable: false);
      if (!_canApplyLeaderboard(requestId: requestId, userId: userId)) return;
      records.assignAll(loaded);
      myRank.value = personalBest?.rank;
    } on TimeAttackServiceException catch (error) {
      if (!_canApplyLeaderboard(requestId: requestId, userId: userId)) return;
      loadError.value = error.userMessage;
    } finally {
      if (requestId == _leaderboardRequestId) {
        isLoading.value = false;
      }
    }
  }

  bool _canApplyLeaderboard({
    required int requestId,
    required String userId,
  }) {
    return !isClosed &&
        requestId == _leaderboardRequestId &&
        _supabase?.auth.currentUser?.id == userId;
  }

  TimeAttackRecord? get personalBest {
    for (final record in records) {
      if (record.isMe) return record;
    }
    return null;
  }

  Future<Object?> _rpc(
    String functionName, [
    Map<String, Object?> params = const <String, Object?>{},
  ]) async {
    final client = _supabase;
    if (client == null) {
      throw const TimeAttackServiceException(
        'network_error',
        '서버에 연결할 수 없습니다.',
      );
    }
    if (client.auth.currentUser == null) {
      throw const TimeAttackServiceException(
        'auth_required',
        '로그인이 필요합니다.',
      );
    }

    try {
      return await client.rpc(functionName, params: params);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    } catch (error, stackTrace) {
      debugPrint('Time Attack RPC failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const TimeAttackServiceException(
        'network_error',
        '네트워크 오류가 발생했습니다.',
      );
    }
  }
}

TimeAttackServiceException _mapPostgrestError(PostgrestException error) {
  final message = error.message.toLowerCase();
  if (message.contains('not authenticated')) {
    return const TimeAttackServiceException('auth_required', '로그인이 필요합니다.');
  }
  if (message.contains('expired')) {
    return const TimeAttackServiceException('session_expired', '시간이 종료되었습니다.');
  }
  if (message.contains('still active')) {
    return const TimeAttackServiceException(
        'session_active', '게임이 아직 진행 중입니다.');
  }
  if (message.contains('rate limit')) {
    return const TimeAttackServiceException(
      'rate_limited',
      '잠시 후 다시 시도해 주세요.',
    );
  }
  if (message.contains('expression') ||
      message.contains('digits') ||
      message.contains('score') ||
      message.contains('puzzle index')) {
    return const TimeAttackServiceException('invalid_result', '수식을 확인해 주세요.');
  }
  return const TimeAttackServiceException('server_error', '서버 오류가 발생했습니다.');
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw const TimeAttackServiceException('server_error', '서버 응답이 올바르지 않습니다.');
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key]?.toString();
  if (value == null || value.isEmpty) {
    throw TimeAttackServiceException('server_error', '서버 응답에 $key 값이 없습니다.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed != null) return parsed;
  throw TimeAttackServiceException('server_error', '서버 응답에 $key 값이 없습니다.');
}
