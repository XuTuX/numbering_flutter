part of 'package:numbering/widgets/home_screen/login_sheet.dart';

class _LoginLegalLinks extends StatelessWidget {
  const _LoginLegalLinks({
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    this.compactLandscape = false,
  });

  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final bool compactLandscape;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: compactLandscape ? AppSpacing.xs : AppSpacing.xxl,
        top: compactLandscape ? 0 : AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegalLink(
            label: '이용약관'.tr,
            onTap: onOpenTerms,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '·',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          _LegalLink(
            label: '개인정보 처리방침'.tr,
            onTap: onOpenPrivacy,
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            label.tr,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
