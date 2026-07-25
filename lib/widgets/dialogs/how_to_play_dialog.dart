import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_typography.dart';
class HowToPlayDialog extends StatelessWidget {
  const HowToPlayDialog({
    super.key,
    this.onPlayTutorial,
  });

  final VoidCallback? onPlayTutorial;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '게임 방법'.tr,
                      style: AppTypography.title.copyWith(color: AppColors.ink),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: AppColors.ink),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shrinkWrap: true,
                children: [
                  _RuleItem(
                    icon: Icons.drag_indicator,
                    title: '등식 완성하기'.tr,
                    description:
                        '숫자 순서를 바꾸지 않고 등호(=)를 하나 넣어 양쪽 값이 같도록 수식을 완성하세요.'.tr,
                  ),
                  const SizedBox(height: 24),
                  _RuleItem(
                    icon: Icons.add_circle_outline,
                    title: '연산자 배치'.tr,
                    description:
                        '아래 연산자를 빈칸으로 끌어다 놓으세요. 잘못 놓은 연산자는 터치하면 지워집니다.'.tr,
                  ),
                  const SizedBox(height: 24),
                  _RuleItem(
                    icon: Icons.data_array,
                    title: '괄호 사용'.tr,
                    description:
                        '숫자를 2개 연속으로 터치하면 괄호가 씌워집니다. 다시 터치해서 해제할 수 있습니다.'.tr,
                  ),
                ],
              ),
            ),
            if (onPlayTutorial != null) ...[
              const Divider(height: 1, color: AppColors.borderLight),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  onPressed: onPlayTutorial,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '튜토리얼'.tr,
                    style: AppTypography.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.blockCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
