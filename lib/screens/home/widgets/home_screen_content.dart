import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:numbering/widgets/home_screen/background_painter.dart';
import 'package:numbering/widgets/home_screen/home_components.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_shadows.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({
    super.key,
    required this.scoreController,
    required this.authService,
    required this.onSettingsTap,
    required this.onStartGame,
    required this.onStartDaily,
    required this.onStartDailyTest,
    required this.onShowDailyRanking,
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
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
    final horizontalPadding = (mediaSize.width * 0.06).clamp(24.0, 40.0);
    final topPadding = isLandscape ? 20.0 : 24.0;
    final contentTopGap = isLandscape ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GridPatternPainter(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isLandscape ? 820 : 480,
                        ),
                        child: _HomeHeader(
                          authService: widget.authService,
                          onSettingsTap: widget.onSettingsTap,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: contentTopGap),
                  Expanded(
                    child: _HomeDashboardPage(
                      onStartGame: widget.onStartGame,
                    ),
                  ),
                  SizedBox(height: isLandscape ? 8 : 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboardPage extends StatelessWidget {
  const _HomeDashboardPage({
    required this.onStartGame,
  });

  final VoidCallback onStartGame;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;
    final sw = mediaSize.width;
    final sh = mediaSize.height;
    final horizontalPadding = (sw * 0.06).clamp(24.0, 40.0);
    final bottomPad = (sh * 0.025).clamp(16.0, 28.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            bottomPad,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLandscape ? sw * 0.95 : 480.0,
                minHeight: constraints.maxHeight,
              ),
              child: isLandscape
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: _LevelJourneyCard(
                                progress: Get.find<LevelProgressService>(),
                                onPressed: onStartGame,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 4,
                              child: _LevelStartButton(onPressed: onStartGame),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: _LevelJourneyCard(
                            progress: Get.find<LevelProgressService>(),
                            onPressed: onStartGame,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _LevelStartButton(onPressed: onStartGame),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.authService,
    required this.onSettingsTap,
  });

  final AuthService authService;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final sw = mediaSize.width;
    final titleFs = (sw * 0.035).clamp(18.0, 24.0);

    return Obx(() {
      final nickname = authService.userNickname.value?.trim();
      final hasNickname = nickname != null && nickname.isNotEmpty;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: hasNickname
                          ? () {
                              Get.dialog(
                                EditNicknameDialog(
                                  currentNickname: nickname,
                                  onSave: (newNickname) async {
                                    return authService
                                        .updateNickname(newNickname);
                                  },
                                ),
                                barrierDismissible: false,
                              );
                            }
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0095FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              hasNickname ? nickname : 'NUMBERING',
                              style: GoogleFonts.blackHanSans(
                                fontSize: titleFs,
                                color: charcoalBlack,
                                height: 1.0,
                                letterSpacing: 0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasNickname) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: charcoalBlack.withValues(alpha: 0.2),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                TopIconButton(
                  icon: Icons.settings_rounded,
                  onTap: onSettingsTap,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _LevelStartButton extends StatelessWidget {
  const _LevelStartButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final progress = Get.find<LevelProgressService>();
    return Obx(() {
      final current = progress.highestUnlockedLevel;
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0095FF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded, size: 24),
              const SizedBox(width: 8),
              Text(
                'LEVEL $current 시작하기',
                style: GoogleFonts.blackHanSans(
                  fontSize: 18,
                  letterSpacing: 0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _LevelJourneyCard extends StatelessWidget {
  const _LevelJourneyCard({required this.progress, required this.onPressed});

  final LevelProgressService progress;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final highest = progress.highestUnlockedLevel;
      final records = progress.progress.values;
      final cleared = records.where((record) => record.cleared).length;
      final ratio = cleared / 200;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppShadows.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceSecondary,
                    color: const Color(0xFF0095FF),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '$cleared / 200',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'LEVEL $highest',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
