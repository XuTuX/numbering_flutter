import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constant.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/soft_icon_button.dart';
import '../game_module.dart';
import 'expression_engine.dart';
import 'level_catalog.dart';
import 'level_models.dart';
import 'level_progress_service.dart';
import 'numbering_models.dart';
import 'numbering_visuals.dart';

class NumberingGamePage extends StatefulWidget {
  const NumberingGamePage({
    super.key,
    required this.game,
    required this.session,
    required this.callbacks,
  });

  final NumberingGame game;
  final GameSessionConfig session;
  final GameCallbacks callbacks;

  @override
  State<NumberingGamePage> createState() => _NumberingGamePageState();
}

class _NumberingGamePageState extends State<NumberingGamePage> {
  late final LevelProgressService _progress;
  int? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    _progress = Get.find<LevelProgressService>();
    if (widget.session.isTutorialMode) _selectedLevelId = 1;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: _selectedLevelId == null
          ? _LevelSelectionView(
              key: const ValueKey('level-selection'),
              progress: _progress,
              accent: widget.game.visuals.accent,
              onExit: widget.callbacks.onExit,
              onSelect: _openLevel,
            )
          : _LevelPlayView(
              key: ValueKey('level-$_selectedLevelId'),
              level: LevelCatalog.byId(_selectedLevelId!),
              progress: _progress,
              accent: widget.game.visuals.accent,
              onShowLevels: () => setState(() => _selectedLevelId = null),
              onNext: (id) => setState(() => _selectedLevelId = id),
            ),
    );
  }

  void _openLevel(int levelId) {
    if (!_progress.isUnlocked(levelId)) return;
    unawaited(_progress.rememberLevel(levelId));
    setState(() => _selectedLevelId = levelId);
  }
}

// ─── 레벨 선택 뷰 ─────────────────────────────────────────

class _LevelSelectionView extends StatelessWidget {
  const _LevelSelectionView({
    super.key,
    required this.progress,
    required this.accent,
    required this.onExit,
    required this.onSelect,
  });

