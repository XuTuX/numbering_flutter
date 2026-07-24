import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:numbering/constant.dart' show gameId;
import 'package:numbering/services/database_models.dart';

enum DailyChallengeUiState {
  loading,
  available,
  alreadyPlayed,
  notAuthenticated,
  networkError,
  submissionError,
}

@immutable
class NumberingSubmissionResult {
  const NumberingSubmissionResult({
    required this.verifiedScore,
    required this.previousBest,
    required this.currentBest,
    required this.isNewBest,
    this.rank,
    this.weeklyBest,
    this.verifiedStage,
    this.dateKey,
    this.isIdempotent = false,
  });

  final int verifiedScore;
  final int? previousBest;
  final int currentBest;
  final bool isNewBest;
  final int? rank;
  final int? weeklyBest;
  final int? verifiedStage;
  final String? dateKey;
  final bool isIdempotent;

  factory NumberingSubmissionResult.fromJson(Map<String, Object?> json) {
    final verifiedScore = _requiredInt(json, 'verified_score');
    return NumberingSubmissionResult(
      verifiedScore: verifiedScore,
      previousBest: _optionalInt(json['previous_best']),
      currentBest: _optionalInt(json['current_best']) ?? verifiedScore,
      isNewBest: json['is_new_best'] == true,
      rank: _optionalInt(json['rank']),
      weeklyBest: _optionalInt(json['weekly_best']),
      verifiedStage: _optionalInt(json['verified_stage']),
      dateKey: json['date_key']?.toString(),
      isIdempotent: json['is_idempotent'] == true,
    );
  }
}

