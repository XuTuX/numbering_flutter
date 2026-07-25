import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/screens/home/arcade_screen.dart';
import 'package:numbering/screens/hints/hint_store_screen.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_text_styles.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/services/hint_purchase_service.dart';
import 'package:numbering/services/time_attack_score_service.dart';
import 'package:numbering/utils/app_snackbar.dart';
import 'package:numbering/widgets/common/soft_card.dart';
import 'package:numbering/simulation_mode.dart';

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
  LevelPack('New York', 41, 60),
  LevelPack('Singapore', 61, 80),
  LevelPack('Sydney', 81, 100),
  LevelPack('London', 101, 120),
  LevelPack('Paris', 121, 140),
  LevelPack('Berlin', 141, 160),
  LevelPack('Cairo', 161, 180),
  LevelPack('Rio', 181, 200),
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
    required this.onStartTimeAttack,
    required this.onRankingTap,
    required this.onNicknameTap,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
  final VoidCallback onStartTimeAttack;
  final VoidCallback onRankingTap;
  final VoidCallback onNicknameTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final horizontalPadding = (mediaSize.width * 0.055).clamp(20.0, 36.0);

    return Scaffold(
      backgroundColor: _homeBackground,
      body: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                children: [
                  _HomeHeader(
                    onNicknameTap: onNicknameTap,
                    onSettingsTap: onSettingsTap,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _ArcadeCard(
                            onTap: () => _openArcade(onStartGame),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child:
                                    _TimeAttackCard(onTap: onStartTimeAttack),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: _RankingCard(onTap: onRankingTap),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
}
