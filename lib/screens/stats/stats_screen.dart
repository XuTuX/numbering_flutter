import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/game/numbering/level_progress_service.dart';
import 'package:numbering/theme/app_colors.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, these are partially mock data and partially real data
    // You would integrate with a full StatsController/Service later.
    final scoreController = Get.find<ScoreController>();
    final progressService = Get.find<LevelProgressService>();

    final highScore = scoreController.highscore.value;
    final highestUnlocked = progressService.highestUnlockedLevel;
    final totalCleared =
        progressService.progress.values.where((e) => e.cleared).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Statistics',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatRow('총 플레이', '1,243'),
              const Divider(height: 32, color: AppColors.borderLight),
              _buildStatRow('총 승리', '$totalCleared'),
              const Divider(height: 32, color: AppColors.borderLight),
              _buildStatRow('평균 점수', '23,124'),
              const Divider(height: 32, color: AppColors.borderLight),
              _buildStatRow('최고 점수', '$highScore'),
              const Divider(height: 32, color: AppColors.borderLight),
              _buildStatRow('오늘의 퍼즐', '72승'),
              const Divider(height: 32, color: AppColors.borderLight),
              _buildStatRow('Arcade', 'Level $highestUnlocked'),
              const SizedBox(height: 48),
              const Text(
                '최근 30일',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Placeholder for a bar chart
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(30, (index) {
                    final height = 20.0 + (index * 7 % 100);
                    return Container(
                      width: 6,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(
                          alpha: index % 3 == 0 ? 0.18 : 0.72,
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
