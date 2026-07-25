part of 'package:numbering/widgets/home_screen/login_sheet.dart';

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
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final horizontalPadding = (size.width * 0.055).clamp(20.0, 36.0);

    final authPanel = _LoginAuthPanel(
      pendingProvider: _pendingProvider,
      errorMessage: _errorMessage,
      showAppleButton: GetPlatform.isIOS,
      fillHeight: isLandscape,
      onGoogleTap: () => _handleSignIn('google', widget.onGoogleSignIn),
      onAppleTap: () => _handleSignIn('apple', widget.onAppleSignIn),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LoginWordmark(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: isLandscape
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(child: _LoginBrandCard()),
                              const SizedBox(width: 14),
                              SizedBox(width: 300, child: authPanel),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(child: _LoginBrandCard()),
                              const SizedBox(height: 14),
                              authPanel,
                            ],
                          ),
                  ),
                  const SizedBox(height: 6),
                  _LoginLegalLinks(
                    onOpenTerms: () => _openUrl(AppConfig.termsOfServiceUrl),
                    onOpenPrivacy: () => _openUrl(AppConfig.privacyPolicyUrl),
                    compactLandscape: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginWordmark extends StatelessWidget {
  const _LoginWordmark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'NUMBERING',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _LoginBrandCard extends StatelessWidget {
  const _LoginBrandCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blockLilac,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomLeft,
              child: Text(
                '로그인 후 시작할 수 있어요'.tr,
                style: AppTextStyles.hero.copyWith(height: 1.1),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'NUMBERING을 이용하려면 먼저 로그인해 주세요.'.tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginAuthPanel extends StatelessWidget {
  const _LoginAuthPanel({
    required this.pendingProvider,
    required this.errorMessage,
    required this.showAppleButton,
    required this.fillHeight,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  final String? pendingProvider;
  final String? errorMessage;
  final bool showAppleButton;
  final bool fillHeight;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  @override
  Widget build(BuildContext context) {
    final isLoading = pendingProvider != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoginProviderButton(
            key: const ValueKey('google-sign-in-button'),
            label: 'Google로 계속하기'.tr,
            icon: Image.asset(
              'assets/icons/google_logo.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            foregroundColor: AppColors.ink,
            backgroundColor: AppColors.surfaceSoft,
            bordered: true,
            isBusy: pendingProvider == 'google',
            onTap: isLoading ? null : onGoogleTap,
          ),
          if (showAppleButton) ...[
            const SizedBox(height: 10),
            _LoginProviderButton(
              key: const ValueKey('apple-sign-in-button'),
              label: 'Apple로 계속하기'.tr,
              icon: const Icon(
                Icons.apple,
                size: 22,
                color: AppColors.onPrimary,
              ),
              foregroundColor: AppColors.onPrimary,
              backgroundColor: AppColors.ink,
              bordered: false,
              isBusy: pendingProvider == 'apple',
              onTap: isLoading ? null : onAppleTap,
            ),
          ],
          _LoginStatusMessage(
            errorMessage: errorMessage,
            compactLandscape: true,
          ),
        ],
      ),
    );
  }
}

class _LoginProviderButton extends StatelessWidget {
  const _LoginProviderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.bordered,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final bool bordered;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: onTap == null && !isBusy ? 0.4 : 1,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: bordered
                  ? Border.all(color: AppColors.hairline)
                  : const Border.fromBorderSide(BorderSide.none),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Center(
                    child: isBusy
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: foregroundColor,
                            ),
                          )
                        : icon,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button.copyWith(
                      fontSize: 15,
                      letterSpacing: -0.2,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
