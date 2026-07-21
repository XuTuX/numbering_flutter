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
import 'package:numbering/theme/app_typography.dart';

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
                              child:
                                  _AnimatedPlayButton(onPressed: onStartGame),
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
                        _AnimatedPlayButton(onPressed: onStartGame),
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

class _AnimatedPlayButton extends StatefulWidget {
  const _AnimatedPlayButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<_AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<_AnimatedPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ms = MediaQuery.sizeOf(context);
    final isLandscape = ms.width > ms.height;
    final btnH = isLandscape
        ? (ms.height * 0.12).clamp(48.0, 80.0)
        : (ms.height * 0.078).clamp(52.0, 72.0);
    final btnFs = isLandscape
        ? (ms.width * 0.025).clamp(16.0, 26.0)
        : (ms.width * 0.06).clamp(18.0, 26.0);
    final br = (ms.width * 0.04).clamp(18.0, 28.0);

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        height: btnH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(br),
          boxShadow: AppShadows.buttonShadow,
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0095FF),
            foregroundColor: Colors.white,
            elevation: 0,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(br),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded, size: 26),
              const SizedBox(width: 6),
              Text(
                '게임 시작'.tr,
                style: GoogleFonts.blackHanSans(
                  fontSize: btnFs,
                  letterSpacing: 0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      final perfect = records.where((record) => record.perfect).length;
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Color(0xFF0095FF),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '나의 레벨 여정',
                            style: GoogleFonts.blackHanSans(fontSize: 22),
                          ),
                          Text(
                            '다음 도전 · LEVEL $highest',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF0095FF),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                const SizedBox(height: 28),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceSecondary,
                    color: const Color(0xFF0095FF),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '$cleared / 200 클리어',
                      style: AppTypography.label,
                    ),
                    const Spacer(),
                    const Icon(Icons.auto_awesome_rounded,
                        size: 17, color: AppColors.scoreOrange),
                    const SizedBox(width: 5),
                    Text('PERFECT $perfect', style: AppTypography.label),
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
