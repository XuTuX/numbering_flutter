part of '../numbering_game_page.dart';

class _DailyPlayView extends StatefulWidget {
  const _DailyPlayView({
    super.key,
    required this.session,
    required this.accent,
    required this.onShowLevels,
  });

  final GameSessionConfig session;
  final Color accent;
  final VoidCallback onShowLevels;

  @override
  State<_DailyPlayView> createState() => _DailyPlayViewState();
}

class _DailyPlayViewState extends State<_DailyPlayView> {
  late final String _digits;
  final _editorKey = GlobalKey<_DailyFormulaEditorState>();

  @override
  void initState() {
    super.initState();
    final seed = widget.session.seed ?? 0;
    _digits = generateDailyPuzzle8Digits(Random(seed));
  }

  void _handleSubmission(String expression, int score) {
    final dateKey = widget.session.dateKey ?? '';
    final controller = Get.find<DailyPuzzleController>();
    controller.submitDailyScore(dateKey, score);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            '성공!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '점수: $score',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: widget.accent,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '가장 높은 점수 30개가 합산되어\n오늘의 랭킹에 반영됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editorKey.currentState?.reset();
              },
              style: FilledButton.styleFrom(backgroundColor: widget.accent),
              child: const Text('계속하기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onShowLevels();
              },
              child: const Text('나가기'),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Row(
          children: [
            SoftIconButton(
              icon: Icons.arrow_back_rounded,
              label: '나가기',
              onPressed: widget.onShowLevels,
              size: 40,
              iconSize: 20,
            ),
            const Expanded(
              child: Text(
                '오늘의 퍼즐',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 40), // Balance back button
          ],
        ),
        const SizedBox(height: 16),
        
        // Editor
        Expanded(
          child: _DailyFormulaEditor(
            key: _editorKey,
            digits: _digits.split(''),
            accent: widget.accent,
            onValidSubmission: _handleSubmission,
          ),
        ),
      ],
    );
  }
}
