import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';
import 'package:numbering/theme/app_spacing.dart';
import 'package:numbering/widgets/common/soft_icon_button.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/game/numbering/level_catalog.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/controllers/daily_puzzle_controller.dart';
import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/game/numbering/numbering_random.dart';
import 'package:numbering/game/numbering/numbering_visuals.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/services/numbering_score_service.dart';
import 'package:numbering/utils/app_snackbar.dart';
import 'package:numbering/screens/ranking/ranking_screen.dart';
import 'package:numbering/screens/hints/hint_store_screen.dart';
import 'package:numbering/services/hint_purchase_service.dart';

part 'views/level_play_view.dart';
part 'views/daily_play_view.dart';
part 'widgets/formula_editor.dart';
part 'widgets/formula_editor_components.dart';

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
    if (!widget.session.isDailyMode) {
      unawaited(_progress.rememberLevel(_selectedLevelId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.isDailyMode) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: _DailyPlayView(
          key: const ValueKey('daily-puzzle'),
          session: widget.session,
          accent: widget.game.visuals.accent,
          onShowLevels: widget.callbacks.onExit,
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: _LevelPlayView(
        key: ValueKey('level-$_selectedLevelId'),
        level: LevelCatalog.byId(_selectedLevelId),
        progress: _progress,
        accent: widget.game.visuals.accent,
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
