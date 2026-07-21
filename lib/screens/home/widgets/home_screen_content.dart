import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:numbering/widgets/home_screen/background_painter.dart';
import 'package:numbering/widgets/home_screen/home_components.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_shadows.dart';

import 'daily_ranking_calendar_page.dart';

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
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openTab(int index) {
    if (!_pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openTab(index);
        }
      });
      return;
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _HomeHeader(
                    authService: widget.authService,
                    activeIndex: _pageIndex,
                    onSettingsTap: widget.onSettingsTap,
                    onTabTap: _openTab,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _pageIndex = index);
                    },
                    children: [
                      _HomeDashboardPage(
                        scoreController: widget.scoreController,
                        authService: widget.authService,
                        onStartGame: widget.onStartGame,
                        onRankingTap: widget.onRankingTap,
                      ),
                      DailyRankingCalendarPage(
                        authService: widget.authService,
                        isVisible: _pageIndex == 1,
                        onStartDaily: widget.onStartDaily,
                        onStartDailyTest: widget.onStartDailyTest,
                        onShowDailyRanking: widget.onShowDailyRanking,
                        onRankingTap: widget.onRankingTap,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboardPage extends StatelessWidget {
  const _HomeDashboardPage({
    required this.scoreController,
    required this.authService,
    required this.onStartGame,
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final VoidCallback onStartGame;
  final VoidCallback onRankingTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;
    final sw = mediaSize.width;
    final sh = mediaSize.height;
    final horizontalPadding = (sw * 0.04).clamp(16.0, 40.0);
    final bottomPad = (sh * 0.02).clamp(8.0, 20.0);

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
                        child: Column(
                          children: [
                            Expanded(
                              child: WeeklyRankingPreview(
                                isAllTime: false,
                                limit: 5,
                                onViewAll: onRankingTap,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 64,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: ScoreDisplay(
                                      scoreController: scoreController,
                                      authService: authService,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 6,
                                    child: Center(
                                      child: _AnimatedPlayButton(
                                        onPressed: onStartGame,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          ScoreDisplay(
                            scoreController: scoreController,
                            authService: authService,
                          ),
                          const SizedBox(height: 12),
                          WeeklyRankingPreview(
                            isAllTime: false,
                            limit: 5,
                            onViewAll: onRankingTap,
                          ),
                          const SizedBox(height: 16),
                          _AnimatedPlayButton(onPressed: onStartGame),
                        ],
                      ),
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
    required this.activeIndex,
    required this.onSettingsTap,
    required this.onTabTap,
  });

  final AuthService authService;
  final int activeIndex;
  final VoidCallback onSettingsTap;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final titleFs = (sw * 0.035).clamp(18.0, 24.0);

    return Obx(() {
      final nickname = authService.userNickname.value?.trim();
      final hasNickname = nickname != null && nickname.isNotEmpty;

      return SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: sw * 0.26),
                child: GestureDetector(
                  onTap: hasNickname
                      ? () {
                          Get.dialog(
                            EditNicknameDialog(
                              currentNickname: nickname,
                              onSave: (newNickname) async {
                                return authService.updateNickname(newNickname);
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
            _HomePageTabs(activeIndex: activeIndex, onTap: onTabTap),
            Align(
              alignment: Alignment.centerRight,
              child: TopIconButton(
                icon: Icons.settings_rounded,
                onTap: onSettingsTap,
              ),
            ),
          ],
        ),
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

class _HomePageTabs extends StatelessWidget {
  const _HomePageTabs({
    required this.activeIndex,
    required this.onTap,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ms = MediaQuery.sizeOf(context);
    final maxWidth = (ms.width * 0.37).clamp(300.0, 390.0);
    const tabHeight = 38.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.smallShadow,
          ),
          child: Row(
            children: List.generate(2, (index) {
              final labels = ['플레이'.tr, '오늘의 퍼즐'.tr];
              final icons = [
                Icons.sports_esports_rounded,
                Icons.auto_awesome_rounded,
              ];
              final activeColors = [
                const Color(0xFF0095FF),
                const Color(0xFFF59E0B),
              ];
              final isActive = activeIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: tabHeight,
                    decoration: BoxDecoration(
                      color:
                          isActive ? activeColors[index] : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[index],
                          size: 17,
                          color: isActive
                              ? Colors.white
                              : charcoalBlack.withValues(alpha: 0.32),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          labels[index],
                          style: GoogleFonts.blackHanSans(
                            fontSize: 14,
                            color: isActive
                                ? Colors.white
                                : charcoalBlack.withValues(alpha: 0.32),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
