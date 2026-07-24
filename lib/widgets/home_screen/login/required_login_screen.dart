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
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSignIn(
    Future<String?> Function() signInMethod,
  ) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final error = await signInMethod();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error == 'cancelled' ? null : error;
      });
    } catch (error) {
      debugPrint('🔴 Required sign-in error: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
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
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 40 : 28,
              vertical: isLandscape ? 20 : 36,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/logo.png',
                    width: isLandscape ? 64 : 84,
                    height: isLandscape ? 64 : 84,
                  ),
                  SizedBox(height: isLandscape ? 14 : 24),
                  Text(
                    '로그인 후 시작할 수 있어요'.tr,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontSize: isLandscape ? 24 : 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'NUMBERING을 이용하려면 먼저 로그인해 주세요.'.tr,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: isLandscape ? 22 : 34),
                  _SocialSignInRow(
                    isLoading: _isLoading,
                    showAppleButton: GetPlatform.isIOS,
                    onGoogleTap: () => _handleSignIn(widget.onGoogleSignIn),
                    onAppleTap: () => _handleSignIn(widget.onAppleSignIn),
                  ),
                  _LoginStatusMessage(errorMessage: _errorMessage),
                  SizedBox(height: isLandscape ? 18 : 28),
                  _LoginLegalLinks(
                    onOpenTerms: () => _openUrl(AppConfig.termsOfServiceUrl),
                    onOpenPrivacy: () => _openUrl(AppConfig.privacyPolicyUrl),
                    compactLandscape: isLandscape,
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
