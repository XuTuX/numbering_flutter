part of 'package:numbering/widgets/dialogs/edit_nickname_dialog.dart';

class _EditNicknameDialogView extends StatelessWidget {
  const _EditNicknameDialogView({
    required this.title,
    required this.controller,
    required this.errorMessage,
    required this.isSaving,
    required this.isGenerating,
    required this.isInitialSetup,
    required this.onChanged,
    required this.onGenerateRandom,
    required this.onCancel,
    required this.onSave,
  });

  final String title;
  final TextEditingController controller;
  final String? errorMessage;
  final bool isSaving;
  final bool isGenerating;
  final bool isInitialSetup;
  final ValueChanged<String> onChanged;
  final VoidCallback onGenerateRandom;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    Widget dialogContent = Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.borderLight, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (!isInitialSetup)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.ink,
                          size: 22,
                        ),
                        onPressed: onCancel,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _NicknameInputField(
                  controller: controller,
                  isGenerating: isGenerating,
                  onChanged: onChanged,
                  onGenerateRandom: onGenerateRandom,
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      errorMessage!.tr,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _NicknameDialogActions(
                  isSaving: isSaving,
                  isInitialSetup: isInitialSetup,
                  onCancel: onCancel,
                  onSave: onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isInitialSetup) {
      return PopScope(
        canPop: false,
        child: dialogContent,
      );
    }

    return dialogContent;
  }
}

class _NicknameInputField extends StatelessWidget {
  const _NicknameInputField({
    required this.controller,
    required this.isGenerating,
    required this.onChanged,
    required this.onGenerateRandom,
  });

  final TextEditingController controller;
  final bool isGenerating;
  final ValueChanged<String> onChanged;
  final VoidCallback onGenerateRandom;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        cursorColor: AppColors.ink,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '새 닉네임'.tr,
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: isGenerating
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.ink,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.ink,
                    size: 22,
                  ),
                  tooltip: '랜덤 닉네임 생성'.tr,
                  onPressed: onGenerateRandom,
                  splashRadius: 20,
                ),
        ),
      ),
    );
  }
}

class _NicknameDialogActions extends StatelessWidget {
  const _NicknameDialogActions({
    required this.isSaving,
    required this.isInitialSetup,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final bool isInitialSetup;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isInitialSetup) ...[
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceSoft,
                  foregroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: Text(
                  '취소'.tr,
                  style: AppTypography.button.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      '저장'.tr,
                      style: AppTypography.button.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

