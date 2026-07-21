import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numbering/services/auth_service.dart';

class DailyPuzzleController extends GetxController {
  // A map of dateKey to a list of top scores
  final RxMap<String, List<int>> dailyTopScores = <String, List<int>>{}.obs;

  String? get _currentUserId => Get.find<AuthService>().user.value?.id;
  String get _storageKey => 'daily_top_scores_${_currentUserId ?? "guest"}';

  @override
  void onInit() {
    super.onInit();
    _loadScores();
    ever(Get.find<AuthService>().user, (_) => _loadScores());
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final map = <String, List<int>>{};
        for (final entry in decoded.entries) {
          map[entry.key] = List<int>.from(entry.value);
        }
        dailyTopScores.value = map;
      } catch (e) {
        debugPrint('Failed to load daily scores: $e');
      }
    } else {
      dailyTopScores.clear();
    }
  }

  Future<void> _saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(dailyTopScores));
  }

  void submitDailyScore(String dateKey, int newScore) {
    if (!dailyTopScores.containsKey(dateKey)) {
      dailyTopScores[dateKey] = [];
    }
    
    final scores = List<int>.from(dailyTopScores[dateKey]!);
    if (!scores.contains(newScore)) {
      scores.add(newScore);
      scores.sort((a, b) => b.compareTo(a)); // Descending
      if (scores.length > 30) {
        scores.removeLast();
      }
      dailyTopScores[dateKey] = scores;
      _saveScores();
    }
  }

  int getDailyTotalScore(String dateKey) {
    final scores = dailyTopScores[dateKey] ?? [];
    return scores.fold(0, (sum, score) => sum + score);
  }
}
