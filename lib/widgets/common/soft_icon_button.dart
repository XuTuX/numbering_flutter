import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';

class SoftIconButton extends StatefulWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 52,
    this.iconSize = 25,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  State<SoftIconButton> createState() => _SoftIconButtonState();
}

class _SoftIconButtonState extends State<SoftIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.size.clamp(44, 64),
              height: widget.size.clamp(44, 64),
              decoration: BoxDecoration(
                color:
                    _pressed ? AppColors.surfaceSecondary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: AppColors.borderLight),
                boxShadow:
                    _pressed ? AppShadows.smallShadow : AppShadows.buttonShadow,
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                color: AppColors.textPrimary,
                size: widget.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
