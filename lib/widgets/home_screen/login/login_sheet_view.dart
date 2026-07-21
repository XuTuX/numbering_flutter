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
        maxHeight: isLandscape ? Get.height * 0.9 : Get.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 왼쪽: 헤더
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _LoginSheetHeader(
                                      title: title,
                                      description: description,
                                    ),
                                    _LoginErrorBanner(
                                        errorMessage: errorMessage),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // 오른쪽: 버튼
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _SocialSignInRow(
                                      isLoading: isLoading,
                                      showAppleButton: showAppleButton,
                                      onGoogleTap: onGoogleTap,
                                      onAppleTap: onAppleTap,
                                    ),
                                    const SizedBox(height: 12),
                                    _LoginLegalLinks(
                                      onOpenTerms: onOpenTerms,
                                      onOpenPrivacy: onOpenPrivacy,
                                    ),
                                  ],
                                ),
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
                            _LoginErrorBanner(errorMessage: errorMessage),
                            const SizedBox(height: 28),
                            _SocialSignInRow(
                              isLoading: isLoading,
                              showAppleButton: showAppleButton,
                              onGoogleTap: onGoogleTap,
                              onAppleTap: onAppleTap,
                            ),
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
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(
              fontSize: 24,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: (errorMessage != null && errorMessage!.isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, top: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!.tr,
                        style: GoogleFonts.notoSans(
                          color: const Color(0xFFB91C1C),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
