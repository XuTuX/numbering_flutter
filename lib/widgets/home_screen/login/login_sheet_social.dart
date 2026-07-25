part of 'package:numbering/widgets/home_screen/login_sheet.dart';

class _SocialSignInButtons extends StatelessWidget {
  const _SocialSignInButtons({
    required this.pendingProvider,
    required this.showAppleButton,
    this.showLabels = false,
    this.stackButtons = false,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  final String? pendingProvider;
  final bool showAppleButton;
  final bool showLabels;
  final bool stackButtons;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  @override
  Widget build(BuildContext context) {
    final isLoading = pendingProvider != null;
    return Flex(
      direction: stackButtons ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GoogleSignInButton(
          key: const ValueKey('google-sign-in-button'),
          isBusy: pendingProvider == 'google',
          isEnabled: !isLoading,
          showLabel: showLabels,
          onTap: onGoogleTap,
        ),
        if (showAppleButton) ...[
          SizedBox(
            width: stackButtons ? 0 : AppSpacing.md,
            height: stackButtons ? AppSpacing.md : 0,
          ),
          _AppleSignInButton(
            key: const ValueKey('apple-sign-in-button'),
            isBusy: pendingProvider == 'apple',
            isEnabled: !isLoading,
            showLabel: showLabels,
            onTap: onAppleTap,
          ),
        ],
      ],
    );
  }
}
