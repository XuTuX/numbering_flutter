import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class TimeAttackRecord {
  const TimeAttackRecord({
    required this.id,
    required this.nickname,
    required this.highestNumber,
    required this.totalScore,
    required this.achievedAt,
    required this.playedAt,
  });

  final String id;
  final String nickname;
  final int highestNumber;
  final int totalScore;
  final DateTime achievedAt;
  final DateTime playedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'highestNumber': highestNumber,
        'totalScore': totalScore,
        'achievedAt': achievedAt.toIso8601String(),
        'playedAt': playedAt.toIso8601String(),
      };

  factory TimeAttackRecord.fromJson(Map<String, dynamic> json) => TimeAttackRecord(
        id: json['id'] as String? ?? '',
        nickname: json['nickname'] as String? ?? 'Player',
        highestNumber: json['highestNumber'] as int? ?? 0,
        totalScore: json['totalScore'] as int? ?? 0,
        achievedAt: DateTime.parse(json['achievedAt'] as String),
        playedAt: DateTime.parse(json['playedAt'] as String),
      );
}

class TimeAttackScoreService extends GetxService {
  static const _storageKey = 'numbering_time_attack_records_v1';
  final RxList<TimeAttackRecord> records = <TimeAttackRecord>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];
    final loaded = <TimeAttackRecord>[];
    for (final raw in rawList) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        loaded.add(TimeAttackRecord.fromJson(json));
      } catch (_) {}
    }
    _sortRecords(loaded);
    records.assignAll(loaded);
  }

  Future<void> submitRecord({
    required String nickname,
    required int highestNumber,
    required int totalScore,
    required DateTime achievedAt,
  }) async {
    final newRecord = TimeAttackRecord(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      nickname: nickname,
      highestNumber: highestNumber,
      totalScore: totalScore,
      achievedAt: achievedAt,
      playedAt: DateTime.now(),
    );

    final updated = List<TimeAttackRecord>.from(records)..add(newRecord);
    _sortRecords(updated);
    records.assignAll(updated);

    final prefs = await SharedPreferences.getInstance();
    final rawList = updated.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }

  void _sortRecords(List<TimeAttackRecord> list) {
    list.sort((a, b) {
      // 1. Highest number descending
      final cmpNum = b.highestNumber.compareTo(a.highestNumber);
      if (cmpNum != 0) return cmpNum;

      // 2. Total score descending
      final cmpScore = b.totalScore.compareTo(a.totalScore);
      if (cmpScore != 0) return cmpScore;

      // 3. Achieved time ascending (earlier achieved comes first)
      return a.achievedAt.compareTo(b.achievedAt);
    });
  }

  TimeAttackRecord? get personalBest {
    if (records.isEmpty) return null;
    return records.first;
  }

  int? getMyRank(String nickname) {
    final index = records.indexWhere((r) => r.nickname == nickname);
    return index >= 0 ? index + 1 : (records.isNotEmpty ? 1 : null);
  }
}
