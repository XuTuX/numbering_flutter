import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:numbering/services/auth_service.dart';

import 'score/score_merge_service.dart';

part 'score/score_auth.dart';
part 'score/score_gameplay.dart';
part 'score/score_persistence.dart';

class ScoreController extends GetxController {
  final score = 0.obs;
  final highscore = 0.obs;
  final isSyncing = false.obs;
  final hasNewHighScoreThisGame = false.obs;

  final combo = 0.obs;

  final ScoreMergeService _mergeService = const ScoreMergeService();

  Completer<void>? _loginSyncCompleter;
  Worker? _authWorker;
  int _authSyncGeneration = 0;

  String? get _currentUserId => Get.find<AuthService>().user.value?.id;
  String get _scoreKey => _mergeService.storageKeyFor(_currentUserId);

  bool _isCurrentAuthSync(int generation, String? userId) {
    return !isClosed &&
        generation == _authSyncGeneration &&
        _currentUserId == userId;
  }

  @override
  void onInit() {
    super.onInit();
    _loadHighScore(this);
    _bindScoreAuthState(this);
  }

  @override
  void onClose() {
    _authSyncGeneration++;
    final completer = _loginSyncCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _authWorker?.dispose();
    super.onClose();
  }

  Future<void> waitForLoginSync() async {
    while (true) {
      final completer = _loginSyncCompleter;
      if (completer == null || completer.isCompleted) {
        return;
      }
      await completer.future;
      if (identical(completer, _loginSyncCompleter)) {
        return;
      }
    }
  }

  void registerPuzzleMatch({
    required int points,
    required int comboDepth,
  }) {
    _registerPuzzleMatch(
      this,
      points: points,
      comboDepth: comboDepth,
    );
  }

  void resetScore() {
    _resetScoreState(this);
  }

  void checkHighScore() {
    _checkHighScore(this);
  }
}
