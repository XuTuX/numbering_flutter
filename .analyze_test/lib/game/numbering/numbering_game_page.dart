import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';
import 'package:numbering/theme/app_spacing.dart';
import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/widgets/common/soft_icon_button.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/game/numbering/expression_engine.dart';
import 'package:numbering/game/numbering/level_catalog.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/game/numbering/numbering_models.dart';
import 'package:numbering/game/numbering/numbering_visuals.dart';


part 'views/level_selection_view.dart';
part 'views/level_play_view.dart';
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
  int? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    _progress = Get.find<LevelProgressService>();
    if (widget.session.isTutorialMode) {
      _selectedLevelId = 1;
    } else if (widget.session.startLevelId != null) {
      _selectedLevelId = widget.session.startLevelId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: _selectedLevelId == null
          ? _LevelSelectionView(
              key: const ValueKey('level-selection'),
              progress: _progress,
              accent: widget.game.visuals.accent,
              onExit: widget.callbacks.onExit,
              onSelect: _openLevel,
            )
          : _LevelPlayView(
              key: ValueKey('level-$_selectedLevelId'),
              level: LevelCatalog.byId(_selectedLevelId!),
              progress: _progress,
              accent: widget.game.visuals.accent,
              onShowLevels: () => setState(() => _selectedLevelId = null),
              onNext: (id) => setState(() => _selectedLevelId = id),
            ),
    );
  }

  void _openLevel(int levelId) {
    if (!_progress.isUnlocked(levelId)) return;
    unawaited(_progress.rememberLevel(levelId));
    setState(() => _selectedLevelId = levelId);
  }
}

