import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/screens/home/arcade_screen.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/utils/kst_clock.dart';

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
    required this.onSettingsTap,
    required this.onStartGame,
    required this.onStartDaily,
    required this.onRankingTap,
    this.currentLevel = 1,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
  final Future<void> Function() onStartDaily;
  final VoidCallback onRankingTap;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final horizontalPadding = (mediaSize.width * 0.055).clamp(22.0, 48.0);
    final today = KstClock.nowInKst();
    final challengeDate = _formatChallengeDate(today);

    return Scaffold(
      backgroundColor: _homeBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _HomeHeader(
                    onSettingsTap: onSettingsTap,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final challenge = _ChallengeCard(
                          dateLabel: challengeDate,
                          onTap: onStartDaily,
                        );
                        final currentPack = levelPacks.firstWhere(
                          (pack) =>
                              currentLevel >= pack.startLevel &&
                              currentLevel <= pack.endLevel,
                          orElse: () => levelPacks.first,
                        );
                        final arcade = _ArcadeCard(
                          roundLabel: currentPack.name.toUpperCase(),
                          onTap: () => _openArcade(onStartGame),
                        );
                        final ranking = _RankingCard(onTap: onRankingTap);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 7, child: challenge),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: arcade),
                                  const SizedBox(height: 14),
                                  Expanded(child: ranking),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openArcade(VoidCallback onStartGame) {
    Get.to(
      () => ArcadeScreen(onStartGame: onStartGame),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 220),
    );
  }

  String _formatChallengeDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')}';
}
