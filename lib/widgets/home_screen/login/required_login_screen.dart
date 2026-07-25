part of 'package:numbering/widgets/home_screen/login_sheet.dart';

/// Hosts the required sign-in screen in its own overlay.
///
/// [GetMaterialApp.builder] is built above the app navigator, so replacing its
/// child directly also removes the navigator's overlay. Tooltips on the sign-in
/// buttons need an overlay ancestor.
class RequiredLoginOverlay extends StatelessWidget {
  const RequiredLoginOverlay({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  final Future<String?> Function() onGoogleSignIn;
  final Future<String?> Function() onAppleSignIn;

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => RequiredLoginScreen(
            onGoogleSignIn: onGoogleSignIn,
            onAppleSignIn: onAppleSignIn,
          ),
        ),
      ],
    );
  }
}

class RequiredLoginScreen extends StatefulWidget {
  const RequiredLoginScreen({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  final Future<String?> Function() onGoogleSignIn;
  final Future<String?> Function() onAppleSignIn;

  @override
  State<RequiredLoginScreen> createState() => _RequiredLoginScreenState();
}

class _RequiredLoginScreenState extends State<RequiredLoginScreen> {
  String? _pendingProvider;
  String? _errorMessage;

  bool get _isLoading => _pendingProvider != null;

  Future<void> _handleSignIn(
    String provider,
    Future<String?> Function() signInMethod,
  ) async {
    if (_isLoading) return;

    setState(() {
      _pendingProvider = provider;
      _errorMessage = null;
    });

    try {
      final error = await signInMethod();
      if (!mounted) return;

      setState(() {
        _pendingProvider = null;
        _errorMessage = error == 'cancelled' ? null : error;
      });
    } catch (error) {
      debugPrint('🔴 Required sign-in error: $error');
      if (!mounted) return;
      setState(() {
        _pendingProvider = null;
        _errorMessage = '로그인에 실패했어요. 다시 시도해 주세요.'.tr;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('🔴 Could not open URL: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackButtons = constraints.maxWidth < 540;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'NUMBERING',
                          style: AppTextStyles.hero.copyWith(fontSize: 44),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _LoginNumberMotion(),
                      const SizedBox(height: AppSpacing.xl),
                      _SocialSignInButtons(
                        pendingProvider: _pendingProvider,
                        showAppleButton: GetPlatform.isIOS,
                        showLabels: true,
                        stackButtons: stackButtons,
                        onGoogleTap: () => _handleSignIn(
                          'google',
                          widget.onGoogleSignIn,
                        ),
                        onAppleTap: () => _handleSignIn(
                          'apple',
                          widget.onAppleSignIn,
                        ),
                      ),
                      _LoginStatusMessage(
                        errorMessage: _errorMessage,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _LoginLegalLinks(
                        onOpenTerms: () =>
                            _openUrl(AppConfig.termsOfServiceUrl),
                        onOpenPrivacy: () =>
                            _openUrl(AppConfig.privacyPolicyUrl),
                        compactLandscape: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    super.key,
    required this.isBusy,
    required this.isEnabled,
    this.showLabel = false,
    required this.onTap,
  });

  final bool isBusy;
  final bool isEnabled;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = 'Google로 계속하기'.tr;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: !isEnabled && !isBusy ? 0.4 : 1,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.button),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isEnabled ? onTap : null,
              child: Container(
                width: showLabel ? 220 : 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: const Color(0xFF747775)),
                ),
                alignment: Alignment.center,
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1F1F1F),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/google_logo.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                          if (showLabel) ...[
                            const SizedBox(width: AppSpacing.md),
                            const Text(
                              'Google',
                              style: AppTextStyles.buttonLabel,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({
    super.key,
    required this.isBusy,
    required this.isEnabled,
    this.showLabel = false,
    required this.onTap,
  });

  final bool isBusy;
  final bool isEnabled;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = 'Apple로 계속하기'.tr;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: !isEnabled && !isBusy ? 0.4 : 1,
          child: Material(
            color: Colors.black,
            borderRadius: BorderRadius.circular(AppRadius.button),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isEnabled ? onTap : null,
              child: SizedBox(
                width: showLabel ? 220 : 52,
                height: 52,
                child: Center(
                  child: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 24,
                              child: CustomPaint(
                                painter: apple.AppleLogoPainter(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (showLabel) ...[
                              const SizedBox(width: AppSpacing.md),
                              const Text(
                                'Apple',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
