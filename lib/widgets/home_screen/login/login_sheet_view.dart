part of 'package:numbering/widgets/home_screen/login_sheet.dart';

class _LoginSheetView extends StatelessWidget {
  const _LoginSheetView({
    required this.title,
    required this.description,
    required this.pendingProvider,
    required this.errorMessage,
    required this.showAppleButton,
    required this.onGoogleTap,
    required this.onAppleTap,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final String title;
  final String description;
  final String? pendingProvider;
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
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.card),
          topRight: Radius.circular(AppRadius.card),
        ),
        border: Border(
          top: BorderSide(color: AppColors.hairline),
          left: BorderSide(color: AppColors.hairline),
          right: BorderSide(color: AppColors.hairline),
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
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xxl,
                            0,
                            AppSpacing.xxl,
                            AppSpacing.md,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _SheetHandle(),
                              const SizedBox(height: AppSpacing.lg),
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
                                  const SizedBox(width: AppSpacing.xxl),
                                  SizedBox(
                                    width: 280,
                                    child: _SocialSignInButtons(
                                      pendingProvider: pendingProvider,
                                      showAppleButton: showAppleButton,
                                      onGoogleTap: onGoogleTap,
                                      onAppleTap: onAppleTap,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
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
                            const SizedBox(height: AppSpacing.xxl),
                            _LoginSheetHeader(
                              title: title,
                              description: description,
                            ),
                            _LoginStatusMessage(errorMessage: errorMessage),
                            const SizedBox(height: AppSpacing.xxl),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xxl,
                              ),
                              child: _SocialSignInButtons(
                                pendingProvider: pendingProvider,
                                showAppleButton: showAppleButton,
                                onGoogleTap: onGoogleTap,
                                onAppleTap: onAppleTap,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
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
            color: AppColors.hairline,
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
          Text(
            title,
            textAlign: compactLandscape ? TextAlign.left : TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: compactLandscape ? 22 : 24,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: compactLandscape ? TextAlign.left : TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
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
                style: const TextStyle(
                  color: AppColors.danger,
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
