import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../game/game_module.dart';
import '../game/game_registry.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(AudioService().pauseBGM());
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
                    maxWidth: MediaQuery.sizeOf(context).width >
                            MediaQuery.sizeOf(context).height
                        ? MediaQuery.sizeOf(context).width * 0.92
                        : 560,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: module.build(
                      context,
                      widget.sessionConfig,
                      GameCallbacks(
                        onScoreChanged: (_) {},
                        onFinished: (_) {},
                        onExit: _goHome,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goHome() => Get.off(() => const HomeScreen());
}
