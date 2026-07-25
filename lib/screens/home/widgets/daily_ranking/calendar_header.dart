import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numbering/utils/kst_clock.dart';

const charcoalBlack = Color(0xFF17191D);

class CalendarHeader extends StatelessWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final headerFs = (sw * 0.055).clamp(17.0, 26.0);
    final subFs = (sw * 0.035).clamp(11.0, 16.0);
    final today = KstClock.nowInKst();
    final monthLabel =
        '${today.year}.${today.month.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFF59E0B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          '오늘의 퍼즐'.tr,
          style: GoogleFonts.blackHanSans(
            fontSize: headerFs,
            color: charcoalBlack,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          monthLabel,
          style: GoogleFonts.notoSans(
            fontSize: subFs,
            fontWeight: FontWeight.w800,
            color: charcoalBlack.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
