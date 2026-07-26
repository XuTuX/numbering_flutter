import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'level_models.dart';
import 'level_catalog.dart';

class LevelProgressService extends GetxService {
  static const _progressKey = 'numbering_level_progress_v1';
  static const _lastLevelKey = 'numbering_last_level_v1';
  static const _sydneyMigrationKey = 'numbering_sydney_progress_migrated_v1';
  static const _accountProgressKey = 'numbering_level_progress_v2';
  static const _accountLastLevelKey = 'numbering_last_level_v2';
  static const _legacyProgressOwnerKey =
      'numbering_level_progress_v1_account_owner';

  final progress = <int, LevelProgress>{}.obs;
  final lastPlayedLevel = 1.obs;
  late SharedPreferences _preferences;
  SupabaseClient? _supabase;
  StreamSubscription<AuthState>? _authSubscription;
  int _syncRequestId = 0;

  Future<LevelProgressService> init() async {
    _preferences = await SharedPreferences.getInstance();
    lastPlayedLevel.value = _preferences.getInt(_lastLevelKey) ?? 1;
    final encoded = _preferences.getString(_progressKey);
    if (encoded != null) {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      progress.assignAll({
        for (final entry in decoded.entries)
          int.parse(entry.key): LevelProgress.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      });
    }
    await _migrateProgressForSydney();
    return this;
  }

  Future<void> connect(SupabaseClient? supabase) async {
    await _authSubscription?.cancel();
    _supabase = supabase;
    if (supabase == null) return;

    await _syncForCurrentSession();
    _authSubscription = supabase.auth.onAuthStateChange.listen((_) {
      unawaited(_syncForCurrentSession());
    });
  }

  Future<void> _migrateProgressForSydney() async {
    if (_preferences.getBool(_sydneyMigrationKey) ?? false) return;

    final migrated = <int, LevelProgress>{};
    for (final entry in progress.entries) {
      final newId =
          entry.key >= 81 && entry.key <= 160 ? entry.key + 40 : entry.key;
      final value = entry.value;
      migrated[newId] = LevelProgress(
        levelId: newId,
        cleared: value.cleared,
        bestScore: value.bestScore,
        stars: value.stars,
        perfect: value.perfect,
        usedHints: value.usedHints,
      );
    }
    progress.assignAll(migrated);

    if (lastPlayedLevel.value >= 81 && lastPlayedLevel.value <= 160) {
      lastPlayedLevel.value += 40;
      await _preferences.setInt(_lastLevelKey, lastPlayedLevel.value);
    }
    if (migrated.isNotEmpty) await _save();
    await _preferences.setBool(_sydneyMigrationKey, true);
  }

  int get highestUnlockedLevel {
    var highest = 1;
    for (var id = 1; id < LevelCatalog.all.length; id++) {
      if (!(progress[id]?.cleared ?? false)) break;
      highest = id + 1;
    }
    return highest;
  }

  bool isUnlocked(int levelId) => levelId <= highestUnlockedLevel;

  LevelProgress forLevel(int levelId) =>
      progress[levelId] ?? LevelProgress(levelId: levelId);

  Future<void> rememberLevel(int levelId) async {
    lastPlayedLevel.value = levelId;
    await _preferences.setInt(_lastLevelStorageKey, levelId);
  }

  Future<void> recordResult({
    required LevelData level,
    required int score,
    required LevelEvaluation evaluation,
    required int usedHints,
  }) async {
    final previous = forLevel(level.id);
    final isBetter = previous.bestScore == null || score > previous.bestScore!;
    progress[level.id] = LevelProgress(
      levelId: level.id,
      cleared: previous.cleared || evaluation.cleared,
      bestScore: isBetter ? score : previous.bestScore,
      stars: isBetter ? evaluation.stars : previous.stars,
      perfect: previous.perfect || evaluation.perfect,
      usedHints: isBetter ? usedHints : previous.usedHints,
    );
    await rememberLevel(level.id);
    await _save();
    unawaited(_syncForCurrentSession());
  }

  Future<void> _save() async {
    final encoded = jsonEncode({
      for (final entry in progress.entries)
        '${entry.key}': entry.value.toJson(),
    });
    await _preferences.setString(_progressStorageKey, encoded);
  }

  Future<void> _syncForCurrentSession() async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    final requestId = ++_syncRequestId;
    if (client == null) return;
    if (user == null) {
      await _loadLegacyProgress();
      return;
    }

