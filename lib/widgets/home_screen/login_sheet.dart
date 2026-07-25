import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple;
import 'package:url_launcher/url_launcher.dart';

import 'package:numbering/config/app_config.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';
import 'package:numbering/theme/app_spacing.dart';
import 'package:numbering/theme/app_text_styles.dart';
import 'package:numbering/theme/app_typography.dart';

part 'login/login_sheet_view.dart';
part 'login/login_sheet_legal.dart';
part 'login/login_sheet_social.dart';
part 'login/required_login_screen.dart';

class LoginSheet extends StatefulWidget {
  const LoginSheet({
    super.key,
    this.isRankingAction = false,
    this.initialError,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    this.onLoginSuccess,
  });

  final bool isRankingAction;
  final String? initialError;
  final Future<String?> Function() onGoogleSignIn;
  final Future<String?> Function() onAppleSignIn;
  final VoidCallback? onLoginSuccess;

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  String? _pendingProvider;
  String? _errorMessage;

  bool get _isLoading => _pendingProvider != null;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialError;
  }

  Future<void> _handleSignIn(
    String provider,
    Future<String?> Function() signInMethod,
  ) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _pendingProvider = provider;
      _errorMessage = null;
    });

    try {
      final error = await signInMethod();

      if (!mounted) {
        return;
      }

      if (error == null) {
        Get.back();
        widget.onLoginSuccess?.call();
        return;
      }

      if (error == 'cancelled') {
        setState(() {
          _pendingProvider = null;
        });
        return;
      }

      setState(() {
        _pendingProvider = null;
        _errorMessage = error;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingProvider = null;
          _errorMessage = '로그인에 실패했어요. 다시 시도해 주세요.'.tr;
        });
      }
      debugPrint('🔴 Sign-in error: $e');
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('🔴 Could not open URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginRequiredMessage = '로그인이 필요합니다.'.tr;
    final visibleErrorMessage =
        _errorMessage == '로그인이 필요합니다.' || _errorMessage == loginRequiredMessage
            ? null
            : _errorMessage;

    return _LoginSheetView(
      title: 'NUMBERING',
      description: '로그인하여 플레이해보세요'.tr,
      pendingProvider: _pendingProvider,
      errorMessage: visibleErrorMessage,
      showAppleButton: GetPlatform.isIOS,
      onGoogleTap: () => _handleSignIn('google', widget.onGoogleSignIn),
      onAppleTap: () => _handleSignIn('apple', widget.onAppleSignIn),
      onOpenTerms: () => _openUrl(AppConfig.termsOfServiceUrl),
      onOpenPrivacy: () => _openUrl(AppConfig.privacyPolicyUrl),
    );
  }
}
