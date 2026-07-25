import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/settings_service.dart';
import 'package:numbering/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:numbering/widgets/dialogs/how_to_play_dialog.dart';
import 'package:numbering/game/game_module.dart';
import 'package:numbering/screens/home/home_screen_flows.dart';
import 'package:numbering/widgets/home_screen/login_sheet.dart';
import 'package:numbering/widgets/dialogs/animated_game_dialog.dart';
import 'package:numbering/utils/app_snackbar.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_typography.dart';

import 'widgets/settings_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileSectionKey = GlobalKey();
  final _generalSectionKey = GlobalKey();
  final _accountSectionKey = GlobalKey();

  SettingsSection _selectedSection = SettingsSection.profile;

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;
                final isWide = constraints.maxWidth >= 600 ||
                    (isLandscape && constraints.maxWidth >= 520);
                final isCompactLandscape =
                    isLandscape && constraints.maxHeight < 500;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: isWide
                          ? (isCompactLandscape
                              ? const EdgeInsets.fromLTRB(20, 8, 20, 0)
                              : const EdgeInsets.fromLTRB(36, 20, 36, 0))
                          : EdgeInsets.zero,
                      child: Obx(() {
                        final user = widget.authService.user.value;
                        final savedNickname =
                            widget.authService.userNickname.value;
                        // Rebuild translated labels as soon as locale changes.
                        settingsService.locale.value;

                        final sections = _buildSections(
                          context: context,
                          settingsService: settingsService,
                          email: user?.email ?? '',
                          nickname: savedNickname ?? '닉네임 설정 필요'.tr,
                          savedNickname: savedNickname,
                          isLoggedIn: user != null,
                          isWide: isWide,
                          isCompactLandscape: isCompactLandscape,
                        );

                        if (!isWide) {
                          return Column(
                            children: [
                              const SettingsHeader(),
                              Expanded(
                                child: ListView(
                                  key: const ValueKey('settings-content'),
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    24,
                                  ),
                                  children: sections,
                                ),
                              ),
                            ],
                          );
                        }

                        final selectedSection = user == null &&
                                _selectedSection == SettingsSection.profile
                            ? SettingsSection.general
                            : _selectedSection;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: isCompactLandscape ? 190 : 250,
                              child: Column(
                                children: [
                                  SettingsHeader(
                                    isWide: true,
                                    isCompactLandscape: isCompactLandscape,
                                  ),
                                  SettingsSidebar(
                                    selectedSection: selectedSection,
                                    showProfile: user != null,
                                    onSectionSelected: _selectSection,
                                    isCompactLandscape: isCompactLandscape,
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              width: isCompactLandscape ? 28 : 56,
                              thickness: 1,
                              color: AppColors.borderLight,
                            ),
                            Expanded(
                              child: ListView(
                                key: const ValueKey('settings-content'),
                                padding: isCompactLandscape
                                    ? const EdgeInsets.fromLTRB(0, 8, 8, 24)
                                    : const EdgeInsets.fromLTRB(0, 24, 8, 48),
                                children: sections,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
          Obx(() {
            return widget.authService.isLoading.value
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

  List<Widget> _buildSections({
    required BuildContext context,
    required SettingsService settingsService,
    required String email,
    required String nickname,
    required String? savedNickname,
    required bool isLoggedIn,
    required bool isWide,
    bool isCompactLandscape = false,
  }) {
    final sectionGap = isCompactLandscape ? 16.0 : (isWide ? 28.0 : 20.0);

    return [
      if (isLoggedIn) ...[
        KeyedSubtree(
          key: _profileSectionKey,
          child: SettingsProfileSection(
            email: email,
            nickname: nickname,
            onEditNickname: () {
              _showEditNicknameDialog(
                context,
                savedNickname ?? '',
                widget.authService.updateNickname,
              );
            },
          ),
        ),
        SizedBox(height: sectionGap),
      ],
      KeyedSubtree(
        key: _generalSectionKey,
        child: SettingsGeneralSection(
          settingsService: settingsService,
          onShowTutorial: () => _showTutorialDialog(context),
          onContact: _launchInstagram,
        ),
      ),
      SizedBox(height: sectionGap),
      KeyedSubtree(
        key: _accountSectionKey,
        child: SettingsAccountSection(
          isLoggedIn: isLoggedIn,
          onLogout: () {
            widget.authService.signOut();
            Get.back();
          },
          onLogin: () {
            Get.bottomSheet(
              LoginSheet(
                onGoogleSignIn: widget.authService.signInWithGoogle,
                onAppleSignIn: widget.authService.signInWithApple,
                onLoginSuccess: Get.back,
              ),
              isScrollControlled: true,
            );
          },
          onDeleteAccount: _confirmDeleteAccount,
        ),
      ),
    ];
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await Get.dialog<bool>(
      AnimatedGameDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 36,
              color: AppColors.danger,
            ),
            const SizedBox(height: 14),
            Text(
              'NEOREO GAMES 계정을\n삭제할까요?'.tr,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'NEOREO GAMES와 관련된 계정인\nOverlap, Fill Your Area, NUMBERING 등의\n'
                      '게임 데이터가 모두 삭제됩니다.\n\n이 작업은 되돌릴 수 없습니다.'
                  .tr,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: Text('취소'.tr),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text('삭제'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmed != true) return;

    final error = await widget.authService.deleteAccount();

    if (error != null) {
      showAppSnackBar(
        title: '삭제 실패'.tr,
        message: error,
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    // The auth gate in main.dart swaps to the login screen on the next frame,
    // which unmounts this screen. Pop the stale settings route only while it is
    // still mounted, but report the result through the global overlay either
    // way so the confirmation never depends on that frame timing.
    if (mounted) Get.back();
    showAppSnackBar(
      title: '삭제 완료'.tr,
      message: 'NEOREO GAMES 계정이 삭제되었습니다.'.tr,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  void _selectSection(SettingsSection section) {
    setState(() => _selectedSection = section);

    final key = switch (section) {
      SettingsSection.profile => _profileSectionKey,
      SettingsSection.general => _generalSectionKey,
      SettingsSection.account => _accountSectionKey,
    };
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );
  }

  void _showTutorialDialog(BuildContext context) {
    Get.dialog(
      HowToPlayDialog(
        onPlayTutorial: () {
          Get.back();
          openGameScreen(const GameSessionConfig(mode: GameMode.tutorial));
        },
      ),
    );
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
