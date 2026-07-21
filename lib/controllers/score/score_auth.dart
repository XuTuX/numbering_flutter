part of 'package:hexor/controllers/score_controller.dart';

void _bindScoreAuthState(ScoreController controller) {
  final authService = Get.find<AuthService>();
  controller._authWorker?.dispose();
  void handleUserChange(dynamic user) {
    if (controller.isClosed) {
      return;
    }

    final generation = ++controller._authSyncGeneration;
    if (user != null) {
      final completer = Completer<void>();
      controller._loginSyncCompleter = completer;
      unawaited(
        _onUserLogin(
          controller,
          user.id,
          generation: generation,
          completer: completer,
        ),
      );
    } else {
      controller._loginSyncCompleter = null;
      unawaited(_onUserLogout(controller, generation: generation));
    }
  }

  controller._authWorker = ever(authService.user, handleUserChange);
  handleUserChange(authService.user.value);
}

Future<void> _onUserLogin(
  ScoreController controller,
  String userId, {
  required int generation,
  required Completer<void> completer,
}) async {
  if (!controller._isCurrentAuthSync(generation, userId)) {
    return;
  }
  controller.isSyncing.value = true;
  controller.hasNewHighScoreThisGame.value = false;

  try {
    final prefs = await SharedPreferences.getInstance();
    if (!controller._isCurrentAuthSync(generation, userId)) {
      return;
    }

    final userLocalScore = prefs.getInt('high_score_$userId') ?? 0;
    final legacyScore = prefs.getInt('high_score') ?? 0;
    final guestScore = prefs.getInt('high_score_guest') ?? 0;

    int bestLocalScore = max(userLocalScore, legacyScore);

    bestLocalScore = max(bestLocalScore, guestScore);
    await prefs.setInt('high_score_$userId', bestLocalScore);
    if (!controller._isCurrentAuthSync(generation, userId)) {
      return;
    }

    if (guestScore > 0) {
      debugPrint(
        '🔵 [ScoreController] Merging guest score ($guestScore) with user score ($userLocalScore) / legacy ($legacyScore) → $bestLocalScore',
      );
      await prefs.setInt('high_score_guest', 0);
      if (!controller._isCurrentAuthSync(generation, userId)) {
        return;
      }
    }

    if (legacyScore > 0) {
      await prefs.remove('high_score');
      if (!controller._isCurrentAuthSync(generation, userId)) {
        return;
      }
      debugPrint(
        '🔵 [ScoreController] Legacy score ($legacyScore) migrated and cleared.',
      );
    }

    controller.highscore.value = bestLocalScore;
    await _syncWithOnlineScore(
      controller,
      bestLocalScore,
      expectedUserId: userId,
      expectedAuthSyncGeneration: generation,
    );
  } catch (e) {
    debugPrint('🔴 [ScoreController] _onUserLogin failed: $e');
  } finally {
    if (controller._isCurrentAuthSync(generation, userId)) {
      controller.isSyncing.value = false;
    }
    if (!completer.isCompleted) {
      completer.complete();
    }
  }
}

Future<void> _onUserLogout(
  ScoreController controller, {
  required int generation,
}) async {
  if (!controller._isCurrentAuthSync(generation, null)) {
    return;
  }
  controller.isSyncing.value = true;
  controller.hasNewHighScoreThisGame.value = false;

  final prefs = await SharedPreferences.getInstance();
  final guestScore = prefs.getInt('high_score_guest') ?? 0;
  if (!controller._isCurrentAuthSync(generation, null)) {
    return;
  }
  controller.highscore.value = guestScore;

  debugPrint(
    '🔵 [ScoreController] Switched to guest mode. Guest score: $guestScore',
  );
  if (controller._isCurrentAuthSync(generation, null)) {
    controller.isSyncing.value = false;
  }
}
