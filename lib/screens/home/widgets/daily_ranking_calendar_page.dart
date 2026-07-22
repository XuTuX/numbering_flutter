import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numbering/constant.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_shadows.dart';
import 'package:numbering/services/auth_service.dart';
import 'package:numbering/theme/app_typography.dart';
import 'package:numbering/utils/kst_clock.dart';
import 'package:numbering/utils/mock_data.dart';
import 'package:numbering/widgets/home_screen/components/weekly_ranking_preview.dart';

part 'daily_ranking_calendar_components.dart';

class DailyRankingCalendarPage extends StatefulWidget {
  const DailyRankingCalendarPage({
    super.key,
    required this.authService,
    required this.isVisible,
    required this.onStartDaily,
    required this.onStartDailyTest,
    required this.onShowDailyRanking,
    required this.onRankingTap,
  });

  final AuthService authService;
  final bool isVisible;
  final Future<void> Function() onStartDaily;
  final Future<void> Function() onStartDailyTest;
  final ValueChanged<String> onShowDailyRanking;
  final VoidCallback onRankingTap;

  @override
  State<DailyRankingCalendarPage> createState() =>
      _DailyRankingCalendarPageState();
}

class _DailyRankingCalendarPageState extends State<DailyRankingCalendarPage>
    with AutomaticKeepAliveClientMixin {
  late final Set<String> _selectableDateKeys;
  late final List<_CalendarCellData> _calendarCells;
  late String _selectedDateKey;
  late final Worker _authWorker;
  bool _isRankLoading = false;
  bool _isSelectedRankingLoading = false;
  bool _isLaunching = false;
  bool _isLaunchingTest = false;
  bool _hasLoadedVisibleData = false;
  String? _selectedRankingError;
  Map<String, int> _myDailyRanks = {};
  List<Map<String, dynamic>> _selectedScores = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final recentDateKeys = KstClock.recentDateKeys(days: 30);
    _selectableDateKeys = recentDateKeys.toSet();
    _calendarCells = _buildCurrentMonthCells();
    _selectedDateKey = recentDateKeys.first;
    _authWorker = ever(widget.authService.user, (_) {
      if (mounted) {
        _hasLoadedVisibleData = false;
        if (widget.isVisible) {
          _ensureVisibleDataLoaded(force: true);
        }
      }
    });
    if (widget.isVisible) {
      _ensureVisibleDataLoaded();
    }
  }

  @override
  void dispose() {
    _authWorker.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DailyRankingCalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && (!oldWidget.isVisible || !_hasLoadedVisibleData)) {
      _ensureVisibleDataLoaded();
    }
  }

  void _ensureVisibleDataLoaded({bool force = false}) {
    if (_hasLoadedVisibleData && !force) {
      return;
    }

    _hasLoadedVisibleData = true;
    _loadMyDailyRanks();
    _loadSelectedRanking(_selectedDateKey);
  }

  void _selectDate(String dateKey) {
    setState(() => _selectedDateKey = dateKey);
    _loadSelectedRanking(dateKey);
  }

  Future<void> _loadMyDailyRanks() async {
    if (!mounted) {
      return;
    }

    final dates = KstClock.recentDateKeys(days: 30);
    final mockRanks = <String, int>{};
    for (int i = 0; i < dates.length; i++) {
      if (i % 3 == 0) {
        mockRanks[dates[i]] = (i % 9) ~/ 3 + 1; // 1, 2, 3
      }
    }

    setState(() {
      _myDailyRanks = mockRanks;
      _isRankLoading = false;
    });
  }

  Future<void> _loadSelectedRanking(String dateKey) async {
    if (!mounted) {
      return;
    }

    final myId = widget.authService.user.value?.id;
    final myNickname = widget.authService.userNickname.value;
    
    setState(() {
      _isSelectedRankingLoading = false;
      _selectedRankingError = null;
      _selectedScores = MockData.getScores(myId, myNickname, 4800);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mediaSize = MediaQuery.sizeOf(context);
    final isLandscape = mediaSize.width > mediaSize.height;
    final sw = mediaSize.width;
    final sh = mediaSize.height;
    final horizontalPadding = (sw * 0.06).clamp(24.0, 40.0);
    final maxWidth = isLandscape ? sw * 0.95 : 480.0;
    final myId = widget.authService.user.value?.id;
    final topPad = (sh * 0.02).clamp(8.0, 20.0);
    final bottomPad = (sh * 0.02).clamp(8.0, 20.0);
    final sectionGap = (sh * 0.02).clamp(8.0, 16.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, topPad, horizontalPadding, bottomPad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 가로 모드: 캘린더와 랭킹+버튼을 좌우로 배치
              // 세로 모드: 위에서 아래로 배치
              Expanded(
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 왼쪽: 캘린더
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(right: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _CalendarHeader(),
                                  SizedBox(height: sectionGap * 0.5),
                                  _MonthlyCalendar(
                                    cells: _calendarCells,
                                    selectableDateKeys: _selectableDateKeys,
                                    selectedDateKey: _selectedDateKey,
                                    myDailyRanks: _myDailyRanks,
                                    isRankLoading: _isRankLoading,
                                    onDateSelected: _selectDate,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 오른쪽: 랭킹 + 버튼
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(left: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _InlineDailyRankingPanel(
                                    dateKey: _selectedDateKey,
                                    scores: _selectedScores,
                                    myId: myId,
                                    isLoading: _isSelectedRankingLoading,
                                    error: _selectedRankingError,
                                    onRetry: () =>
                                        _loadSelectedRanking(_selectedDateKey),
                                    onViewAll: () => widget
                                        .onShowDailyRanking(_selectedDateKey),
                                  ),
                                  SizedBox(height: sectionGap),
                                  _DailyPlayButton(
                                    isLoading: _isLaunching,
                                    onPressed: _handleStartDaily,
                                  ),
                                  if (kDebugMode) ...[
                                    const SizedBox(height: 8),
                                    _DailyTestButton(
                                      isLoading: _isLaunchingTest,
                                      onPressed: _handleStartDailyTest,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(
                            left: 4, right: 4, bottom: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _CalendarHeader(),
                            SizedBox(height: sectionGap * 0.5),
                            _MonthlyCalendar(
                              cells: _calendarCells,
                              selectableDateKeys: _selectableDateKeys,
                              selectedDateKey: _selectedDateKey,
                              myDailyRanks: _myDailyRanks,
                              isRankLoading: _isRankLoading,
                              onDateSelected: _selectDate,
                            ),
                            SizedBox(height: sectionGap),
                            _InlineDailyRankingPanel(
                              dateKey: _selectedDateKey,
                              scores: _selectedScores,
                              myId: myId,
                              isLoading: _isSelectedRankingLoading,
                              error: _selectedRankingError,
                              onRetry: () =>
                                  _loadSelectedRanking(_selectedDateKey),
                              onViewAll: () =>
                                  widget.onShowDailyRanking(_selectedDateKey),
                            ),
                          ],
                        ),
                      ),
              ),
              // 가로 모드에서는 버튼이 우측 패널 안에 이미 포함됨
              if (!isLandscape) ...[
                SizedBox(height: sectionGap * 0.6),
                _DailyPlayButton(
                  isLoading: _isLaunching,
                  onPressed: _handleStartDaily,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  _DailyTestButton(
                    isLoading: _isLaunchingTest,
                    onPressed: _handleStartDailyTest,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleStartDaily() async {
    if (_isLaunching) {
      return;
    }

    setState(() => _isLaunching = true);
    try {
      await widget.onStartDaily();
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  Future<void> _handleStartDailyTest() async {
    if (_isLaunchingTest) {
      return;
    }

    setState(() => _isLaunchingTest = true);
    try {
      await widget.onStartDailyTest();
    } finally {
      if (mounted) {
        setState(() => _isLaunchingTest = false);
      }
    }
  }

  List<_CalendarCellData> _buildCurrentMonthCells() {
    final today = KstClock.nowInKst();
    final firstDay = DateTime(today.year, today.month);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final leadingEmptyCells = firstDay.weekday % 7;
    final cells = <_CalendarCellData>[
      for (var index = 0; index < leadingEmptyCells; index++)
        const _CalendarCellData.empty(),
    ];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(today.year, today.month, day);
      cells
          .add(_CalendarCellData(dateKey: KstClock.dateKeyFor(date), day: day));
    }

    while (cells.length % 7 != 0) {
      cells.add(const _CalendarCellData.empty());
    }

    return cells;
  }
}

