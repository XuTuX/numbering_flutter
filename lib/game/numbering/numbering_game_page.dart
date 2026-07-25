import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/level_catalog.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/game/numbering/numbering_visuals.dart';

import 'views/level_play_view.dart';
import 'views/time_attack_play_view.dart';

class NumberingGamePage extends StatefulWidget {
  const NumberingGamePage({
    super.key,
    required this.game,
    required this.session,
    required this.callbacks,
  });

  final NumberingGame game;
  final GameSessionConfig session;
  final GameCallbacks callbacks;

  @override
  State<NumberingGamePage> createState() => _NumberingGamePageState();
}

class _NumberingGamePageState extends State<NumberingGamePage> {
  late final LevelProgressService _progress;
  late int _selectedLevelId;

  @override
  void initState() {
    super.initState();
    _progress = Get.find<LevelProgressService>();
    if (widget.session.isTutorialMode) {
      _selectedLevelId = 1;
    } else if (widget.session.startLevelId != null) {
      _selectedLevelId = widget.session.startLevelId!;
    } else {
      _selectedLevelId = _progress.highestUnlockedLevel;
    }
    if (!widget.session.isTimeAttackMode) {
      unawaited(_progress.rememberLevel(_selectedLevelId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.isTimeAttackMode) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: TimeAttackPlayView(
          key: const ValueKey('time-attack-play'),
          session: widget.session,
          accent: widget.game.visuals.accent,
          onShowLevels: widget.callbacks.onExit,
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: LevelPlayView(
        key: ValueKey('level-$_selectedLevelId'),
        level: LevelCatalog.byId(_selectedLevelId),
        progress: _progress,
        accent: widget.game.visuals.accent,
        isTutorial: widget.session.isTutorialMode,
        onShowLevels: widget.callbacks.onExit,
        onNext: (id) {
          if (!_progress.isUnlocked(id)) return;
          unawaited(_progress.rememberLevel(id));
          setState(() => _selectedLevelId = id);
        },
      ),
    );
  }
}
