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
                final isWide = constraints.maxWidth >= 860;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: isWide
                          ? const EdgeInsets.fromLTRB(36, 28, 36, 0)
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
                                    40,
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
                              width: 260,
                              child: Column(
                                children: [
                                  const SettingsHeader(isWide: true),
                                  SettingsSidebar(
                                    selectedSection: selectedSection,
                                    showProfile: user != null,
                                    onSectionSelected: _selectSection,
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(
                              width: 64,
                              thickness: 1,
                              color: AppColors.borderLight,
                            ),
                            Expanded(
                              child: ListView(
                                key: const ValueKey('settings-content'),
                                padding:
                                    const EdgeInsets.fromLTRB(0, 38, 8, 48),
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
  }) {
    final sectionGap = isWide ? 32.0 : 24.0;

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
        ),
      ),
    ];
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
