import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_shadows.dart';

class DailyPlayButton extends StatefulWidget {
  const DailyPlayButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  final Future<void> Function() onPressed;
  final bool isLoading;

  @override
  State<DailyPlayButton> createState() => _DailyPlayButtonState();
}

class _DailyPlayButtonState extends State<DailyPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ms = MediaQuery.sizeOf(context);
    final isLandscape = ms.width > ms.height;
    final btnH = isLandscape
        ? (ms.height * 0.1).clamp(44.0, 64.0)
        : (ms.height * 0.078).clamp(52.0, 72.0);
    final btnFs = isLandscape
        ? (ms.width * 0.025).clamp(16.0, 24.0)
        : (ms.width * 0.06).clamp(18.0, 26.0);
    final br = (ms.width * 0.04).clamp(16.0, 26.0);

    return Container(
      width: double.infinity,
      height: btnH,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(br),
        boxShadow: AppShadows.buttonShadow,
      ),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, child) {
          return ElevatedButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    widget.onPressed();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(br),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: btnFs * 0.8,
                    height: btnFs * 0.8,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.isLoading ? '입장 중...'.tr : '오늘의 퍼즐'.tr,
                  style: GoogleFonts.blackHanSans(
                    fontSize: btnFs,
                    letterSpacing: 0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DailyTestButton extends StatelessWidget {
  const DailyTestButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () {
              onPressed();
            },
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.ink,
              ),
            )
          : const Icon(Icons.science_rounded),
      label: Text(isLoading ? '테스트 준비 중'.tr : '테스트 플레이'.tr),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
