import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/constant.dart';
import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';
import 'package:numbering/theme/app_shadows.dart';
import 'package:numbering/utils/random_nickname_generator.dart';

part 'nickname/edit_nickname_dialog_view.dart';

class EditNicknameDialog extends StatefulWidget {
  const EditNicknameDialog({
    super.key,
    required this.currentNickname,
    required this.onSave,
    this.isInitialSetup = false,
  });

  final String currentNickname;
  final Future<String?> Function(String) onSave;
  final bool isInitialSetup;

  @override
  State<EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<EditNicknameDialog> {
  late final TextEditingController controller;
  String? errorMessage;
  bool isSaving = false;
  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.currentNickname);

    if (widget.currentNickname.isEmpty) {
      _generateRandom();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _generateRandom() async {
    if (isGenerating) {
      return;
    }

    setState(() {
      isGenerating = true;
      errorMessage = null;
    });

    final candidate = await _generateAvailableNickname();

    if (!mounted) {
      return;
    }

    setState(() {
      isGenerating = false;
      if (candidate != null) {
        controller.text = candidate;
      } else {
        errorMessage = '랜덤 닉네임 생성에 실패했습니다. 다시 시도해주세요.'.tr;
      }
    });
  }

  Future<String?> _generateAvailableNickname() async {
    return RandomNicknameGenerator.generate();
  }

  Future<void> _handleSave() async {
    final newNickname = controller.text.trim();
    if (newNickname.isEmpty) {
      if (mounted) {
        setState(() => errorMessage = '닉네임을 입력해주세요'.tr);
      }
      return;
    }

    if (!widget.isInitialSetup && newNickname == widget.currentNickname) {
      Get.back();
      return;
    }

    if (mounted) {
      setState(() => isSaving = true);
    }

    final error = await widget.onSave(newNickname);

    if (!mounted) {
      return;
    }

    if (error != null) {
      setState(() {
        errorMessage = error;
        isSaving = false;
      });
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditNicknameDialogView(
      title: widget.isInitialSetup ? '닉네임 설정'.tr : '닉네임 변경'.tr,
      controller: controller,
      errorMessage: errorMessage,
      isSaving: isSaving,
      isGenerating: isGenerating,
      isInitialSetup: widget.isInitialSetup,
      onChanged: (_) {
        if (errorMessage != null) {
          setState(() => errorMessage = null);
        }
      },
      onGenerateRandom: _generateRandom,
      onCancel: Get.back,
      onSave: _handleSave,
    );
  }
}