    final localProgress = await _readProgress(_accountProgressKeyFor(user.id));
    var localLastLevel =
        _preferences.getInt(_accountLastLevelKeyFor(user.id)) ?? 1;
    final legacyOwner = _preferences.getString(_legacyProgressOwnerKey);
    final shouldClaimLegacy = legacyOwner == null || legacyOwner == user.id;
    if (shouldClaimLegacy) {
      final legacyProgress = await _readProgress(_progressKey);
      for (final entry in legacyProgress.entries) {
        localProgress.update(
          entry.key,
          (current) => mergeProgress(current, entry.value),
          ifAbsent: () => entry.value,
        );
      }
      localLastLevel = _preferences.getInt(_lastLevelKey) ?? localLastLevel;
    }

    if (!_canApplySync(client, user.id, requestId)) return;
    progress.assignAll(localProgress);
    lastPlayedLevel.value = localLastLevel;

    try {
      final response = await client.rpc(
        'sync_my_numbering_arcade_progress',
        params: <String, Object?>{
          'p_progress': [
            for (final item in localProgress.values) item.toJson(),
          ],
        },
      );
      if (!_canApplySync(client, user.id, requestId)) return;

      final syncedProgress = _decodeCloudProgress(response);
      progress.assignAll(syncedProgress);
      await _saveAccountCache(user.id);

      if (shouldClaimLegacy) {
        await _preferences.setString(_legacyProgressOwnerKey, user.id);
        await _preferences.remove(_progressKey);
        await _preferences.remove(_lastLevelKey);
      }
    } catch (error, stackTrace) {
      debugPrint('Arcade progress sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool _canApplySync(
    SupabaseClient client,
    String userId,
    int requestId,
  ) {
    return !isClosed &&
        requestId == _syncRequestId &&
        client.auth.currentUser?.id == userId;
  }

  Future<void> _loadLegacyProgress() async {
    final legacyProgress = await _readProgress(_progressKey);
    if (isClosed || _supabase?.auth.currentUser != null) return;
    progress.assignAll(legacyProgress);
    lastPlayedLevel.value = _preferences.getInt(_lastLevelKey) ?? 1;
  }

  Future<Map<int, LevelProgress>> _readProgress(String key) async {
    final encoded = _preferences.getString(key);
    if (encoded == null) return <int, LevelProgress>{};
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        int.parse(entry.key): LevelProgress.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        ),
    };
  }

  Map<int, LevelProgress> _decodeCloudProgress(Object? response) {
    if (response is! List) {
      throw const FormatException('Unexpected arcade progress response');
    }
    final decoded = <int, LevelProgress>{};
    for (final item in response) {
      if (item is! Map) {
        throw const FormatException('Invalid arcade progress entry');
      }
      final record = LevelProgress.fromJson(Map<String, dynamic>.from(item));
      decoded[record.levelId] = record;
    }
    return decoded;
  }

  @visibleForTesting
  static LevelProgress mergeProgress(
    LevelProgress current,
    LevelProgress incoming,
  ) {
    final incomingIsBetter = incoming.bestScore != null &&
        (current.bestScore == null || incoming.bestScore! > current.bestScore!);
    final scoresAreEqual = current.bestScore == incoming.bestScore;
    return LevelProgress(
      levelId: current.levelId,
      cleared: current.cleared || incoming.cleared,
      bestScore: incomingIsBetter ? incoming.bestScore : current.bestScore,
      stars: incomingIsBetter
          ? incoming.stars
          : scoresAreEqual
              ? (current.stars >= incoming.stars
                  ? current.stars
                  : incoming.stars)
              : current.stars,
      perfect: current.perfect || incoming.perfect,
      usedHints: incomingIsBetter
          ? incoming.usedHints
          : scoresAreEqual
              ? (current.usedHints <= incoming.usedHints
                  ? current.usedHints
                  : incoming.usedHints)
              : current.usedHints,
    );
  }

  Future<void> _saveAccountCache(String userId) async {
    final encoded = jsonEncode({
      for (final entry in progress.entries)
        '${entry.key}': entry.value.toJson(),
    });
    await _preferences.setString(_accountProgressKeyFor(userId), encoded);
    await _preferences.setInt(
      _accountLastLevelKeyFor(userId),
      lastPlayedLevel.value,
    );
  }

  String get _progressStorageKey {
    final userId = _supabase?.auth.currentUser?.id;
    return userId == null ? _progressKey : _accountProgressKeyFor(userId);
  }

  String get _lastLevelStorageKey {
    final userId = _supabase?.auth.currentUser?.id;
    return userId == null ? _lastLevelKey : _accountLastLevelKeyFor(userId);
  }

  String _accountProgressKeyFor(String userId) =>
      '$_accountProgressKey:$userId';

  String _accountLastLevelKeyFor(String userId) =>
      '$_accountLastLevelKey:$userId';

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
