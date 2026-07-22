import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/settings_service.dart';
import 'package:numbering/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/screens/home/home_screen_flows.dart';
import 'package:numbering/widgets/home_screen/login_sheet.dart';
import 'package:numbering/theme/app_colors.dart';

import 'widgets/settings_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Removed GridPatternPainter for clean Figma aesthetic
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Column(
                  children: [
                    const SettingsHeader(),
                    Expanded(
                      child: Obx(() {
                        final user = authService.user.value;
                        final savedNickname = authService.userNickname.value;
                        // 언어 변경 감지를 위해 locale 참조
                        settingsService.locale.value;
                        final nickname = savedNickname ?? '닉네임 설정 필요'.tr;
                        final email = user?.email ?? '';

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          children: [
                            if (user != null) ...[
                              SettingsProfileSection(
                                email: email,
                                nickname: nickname,
                                onEditNickname: () {
                                  _showEditNicknameDialog(
                                    context,
                                    savedNickname ?? '',
                                    (newNickname) async {
                                      return authService
                                          .updateNickname(newNickname);
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                            SettingsGeneralSection(
                              settingsService: settingsService,
                              onShowTutorial: () =>
                                  _showTutorialDialog(context),
                              onContact: _launchInstagram,
                            ),
                            const SizedBox(height: 24),
                            SettingsAccountSection(
                              isLoggedIn: user != null,
                              onLogout: () {
                                authService.signOut();
                                Get.back();
                              },
                              onLogin: () {
                                Get.bottomSheet(
                                  LoginSheet(
                                    onGoogleSignIn: () async {
                                      return authService.signInWithGoogle();
                                    },
                                    onAppleSignIn: () async {
                                      return authService.signInWithApple();
                                    },
                                    onLoginSuccess: Get.back,
                                  ),
                                  isScrollControlled: true,
                                );
                              },
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            return authService.isLoading.value
                ? Container(
                    color: AppColors.textPrimary.withValues(alpha: 0.26),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  void _showTutorialDialog(BuildContext context) {
    openGameScreen(const GameSessionConfig(mode: GameMode.tutorial));
  }

  void _showEditNicknameDialog(
    BuildContext context,
    String currentNickname,
    Future<String?> Function(String) onSave,
  ) {
    Get.dialog(
      EditNicknameDialog(
        currentNickname: currentNickname,
        onSave: onSave,
      ),
    );
  }

  Future<void> _launchInstagram() async {
    final url = Uri.parse(
      'https://www.instagram.com/neoreo_games?igsh=d3R6bnN3M3Y4ZzFu&utm_source=qr',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
