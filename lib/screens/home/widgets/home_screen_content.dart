import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/game/numbering/level_models.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';

import 'package:numbering/services/auth_service.dart';
import 'package:numbering/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:numbering/widgets/home_screen/background_painter.dart';
import 'package:numbering/widgets/home_screen/home_components.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/screens/home/level_list_screen.dart';

// ─── 레벨 팩 ────────────────────────────────────────────────────

part 'home_screen_content_components.dart';

class LevelPack {
  const LevelPack(this.name, this.startLevel, this.endLevel);
  final String name;
  final int startLevel;
  final int endLevel;
  int get totalLevels => endLevel - startLevel + 1;
}

const levelPacks = [
  LevelPack('Seoul', 1, 40),
  LevelPack('Tokyo', 41, 80),
  LevelPack('New York', 81, 120),
  LevelPack('London', 121, 160),
  LevelPack('Paris', 161, 200),
];

// ─── 홈 화면 ────────────────────────────────────────────────────

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({
    super.key,
    required this.scoreController,
    required this.authService,
    required this.onSettingsTap,
    required this.onStartGame,
    required this.onOpenLevelList,
    required this.onStartDaily,
    required this.onStartDailyTest,
    required this.onShowDailyRanking,
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
  final VoidCallback onOpenLevelList;
  final Future<void> Function() onStartDaily;
  final Future<void> Function() onStartDailyTest;
  final ValueChanged<String> onShowDailyRanking;
  final VoidCallback onRankingTap;

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;
    final hPad = (mediaSize.width * 0.06).clamp(24.0, 40.0);
    final topPad = isLandscape ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: GridPatternPainter()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: topPad),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isLandscape ? 820 : 480),
                        child: _HomeHeader(
                          authService: widget.authService,
                          onSettingsTap: widget.onSettingsTap,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _LevelPackPage(onStartGame: widget.onStartGame),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 팩 페이지 ──────────────────────────────────────────────────

