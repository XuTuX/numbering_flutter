import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/numbering/numbering_models.dart';
import '../game/numbering/numbering_visuals.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/common/soft_card.dart';

Future<NumberingGame?> showGameSelectionSheet() {
  return Get.bottomSheet<NumberingGame>(
    const GameSelectionSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class GameSelectionSheet extends StatelessWidget {
  const GameSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return SafeArea(
      child: isLandscape
          ? SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SoftCard(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                    child: _buildContent(),
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              child: SoftCard(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: _buildContent(),
              ),
            ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '게임 선택'.tr,
          style: GoogleFonts.blackHanSans(
            fontSize: 26,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '플레이할 NUMBERING 게임을 고르세요.'.tr,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ...NumberingGame.values.map((game) {
          final visuals = game.visuals;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InkWell(
              onTap: () => Get.back(result: game),
              borderRadius: BorderRadius.circular(AppRadius.large),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: visuals.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Icon(
                        visuals.icon,
                        color: visuals.accent,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title.tr,
                            style: GoogleFonts.blackHanSans(
                              fontSize: 19,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            game.description.tr,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: visuals.accentSoft,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '무제한 라운드'.tr,
                              style: AppTypography.tiny.copyWith(
                                color: visuals.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: visuals.accent,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
