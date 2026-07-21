import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constant.dart';
import '../controllers/score_controller.dart';
import '../game/game_module.dart';
import '../game/game_registry.dart';
import '../game/numbering/numbering_models.dart';
import '../game/numbering/numbering_visuals.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/common/soft_card.dart';
import '../widgets/home_screen/background_painter.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.sessionConfig = const GameSessionConfig.normal(),
  });

  final GameSessionConfig sessionConfig;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final ScoreController _scoreController;
  GameResult? _result;
  int _sessionKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scoreController = Get.find<ScoreController>()..resetScore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(AudioService().startBGM());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(AudioService().resumeBGMIfNeeded());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(AudioService().pauseBGM());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = GameRegistry.byId(widget.sessionConfig.gameId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: GridPatternPainter()),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).shortestSide >= 600
                        ? 680
                        : 480,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: KeyedSubtree(
                      key: ValueKey(_sessionKey),
                      child: module.build(
                        context,
                        widget.sessionConfig,
                        GameCallbacks(
                          onScoreChanged: _setScore,
                          onFinished: _finishGame,
                          onExit: _goHome,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_result case final result?)
              Positioned.fill(
                child: _ResultOverlay(
                  game: NumberingGame.fromId(widget.sessionConfig.gameId),
                  result: result,
                  bestScore: _scoreController.highscore.value,
                  onReplay: _restart,
                  onHome: _goHome,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _setScore(int score) {
    _scoreController.score.value = score;
    _scoreController.checkHighScore();
  }

  void _finishGame(GameResult result) {
    _setScore(result.score);
    setState(() => _result = result);
  }

  void _restart() {
    _scoreController.resetScore();
    setState(() {
      _result = null;
      _sessionKey += 1;
    });
  }

  void _goHome() {
    Get.off(() => const HomeScreen());
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.game,
    required this.result,
    required this.bestScore,
    required this.onReplay,
    required this.onHome,
  });

  final NumberingGame game;
  final GameResult result;
  final int bestScore;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final visuals = game.visuals;
    return ColoredBox(
      color: charcoalBlack.withValues(alpha: 0.42),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SizedBox(
                width: double.infinity,
                child: SoftCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: visuals.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.large),
                        ),
                        child: Icon(
                          visuals.icon,
                          color: visuals.accent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '플레이 완료'.tr,
                        style: GoogleFonts.blackHanSans(
                          fontSize: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        game.title.tr,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        '해결한 문제'.tr,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${result.score}',
                        style: GoogleFonts.blackHanSans(
                          fontSize: 52,
                          color: visuals.accent,
                        ),
                      ),
                      Text(
                        '${'최고 기록'.tr} $bestScore',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (result.detailLabel != null &&
                          result.detailValue != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${result.detailLabel} ${result.detailValue}',
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onHome,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: Text('홈'.tr),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: FilledButton(
                              onPressed: onReplay,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: AppColors.blue,
                              ),
                              child: Text('다시 시작하기'.tr),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
