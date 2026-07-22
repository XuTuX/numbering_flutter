import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:numbering/controllers/score_controller.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/services/database_models.dart';
import 'package:numbering/controllers/daily_puzzle_controller.dart';
import 'package:numbering/widgets/home_screen/login_sheet.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/utils/mock_data.dart';

import 'ranking_period.dart';
import 'widgets/my_rank_card.dart';
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
  int? _myRank;
  int? _myScore;
  List<Map<String, dynamic>> _scores = [];
  WeeklySeasonSummary? _weeklySeasonSummary;
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
    
    final mockScores = MockData.getScores(myId, authService.userNickname.value, localScore);
    int? calculatedRank;
    if (myId != null && localScore != null) {
      final myIndex = mockScores.indexWhere((item) => item['user_id'] == myId);
      if (myIndex >= 0) {
        calculatedRank = myIndex + 1;
      }
    }
    
    setState(() {
      _myRank = calculatedRank;
      _myScore = localScore;
      _scores = mockScores;
      _weeklySeasonSummary = null;
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
      backgroundColor: AppColors.canvas,
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

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: MyRankCard(
            rank: _myRank,
            score: _myScore,
            isLoggedIn: myId != null,
            period: _period,
            weeklySeasonSummary: _weeklySeasonSummary,
            onLoginTap: _showLoginSheet,
          ),
        ),
        if (_scores.isEmpty) ...[
          const SizedBox(height: 16),
          Expanded(child: EmptyRankingState(period: _period)),
        ] else ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: TopPlayersLabel(period: _period),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              itemCount: _scores.length,
              itemBuilder: (context, index) {
                return RankListItem(
                  scoreData: _scores[index],
                  index: index,
                  myId: myId,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
