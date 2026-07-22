import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';

import 'package:numbering/services/auth_service.dart';
import 'package:numbering/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:numbering/widgets/home_screen/home_components.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/screens/home/arcade_screen.dart';
import 'package:numbering/utils/mock_data.dart';

part 'home_screen_content_components.dart';

class LevelPack {
  const LevelPack(this.name, this.startLevel, this.endLevel);
  final String name;
  final int startLevel;
  final int endLevel;
  int get totalLevels => endLevel - startLevel + 1;
}

const levelPacks = [
  LevelPack('Seoul', 1, 20),
  LevelPack('Tokyo', 21, 40),
  LevelPack('New York', 41, 80),
  LevelPack('London', 81, 120),
  LevelPack('Paris', 121, 160),
];

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({
    super.key,
    required this.scoreController,
    required this.authService,
    required this.onSettingsTap,
    required this.onProfileTap,
    required this.onStartGame,
    required this.onOpenLevelList,
    required this.onStartDaily,
    required this.onStartDailyTest,
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onStartGame;
  final VoidCallback onOpenLevelList;
  final Future<void> Function() onStartDaily;
  final Future<void> Function() onStartDailyTest;
  final VoidCallback onRankingTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;
    final hPad = (mediaSize.width * 0.06).clamp(24.0, 40.0);
    
    final progress = Get.find<LevelProgressService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isLandscape ? 820 : 480),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _HomeHeader(
                    authService: authService,
                    onSettingsTap: onSettingsTap,
                    onProfileTap: onProfileTap,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 8,
                          child: _Top3RankingCard(
                            onShowRanking: onRankingTap,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Obx(() {
                            final current = progress.highestUnlockedLevel;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _SquareActionButton(
                                    title: '아케이드',
                                    actionLabel: 'LV.$current 도전하기',
                                    color: AppColors.blockLime,
                                    onTap: () {
                                      Get.to(
                                        () => ArcadeScreen(onStartGame: onStartGame),
                                        transition: Transition.zoom,
                                        duration: const Duration(milliseconds: 250),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _SquareActionButton(
                                    title: '오늘의 퍼즐',
                                    actionLabel: '도전',
                                    color: AppColors.blockCream,
                                    onTap: onStartDaily,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
