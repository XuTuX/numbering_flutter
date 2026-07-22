import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/services/auth_service.dart';

import 'package:numbering/controllers/daily_puzzle_controller.dart';
import 'package:numbering/widgets/home_screen/login_sheet.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/utils/mock_data.dart';

import 'ranking_period.dart';
import 'widgets/ranking_chrome.dart';
import 'widgets/rank_list_item.dart';
import 'widgets/ranking_states.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({
    super.key,
    this.isDailyOnly = false,
    this.dailyDateKey,
  });

  final bool isDailyOnly;
  final String? dailyDateKey;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _scores = [];
  late RankingPeriod _period;
  late final Worker _authWorker;

  @override
  void initState() {
    super.initState();
    _period = widget.isDailyOnly ? RankingPeriod.daily : RankingPeriod.weekly;
    _loadRankingData();

    final authService = Get.find<AuthService>();
    _authWorker = ever(authService.user, (_) {
      if (mounted) {
        _loadRankingData();
      }
    });
  }

  @override
  void dispose() {
    _authWorker.dispose();
    super.dispose();
  }

  Future<void> _loadRankingData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final scoreController = Get.find<ScoreController>();
    final authService = Get.find<AuthService>();
    await scoreController.waitForLoginSync();

    if (!mounted) return;
    final myId = authService.user.value?.id;
    int? localScore;
    if (_period == RankingPeriod.daily) {
      final dailyController = Get.find<DailyPuzzleController>();
      final dateKey = widget.dailyDateKey ?? '';
      localScore = dailyController.getDailyTotalScore(dateKey);
      if (localScore == 0) localScore = null;
    } else {
      localScore = scoreController.highscore.value;
    }

    final mockScores =
        MockData.getScores(myId, authService.userNickname.value, localScore);

    setState(() {
      _scores = mockScores;
      _isLoading = false;
    });
  }

  void _handlePeriodChanged(RankingPeriod period) {
    if (_period == period) {
      return;
    }

    setState(() {
      _period = period;
    });
    _loadRankingData();
  }

  void _showLoginSheet() {
    final authService = Get.find<AuthService>();
    Get.bottomSheet(
      LoginSheet(
        isRankingAction: true,
        onGoogleSignIn: authService.signInWithGoogle,
        onAppleSignIn: authService.signInWithApple,
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final myId = authService.user.value?.id;

    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(
          widget.isDailyOnly ? 'DAILY PUZZLE'.tr : 'RANKING'.tr,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            RankingHeader(
              period: _period,
              onPeriodChanged: _handlePeriodChanged,
              isDailyOnly: widget.isDailyOnly,
              dailyDateKey: widget.dailyDateKey,
            ),
            SizedBox(height: isLandscape ? 8 : 16),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? mediaSize.width * 0.85 : 480,
                  ),
                  child: _buildContent(myId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String? myId) {
    if (_isLoading) {
      return const RankingLoadingState();
    }

    if (_error != null) {
      return RankingErrorState(onRetry: _loadRankingData);
    }

    if (_scores.isEmpty) {
      return EmptyRankingState(period: _period);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _scores.length + (myId == null ? 1 : 0),
      itemBuilder: (context, index) {
        // Show compact login bar at the top when not logged in
        if (myId == null && index == 0) {
          return _LoginPromptBar(onLoginTap: _showLoginSheet);
        }

        final scoreIndex = myId == null ? index - 1 : index;
        return RankListItem(
          scoreData: _scores[scoreIndex],
          index: scoreIndex,
          myId: myId,
        );
      },
    );
  }
}

/// Compact inline login prompt — replaces bulky MyRankCard for non-logged-in users.
class _LoginPromptBar extends StatelessWidget {
  const _LoginPromptBar({required this.onLoginTap});
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded,
              size: 18, color: AppColors.ink.withValues(alpha: 0.35)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '로그인하면 랭킹에 참여할 수 있어요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onLoginTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '로그인',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
