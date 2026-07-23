import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/screens/home/arcade_screen.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/utils/kst_clock.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/services/numbering_score_service.dart';

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

LevelPack levelPackFor(int levelId) => levelPacks.firstWhere(
      (pack) => levelId >= pack.startLevel && levelId <= pack.endLevel,
      orElse: () => levelId < levelPacks.first.startLevel
          ? levelPacks.first
          : levelPacks.last,
    );

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({
    super.key,
    required this.onSettingsTap,
    required this.onStartGame,
    required this.onStartDaily,
    required this.onRankingTap,
    this.nickname,
    this.onNicknameTap,
    this.currentLevel = 1,
    this.dailyState = DailyChallengeUiState.loading,
    this.dailyDateKey,
    this.dailyScore,
    this.allTimeRank,
    this.allTimeBest,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
  final Future<void> Function() onStartDaily;
  final VoidCallback onRankingTap;
  final String? nickname;
  final VoidCallback? onNicknameTap;
  final int currentLevel;
  final DailyChallengeUiState dailyState;
  final String? dailyDateKey;
  final int? dailyScore;
  final int? allTimeRank;
  final int? allTimeBest;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final horizontalPadding = (mediaSize.width * 0.055).clamp(22.0, 48.0);
    final today = KstClock.nowInKst();
    final challengeDate = dailyDateKey == null
        ? _formatChallengeDate(today)
        : KstClock.compactDateLabel(dailyDateKey!);

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
                    nickname: nickname,
                    onNicknameTap: onNicknameTap,
                    onSettingsTap: onSettingsTap,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final challenge = _ChallengeCard(
                          dateLabel: challengeDate,
                          onTap: onStartDaily,
                          state: dailyState,
                          score: dailyScore,
                        );
                        final currentPack = levelPackFor(currentLevel);
                        final arcade = _ArcadeCard(
                          roundLabel: currentPack.name.toUpperCase(),
                          onTap: () => _openArcade(onStartGame),
                        );
                        final ranking = _RankingCard(
                          onTap: onRankingTap,
                          rank: allTimeRank,
                          bestScore: allTimeBest,
                        );

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
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 280),
    );
  }

  String _formatChallengeDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')}';
}