@immutable
class NumberingLeaderboardEntry {
  const NumberingLeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.score,
    required this.rank,
    this.avatarUrl,
  });

  final String userId;
  final String nickname;
  final int score;
  final int rank;
  final String? avatarUrl;

  factory NumberingLeaderboardEntry.fromJson(Map<String, Object?> json) {
    return NumberingLeaderboardEntry(
      userId: json['user_id']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? 'Player',
      score: _requiredInt(json, 'score'),
      rank: _requiredInt(json, 'rank'),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

@immutable
class DailyPuzzleParenthesis {
  const DailyPuzzleParenthesis({
    required this.start,
    required this.end,
  });

  final int start;
  final int end;

  Map<String, Object?> toJson() => {'start': start, 'end': end};
}

@immutable
class DailyPuzzleProgress {
  const DailyPuzzleProgress({
    required this.digits,
    required this.operators,
    required this.parentheses,
    this.liftedIndices = const [],
  });

  final List<String> digits;
  final List<String?> operators;
  final List<DailyPuzzleParenthesis> parentheses;
  final List<int> liftedIndices;

  Map<String, Object?> toJson() => <String, Object?>{
        'version': 2,
        'digits': digits,
        'operators': operators,
        'parentheses': parentheses.map((item) => item.toJson()).toList(),
        'liftedIndices': liftedIndices,
      };

  factory DailyPuzzleProgress.fromJson(Map<String, Object?> json) {
    final rawDigits = json['digits'];
    final rawOperators = json['operators'];
    final rawParentheses = json['parentheses'];
    final rawLifted = json['liftedIndices'];
    return DailyPuzzleProgress(
      digits: rawDigits is List
          ? rawDigits.map((item) => item.toString()).toList(growable: false)
          : const [],
      operators: rawOperators is List
          ? rawOperators
              .map<String?>((item) => item?.toString())
              .toList(growable: false)
          : const [],
      parentheses: rawParentheses is List
          ? rawParentheses
              .whereType<Map>()
              .map(
                (item) => DailyPuzzleParenthesis(
                  start: _optionalInt(item['start']) ?? -1,
                  end: _optionalInt(item['end']) ?? -1,
                ),
              )
              .toList(growable: false)
          : const [],
      liftedIndices: rawLifted is List
          ? rawLifted
              .map((item) => _optionalInt(item))
              .whereType<int>()
              .toList(growable: false)
          : const [],
    );
  }
}

class NumberingServiceException implements Exception {
  const NumberingServiceException(this.code, this.userMessage);

  final String code;
  final String userMessage;

  @override
  String toString() => userMessage;
}

class NumberingScoreService {
  NumberingScoreService({SupabaseClient? supabase}) : _supabase = supabase;

  final SupabaseClient? _supabase;

  bool get isAvailable => _supabase != null;
  bool get isAuthenticated => _supabase?.auth.currentUser != null;

  Future<DailyChallengeInfo> getDailyChallenge() async {
    final response = await _rpc(
      'get_daily_challenge',
      const <String, Object?>{'p_game_id': gameId},
    );
    final row = _firstRow(response);
    return DailyChallengeInfo(
      dateKey: row['date_key']?.toString() ?? '',
      seed: _requiredInt(row, 'seed'),
      hasUsedEntry: row['has_used_entry'] == true,
      myScore: _optionalInt(row['my_score']),
    );
  }

  Future<DailyChallengeInfo> claimDailyChallenge() async {
    try {
      final response = await _rpc(
        'claim_daily_challenge_entry',
        const <String, Object?>{'p_game_id': gameId},
      );
      final row = _firstRow(response);
      return DailyChallengeInfo(
        dateKey: row['date_key']?.toString() ?? '',
        seed: _requiredInt(row, 'seed'),
        hasUsedEntry: true,
        myScore: _optionalInt(row['my_score']),
      );
    } on NumberingServiceException catch (error) {
      // A lost response after a successful claim is recovered by reading the
      // server state. An unfinished attempt may resume with the same seed.
      if (error.code != 'already_participated') rethrow;
      final challenge = await getDailyChallenge();
      if (challenge.hasUsedEntry && challenge.myScore == null) return challenge;
      rethrow;
    }
  }

  Future<NumberingSubmissionResult> submitNormalResult({
    required int levelId,
    required String expression,
    required int usedHints,
  }) async {
    _requireAuthentication();
    final response = await _rpc(
      'submit_numbering_result',
      <String, Object?>{
        'p_level_id': levelId,
        'p_expression': expression,
        'p_used_hints': usedHints,
      },
    );
    return NumberingSubmissionResult.fromJson(_asMap(response));
  }

  Future<NumberingSubmissionResult> submitDailyResult({
    required int seed,
    required String expression,
  }) async {
    _requireAuthentication();
    final response = await _rpc(
      'submit_numbering_daily_result',
      <String, Object?>{
        'p_seed': seed,
        'p_expression': expression,
      },
    );
    return NumberingSubmissionResult.fromJson(_asMap(response));
  }

  Future<DailyPuzzleProgress?> getDailyProgress({
    required String periodKey,
    required int seed,
  }) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;
    try {
      final row = await client
          .from('numbering_daily_progress')
          .select('seed, state')
          .eq('user_id', user.id)
          .eq('period_key', periodKey)
          .maybeSingle();
      if (row == null || _optionalInt(row['seed']) != seed) return null;
      return DailyPuzzleProgress.fromJson(_asMap(row['state']));
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<void> saveDailyProgress({
    required String periodKey,
    required int seed,
    required DailyPuzzleProgress progress,
  }) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    try {
      await client.from('numbering_daily_progress').upsert(
        <String, Object?>{
          'user_id': user.id,
          'period_key': periodKey,
          'seed': seed,
          'state': progress.toJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,period_key',
      );
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<void> clearDailyProgress({required String periodKey}) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    try {
      await client
          .from('numbering_daily_progress')
          .delete()
          .eq('user_id', user.id)
          .eq('period_key', periodKey);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<List<NumberingLeaderboardEntry>> getAllTimeLeaderboard({
    int limit = 50,
  }) {
    return _getLeaderboard(
      'get_all_time_leaderboard',
      <String, Object?>{'p_game_id': gameId, 'p_limit': limit},
    );
  }

  Future<List<NumberingLeaderboardEntry>> getWeeklyLeaderboard({
    int limit = 50,
  }) {
    return _getLeaderboard(
      'get_weekly_leaderboard',
      <String, Object?>{'p_game_id': gameId, 'p_limit': limit},
    );
  }

  Future<List<NumberingLeaderboardEntry>> getDailyLeaderboard({
    required String dateKey,
    int limit = 50,
  }) {
    return _getLeaderboard(
      'get_daily_leaderboard',
      <String, Object?>{
        'p_game_id': gameId,
        'p_date_key': dateKey,
        'p_limit': limit,
      },
    );
  }

  Future<int?> getMyScore(
      {required String functionName, String? dateKey}) async {
    if (!isAuthenticated) return null;
    final params = <String, Object?>{'p_game_id': gameId};
    if (dateKey != null) params['p_date_key'] = dateKey;
    final response = await _rpc(functionName, params);
    return _optionalInt(response);
  }

  Future<List<NumberingLeaderboardEntry>> _getLeaderboard(
    String functionName,
    Map<String, Object?> params,
  ) async {
    final response = await _rpc(functionName, params);
    final rows = response is List<Object?> ? response : const <Object?>[];
    return rows
        .map(_asMap)
        .map(NumberingLeaderboardEntry.fromJson)
        .toList(growable: false);
  }

  void _requireAuthentication() {
    if (!isAuthenticated) {
      throw const NumberingServiceException('auth_required', '로그인이 필요합니다.');
    }
  }

  Future<Object?> _rpc(String functionName, Map<String, Object?> params) async {
    final client = _supabase;
    if (client == null) {
      throw const NumberingServiceException(
        'network_error',
        '서버에 연결할 수 없습니다. 네트워크 연결을 확인해 주세요.',
      );
    }
    try {
      return await client.rpc(functionName, params: params);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    } catch (_) {
      throw const NumberingServiceException(
        'network_error',
        '네트워크 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }
}

NumberingServiceException _mapPostgrestError(PostgrestException error) {
  final message = error.message.toLowerCase();
  if (message.contains('auth') || message.contains('not authenticated')) {
    return const NumberingServiceException('auth_required', '로그인이 필요합니다.');
  }
  if (message.contains('already used') ||
      message.contains('already participated')) {
    return const NumberingServiceException(
      'already_participated',
      '이번 12시간 퍼즐에 이미 참여했습니다.',
    );
  }
  if (message.contains('already submitted') ||
      message.contains('already finalized')) {
    return const NumberingServiceException(
      'already_submitted',
      '이번 12시간 퍼즐 점수 제출이 이미 완료되었습니다.',
    );
  }
  if (message.contains('seed')) {
    return const NumberingServiceException(
        'invalid_seed', '오늘의 퍼즐 정보가 올바르지 않습니다.');
  }
  if (message.contains('date') || message.contains('today')) {
    return const NumberingServiceException(
        'invalid_date', '오늘 날짜의 도전만 제출할 수 있습니다.');
  }
  if (message.contains('expression') ||
      message.contains('result') ||
      message.contains('score')) {
    return const NumberingServiceException(
        'invalid_result', '유효하지 않은 게임 결과입니다.');
  }
  return const NumberingServiceException(
    'server_error',
    '서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
  );
}

Map<String, Object?> _firstRow(Object? value) {
  if (value is List<Object?> && value.isNotEmpty) return _asMap(value.first);
  return _asMap(value);
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw const NumberingServiceException('server_error', '서버 응답 형식이 올바르지 않습니다.');
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = _optionalInt(json[key]);
  if (value == null) {
    throw NumberingServiceException('server_error', '서버 응답에 $key 값이 없습니다.');
  }
  return value;
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
