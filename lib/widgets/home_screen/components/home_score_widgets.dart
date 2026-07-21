import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_models.dart';
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/widgets/home_screen/nickname_sticker_card.dart';

class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  final ScoreController scoreController;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final score = scoreController.highscore.value;
      final tier =
          authService.user.value == null ? null : SeasonTier.fromScore(score);
      final isLoading =
          authService.isLoading.value || scoreController.isSyncing.value;

      return NicknameStickerCard(
        nickname: authService.userNickname.value,
        score: score,
        isLoading: isLoading,
        tierLabel: tier?.label,
        tierColor: _tierColor(tier),
        onTapNickname: () {
          Get.dialog(
            EditNicknameDialog(
              currentNickname: authService.userNickname.value ?? '',
              onSave: authService.updateNickname,
            ),
            barrierDismissible: false,
          );
        },
      );
    });
  }

  Color? _tierColor(SeasonTier? tier) {
    return switch (tier) {
      SeasonTier.jesus => const Color(0xFF4F46E5),
      SeasonTier.challenger => const Color(0xFFA855F7),
      SeasonTier.master => const Color(0xFFDC2626),
      SeasonTier.diamond => const Color(0xFF38BDF8),
      SeasonTier.platinum => const Color(0xFF64748B),
      SeasonTier.gold => const Color(0xFFF59E0B),
      SeasonTier.silver => const Color(0xFF94A3B8),
      SeasonTier.bronze => const Color(0xFFB45309),
      null => null,
    };
  }
}
