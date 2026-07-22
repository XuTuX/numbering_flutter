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
    required this.onProfileTap,
    required this.onStartGame,
    required this.onStartDaily,
    required this.onRankingTap,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onStartGame;
  final Future<void> Function() onStartDaily;
  final VoidCallback onRankingTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final horizontalPadding = (mediaSize.width * 0.055).clamp(22.0, 48.0);
    final today = KstClock.nowInKst();
    final dateLabel = '${today.day} ${_monthLabel(today.month)}';

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
                    onProfileTap: onProfileTap,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final challenge = _ChallengeCard(
                          dateLabel: dateLabel,
                          onTap: onStartDaily,
                        );
                        final arcade = _ArcadeCard(
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

  String _monthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