  final LevelProgressService progress;
  final Color accent;
  final VoidCallback onExit;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 8
            : constraints.maxWidth >= 650
                ? 6
                : constraints.maxWidth >= 420
                    ? 4
                    : 3;
        const rowExtent = 118.0;
        return Obx(() {
          final current = progress.highestUnlockedLevel;
          final records = Map<int, LevelProgress>.of(progress.progress);
          final controller = ScrollController(
            initialScrollOffset:
                (((current - 1) ~/ columns) * rowExtent - 80).clamp(0, 5000),
          );
          return Column(
            children: [
              Row(
                children: [
                  SoftIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: '뒤로 가기'.tr,
                    onPressed: onExit,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'LEVEL',
                      style: GoogleFonts.blackHanSans(
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$current / 200',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 106,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: LevelCatalog.all.length,
                  itemBuilder: (context, index) {
                    final level = LevelCatalog.all[index];
                    final record =
                        records[level.id] ?? LevelProgress(levelId: level.id);
                    final unlocked = level.id <= current;
                    return _LevelCard(
                      level: level,
                      record: record,
                      unlocked: unlocked,
                      current: level.id == current,
                      accent: accent,
                      onTap: () => onSelect(level.id),
                    );
                  },
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.record,
    required this.unlocked,
    required this.current,
    required this.accent,
    required this.onTap,
  });

  final LevelData level;
  final LevelProgress record;
  final bool unlocked;
  final bool current;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = current
        ? accent
        : record.cleared
            ? AppColors.green.withValues(alpha: 0.5)
            : AppColors.borderLight;
    final background = !unlocked
        ? AppColors.surfaceSecondary.withValues(alpha: 0.75)
        : current
            ? accent.withValues(alpha: 0.09)
            : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: borderColor, width: current ? 1.8 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${level.id}',
                style: GoogleFonts.blackHanSans(
                  fontSize: 22,
                  color: unlocked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              if (record.cleared)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.green,
                )
              else if (!unlocked)
                const Icon(Icons.lock_rounded,
                    size: 18, color: Color(0xFFAAB0BA)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 레벨 플레이 뷰 ─────────────────────────────────────────

class _LevelPlayView extends StatefulWidget {
  const _LevelPlayView({
    super.key,
    required this.level,
    required this.progress,
    required this.accent,
    required this.onShowLevels,
    required this.onNext,
  });

  final LevelData level;
  final LevelProgressService progress;
  final Color accent;
  final VoidCallback onShowLevels;
  final ValueChanged<int> onNext;

  @override
  State<_LevelPlayView> createState() => _LevelPlayViewState();
}

class _LevelPlayViewState extends State<_LevelPlayView> {
  final _editorKey = GlobalKey<_FormulaEditorState>();
  int _usedHints = 0;
  _CompletedAttempt? _completed;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return Stack(
      children: [
        Column(
          children: [
            _LevelHeader(
              levelId: widget.level.id,
              remainingHints: 3 - _usedHints,
              accent: widget.accent,
              onBack: widget.onShowLevels,
              onHint: _showHint,
              isLandscape: isLandscape,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _FormulaEditor(
                key: _editorKey,
                level: widget.level,
                accent: widget.accent,
                isLandscape: isLandscape,
                onValidSubmission: _handleSubmission,
              ),
            ),
          ],
        ),
        if (_completed case final completed?)
          Positioned.fill(
            child: _LevelResultOverlay(
              level: widget.level,
              attempt: completed,
              usedHints: _usedHints,
              accent: widget.accent,
              onReplay: _replay,
              onShowLevels: widget.onShowLevels,
              onNext: widget.level.id < 200
                  ? () => widget.onNext(widget.level.id + 1)
                  : null,
            ),
          ),
      ],
    );
  }

  void _showHint() {
    if (_usedHints < 3) setState(() => _usedHints++);
    final visibleCount = _usedHints;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppColors.yellow),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '힌트 $visibleCount/3',
                    style: AppTypography.subtitle,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (var index = 0; index < visibleCount; index++) ...[
                Text(
                  '${index + 1}. ${widget.level.hints.at(index)}',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                if (index + 1 < visibleCount)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmission(String expression, int score) {
    final evaluation = evaluateLevelScore(widget.level, score);
    if (!evaluation.cleared) {
      _editorKey.currentState?.showMessage(
        '+${widget.level.minimumScore}점 이상 필요',
      );
      return;
    }
    unawaited(
      widget.progress.recordResult(
        level: widget.level,
        score: score,
        evaluation: evaluation,
        usedHints: _usedHints,
      ),
    );
    setState(() {
      _completed = _CompletedAttempt(
        expression: expression,
        score: score,
        evaluation: evaluation,
      );
    });
  }

  void _replay() {
    setState(() {
      _usedHints = 0;
      _completed = null;
    });
    _editorKey.currentState?.reset();
  }
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.levelId,
    required this.remainingHints,
    required this.accent,
    required this.onBack,
    required this.onHint,
    required this.isLandscape,
  });

  final int levelId;
  final int remainingHints;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback onHint;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SoftIconButton(
          icon: Icons.arrow_back_rounded,
          label: '레벨 목록',
          onPressed: onBack,
          size: isLandscape ? 36 : 40,
          iconSize: 20,
        ),
        Expanded(
          child: Text(
            'LEVEL $levelId',
            textAlign: TextAlign.center,
            style: GoogleFonts.blackHanSans(
              fontSize: isLandscape ? 20 : 22,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHint,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        size: 18, color: AppColors.yellow),
                    const SizedBox(width: 4),
                    Text(
                      '$remainingHints',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: remainingHints == 0
                            ? AppColors.textSecondary
                            : accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 수식 편집기 ────────────────────────────────────────────

class _FormulaEditor extends StatefulWidget {
  const _FormulaEditor({
    super.key,
    required this.level,
    required this.accent,
    required this.isLandscape,
    required this.onValidSubmission,
  });

  final LevelData level;
  final Color accent;
  final bool isLandscape;
  final void Function(String expression, int score) onValidSubmission;

  @override
  State<_FormulaEditor> createState() => _FormulaEditorState();
}

class _EditorSnapshot {
  _EditorSnapshot(this.operators, this.parentheses);
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
}

class _FormulaEditorState extends State<_FormulaEditor> {
  late List<InlineOperator?> _operators;
  final List<ParenthesisRange> _parentheses = [];
  final List<_EditorSnapshot> _history = [];
  int? _selectedDigitIndex;
  String? _message;

  String get _expression => assembleInlineExpression(
        digits: widget.level.digits,
        operators: _operators,
        parentheses: _parentheses,
      );

  @override
  void initState() {
    super.initState();
    _operators = List.filled(widget.level.digits.length - 1, null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 470;
        return Column(
          children: [
            SizedBox(height: compact ? 4 : 12),
            Expanded(
              child: SingleChildScrollView(
                child: _DragDropEditor(
                  digits: widget.level.digits,
                  operators: _operators,
                  parentheses: _parentheses,
                  availableOperators: widget.level.availableOperators,
                  accent: widget.accent,
                  selectedDigitIndex: _selectedDigitIndex,
                  isLandscape: widget.isLandscape,
                  onDigitTapped: _handleDigitTap,
                  onOperatorChanged: _changeOperator,
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              child: _message == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: const Text('제출', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  void _saveSnapshot() {
    _history.add(_EditorSnapshot(List.of(_operators), List.of(_parentheses)));
  }

  void _changeOperator(int index, InlineOperator? value) {
    _saveSnapshot();
    setState(() {
      _operators[index] = value;
      _message = null;
    });
    _previewValidation();
  }

  void _handleDigitTap(int index) {
    if (_selectedDigitIndex == null) {
      setState(() => _selectedDigitIndex = index);
      return;
    }
    if (_selectedDigitIndex == index) {
      setState(() => _selectedDigitIndex = null);
      return;
    }
    final candidate = ParenthesisRange(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      startDigitIndex: _selectedDigitIndex!,
      endDigitIndex: index,
    ).normalized();
    final existingIndex = _parentheses.indexWhere((range) {
      final normalized = range.normalized();
      return normalized.startDigitIndex == candidate.startDigitIndex &&
          normalized.endDigitIndex == candidate.endDigitIndex;
    });
    if (existingIndex >= 0) {
      _saveSnapshot();
      setState(() {
        _parentheses.removeAt(existingIndex);
        _selectedDigitIndex = null;
        _message = null;
      });
      return;
    }
    final validation = validateParenthesisRange(
      digitCount: widget.level.digits.length,
      candidate: candidate,
      existing: _parentheses,
    );
    if (!validation.valid) {
      setState(() {
        _selectedDigitIndex = null;
        _message = validation.message;
      });
      return;
    }
    _saveSnapshot();
    setState(() {
      _parentheses.add(candidate);
      _selectedDigitIndex = null;
      _message = null;
    });
  }

  void _previewValidation() {
    if (!_operators.contains(InlineOperator.equals)) return;
    final result = validateLevelFormula(
      digitString: widget.level.digitString,
      expression: _expression,
      availableOperators: widget.level.availableOperators,
    );
    if (!result.valid && mounted) setState(() => _message = result.message);
  }

  void _submit() {
    final result = validateLevelFormula(
      digitString: widget.level.digitString,
      expression: _expression,
      availableOperators: widget.level.availableOperators,
    );
    if (!result.valid) {
      showMessage(result.message ?? '수식을 확인하세요');
      return;
    }
    widget.onValidSubmission(_expression, result.value!);
  }

  void showMessage(String message) => setState(() => _message = message);
}

// ─── 드래그 드롭 편집기 ──────────────────────────────────────

class _DragDropEditor extends StatelessWidget {
  const _DragDropEditor({
    required this.digits,
    required this.operators,
    required this.parentheses,
    required this.availableOperators,
    required this.accent,
    required this.selectedDigitIndex,
    required this.onDigitTapped,
    required this.onOperatorChanged,
    required this.isLandscape,
  });

  final List<String> digits;
  final List<InlineOperator?> operators;
  final List<ParenthesisRange> parentheses;
  final Set<String> availableOperators;
  final Color accent;
  final int? selectedDigitIndex;
  final ValueChanged<int> onDigitTapped;
  final void Function(int index, InlineOperator? value) onOperatorChanged;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context);
        final compact = constraints.maxWidth < 600 || viewport.height < 560;
        final digitFontSize = compact
            ? (constraints.maxWidth / (digits.length * 1.12)).clamp(34.0, 58.0)
            : (constraints.maxWidth * 0.08).clamp(62.0, 96.0);
        final digitPadding = compact ? (digits.length >= 8 ? 3.0 : 7.0) : 13.0;
        final operatorFontSize = (digitFontSize * 0.5).clamp(22.0, 44.0);
        final items = List<Widget>.generate(digits.length, (digitIndex) {
          final openingCount = parentheses
              .where(
                  (range) => range.normalized().startDigitIndex == digitIndex)
              .length;
          final closingCount = parentheses
              .where((range) => range.normalized().endDigitIndex == digitIndex)
              .length;
          final selected = selectedDigitIndex == digitIndex;
          final digit = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onDigitTapped(digitIndex),
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: digitPadding, vertical: 8),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: digitFontSize,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: selected ? accent : const Color(0xFF17191D),
                ),
                child: Text(
                  '${'(' * openingCount}${digits[digitIndex]}${')' * closingCount}',
                ),
              ),
            ),
          );
          if (digitIndex == 0) return digit;
          final slotIndex = digitIndex - 1;
          return _InlineOperatorTarget(
            current: operators[slotIndex],
            digit: digit,
            accent: accent,
            operatorFontSize: operatorFontSize,
            horizontalPadding: digitPadding * 0.65,
            onAccept: (operator) => onOperatorChanged(slotIndex, operator),
            onRemove: () => onOperatorChanged(slotIndex, null),
          );
        });

        return Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            ),
            SizedBox(height: compact ? 16 : 32),
            _OperatorPalette(
              accent: accent,
              availableOperators: availableOperators,
              compact: compact,
            ),
          ],
        );
      },
    );
  }
}

class _InlineOperatorTarget extends StatefulWidget {
  const _InlineOperatorTarget({
    required this.current,
    required this.digit,
    required this.accent,
    required this.operatorFontSize,
    required this.horizontalPadding,
    required this.onAccept,
    required this.onRemove,
  });

  final InlineOperator? current;
  final Widget digit;
  final Color accent;
  final double operatorFontSize;
  final double horizontalPadding;
  final ValueChanged<InlineOperator> onAccept;
  final VoidCallback onRemove;

  @override
  State<_InlineOperatorTarget> createState() => _InlineOperatorTargetState();
}

class _InlineOperatorTargetState extends State<_InlineOperatorTarget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<InlineOperator>(
      onWillAcceptWithDetails: (_) {
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _hovering = false);
        widget.onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: _hovering && widget.current == null
                ? widget.operatorFontSize * 0.75
                : 0,
          ),
          if (widget.current case final current?)
            GestureDetector(
              onTap: widget.onRemove,
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
                child: Text(
                  current.symbol,
                  style: TextStyle(
                    fontSize: widget.operatorFontSize,
                    fontWeight: FontWeight.w700,
                    color: _hovering ? widget.accent : const Color(0xFF253044),
                  ),
                ),
              ),
            ),
          widget.digit,
        ],
      ),
    );
  }
}

