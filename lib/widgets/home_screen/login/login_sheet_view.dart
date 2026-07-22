part of 'package:numbering/widgets/home_screen/login_sheet.dart';

class _LoginSheetView extends StatelessWidget {
  const _LoginSheetView({
    required this.title,
    required this.description,
    required this.isLoading,
    required this.errorMessage,
    required this.showAppleButton,
    required this.onGoogleTap,
    required this.onAppleTap,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final String title;
  final String description;
  final bool isLoading;
  final String? errorMessage;
  final bool showAppleButton;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: isLandscape ? Get.height * 0.82 : Get.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? 600 : 450,
                  ),
                  child: isLandscape
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _SheetHandle(),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _LoginSheetHeader(
                                          title: title,
                                          description: description,
                                          compactLandscape: true,
                                        ),
                                        _LoginStatusMessage(
                                          errorMessage: errorMessage,
                                          compactLandscape: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                  _SocialSignInRow(
                                    isLoading: isLoading,
                                    showAppleButton: showAppleButton,
                                    onGoogleTap: onGoogleTap,
                                    onAppleTap: onAppleTap,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _LoginLegalLinks(
                                onOpenTerms: onOpenTerms,
                                onOpenPrivacy: onOpenPrivacy,
                                compactLandscape: true,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SheetHandle(),
                            const SizedBox(height: 32),
                            _LoginSheetHeader(
                              title: title,
                              description: description,
                            ),
                            _LoginStatusMessage(errorMessage: errorMessage),
                            const SizedBox(height: 28),
                            _SocialSignInRow(
                              isLoading: isLoading,
                              showAppleButton: showAppleButton,
                              onGoogleTap: onGoogleTap,
                              onAppleTap: onAppleTap,
                            ),
                            const SizedBox(height: 20),
                            _LoginLegalLinks(
                              onOpenTerms: onOpenTerms,
                              onOpenPrivacy: onOpenPrivacy,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _LoginSheetHeader extends StatelessWidget {
  const _LoginSheetHeader({
    required this.title,
    required this.description,
    this.compactLandscape = false,
  });

  final String title;
  final String description;
  final bool compactLandscape;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compactLandscape ? 0 : 32),
      child: Column(
        crossAxisAlignment: compactLandscape
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              textAlign: compactLandscape ? TextAlign.left : TextAlign.center,
              style: AppTypography.body.copyWith(
                fontSize: compactLandscape ? 22 : 24,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                compactLandscape ? Alignment.centerLeft : Alignment.center,
            child: Text(
              description,
              maxLines: 1,
              softWrap: false,
              textAlign: compactLandscape ? TextAlign.left : TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginStatusMessage extends StatelessWidget {
  const _LoginStatusMessage({
    required this.errorMessage,
    this.compactLandscape = false,
  });

  final String? errorMessage;
  final bool compactLandscape;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: (errorMessage != null && errorMessage!.isNotEmpty)
          ? Padding(
              padding: EdgeInsets.only(
                left: compactLandscape ? 0 : 32,
                right: compactLandscape ? 0 : 32,
                top: compactLandscape ? 10 : 12,
              ),
              child: Text(
                errorMessage!.tr,
                textAlign: compactLandscape ? TextAlign.left : TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
