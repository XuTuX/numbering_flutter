import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'level_models.dart';
import 'level_catalog.dart';

class LevelProgressService extends GetxService {
  static const _progressKey = 'numbering_level_progress_v1';
  static const _lastLevelKey = 'numbering_last_level_v1';
  static const _sydneyMigrationKey = 'numbering_sydney_progress_migrated_v1';

  final progress = <int, LevelProgress>{}.obs;
  final lastPlayedLevel = 1.obs;
  late SharedPreferences _preferences;

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
    await _preferences.setInt(_lastLevelKey, levelId);
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
  }

  Future<void> _save() async {
    final encoded = jsonEncode({
      for (final entry in progress.entries)
        '${entry.key}': entry.value.toJson(),
    });
    await _preferences.setString(_progressKey, encoded);
  }
}