class _OperatorPalette extends StatefulWidget {
  const _OperatorPalette({
    required this.accent,
    required this.availableOperators,
    required this.compact,
  });

  final Color accent;
  final Set<String> availableOperators;
  final bool compact;

  @override
  State<_OperatorPalette> createState() => _OperatorPaletteState();
}

class _OperatorPaletteState extends State<_OperatorPalette> {
  InlineOperator? _dragging;

  @override
  Widget build(BuildContext context) {
    final operators = InlineOperator.values
        .where(
            (operator) => widget.availableOperators.contains(operator.symbol))
        .toList();
    final size = widget.compact ? 44.0 : 58.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 14 : 22,
        vertical: widget.compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < operators.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Draggable<InlineOperator>(
              data: operators[index],
              onDragStarted: () => setState(() => _dragging = operators[index]),
              onDragEnd: (_) => setState(() => _dragging = null),
              feedback: Material(
                color: Colors.transparent,
                child: _OperatorButton(
                  operator: operators[index],
                  accent: widget.accent,
                  size: size,
                  active: true,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _OperatorButton(
                  operator: operators[index],
                  accent: widget.accent,
                  size: size,
                  active: false,
                ),
              ),
              child: _OperatorButton(
                operator: operators[index],
                accent: widget.accent,
                size: size,
                active: _dragging == operators[index],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OperatorButton extends StatelessWidget {
  const _OperatorButton({
    required this.operator,
    required this.accent,
    required this.size,
    required this.active,
  });

  final InlineOperator operator;
  final Color accent;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? accent : AppColors.surfaceSecondary,
        shape: BoxShape.circle,
      ),
      child: Text(
        operator.symbol,
        style: TextStyle(
          fontSize: size * 0.42,
          color: active ? Colors.white : const Color(0xFF253044),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── 완료 시도 데이터 ────────────────────────────────────────

class _CompletedAttempt {
  const _CompletedAttempt({
    required this.expression,
    required this.score,
    required this.evaluation,
  });

  final String expression;
  final int score;
  final LevelEvaluation evaluation;
}

// ─── 레벨 결과 오버레이 ──────────────────────────────────────

class _LevelResultOverlay extends StatelessWidget {
  const _LevelResultOverlay({
    required this.level,
    required this.attempt,
    required this.usedHints,
    required this.accent,
    required this.onReplay,
    required this.onShowLevels,
    required this.onNext,
  });

  final LevelData level;
  final _CompletedAttempt attempt;
  final int usedHints;
  final Color accent;
  final VoidCallback onReplay;
  final VoidCallback onShowLevels;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final evaluation = attempt.evaluation;
    return ColoredBox(
      color: const Color(0xFF20242C).withValues(alpha: 0.44),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LEVEL ${level.id}',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+${attempt.score}',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 56,
                    color: accent,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  evaluation.perfect ? 'PERFECT' : '★★★',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 20,
                    color: evaluation.perfect
                        ? AppColors.scoreOrange
                        : AppColors.yellow,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReplay,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '다시',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onShowLevels,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '목록',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: onNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          onNext == null ? '완료' : '다음',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
