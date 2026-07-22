import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/screens/home/home_screen_flows.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final progressService = Get.find<LevelProgressService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Profile Header
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Center(
                  child: Text(
                    '😀',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() {
                final nickname = authService.userNickname.value ?? 'NUMBERING';
                return Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                );
              }),
              const SizedBox(height: 8),
              Obx(() {
                final currentLevel = progressService.highestUnlockedLevel;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blockLilac,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Level $currentLevel',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 48),
              // Stars
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '획득한 별',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 24),
                      Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 24),
                      Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 24),
                      Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 24),
                      Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 24),
                      Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 24),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
              // Menu Options
              _buildMenuRow(Icons.palette_rounded, '테마 변경', () {}),
              _buildMenuRow(Icons.account_circle_rounded, '계정', () {}),
              _buildMenuRow(Icons.settings_rounded, '설정', () {
                showSettingsScreen(authService);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
