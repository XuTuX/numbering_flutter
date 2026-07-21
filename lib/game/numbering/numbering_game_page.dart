import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/soft_card.dart';
import '../../widgets/common/soft_icon_button.dart';
import '../game_module.dart';
import 'expression_engine.dart';
import 'numbering_models.dart';
import 'numbering_visuals.dart';
import 'problem_generators.dart';

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
  late final Random _random;
  late final DateTime _startedAt;
  late final Timer _clock;
  int _round = 1;
  int _score = 0;
  int _attempts = 0;
  int _roundVersion = 0;
  bool _roundLocked = false;
  String? _feedback;
  late Object _problem;

  @override
  void initState() {
    super.initState();
    _random = Random(widget.session.seed);
    _startedAt = DateTime.now();
    _problem = _generateProblem();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = difficultyForRound(_round);
    final visuals = widget.game.visuals;
    return Column(
      children: [
        _GameHeader(
          title: widget.game.title,
          icon: visuals.icon,
          accent: visuals.accent,
          accentSoft: visuals.accentSoft,
          round: _round,
          score: _score,
          difficulty: difficulty,
          elapsed: DateTime.now().difference(_startedAt),
          attempts:
              widget.game == NumberingGame.sequenceDetective ? _attempts : null,
          onReset: _resetCurrentRound,
          onExit: widget.callbacks.onExit,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (widget.session.isTutorialMode)
          _InfoBanner(
            text: widget.game.description,
            accent: visuals.accent,
            accentSoft: visuals.accentSoft,
          ),
        if (widget.session.isTutorialMode)
          const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                key: ValueKey('${widget.game.id}-$_round-$_roundVersion'),
                ignoring: _roundLocked,
                child: _buildRound(),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: _feedback == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _InfoBanner(
                    text: _feedback!,
                    success: _roundLocked,
                    accent: visuals.accent,
                    accentSoft: visuals.accentSoft,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRound() {
    final visuals = widget.game.visuals;
    return switch (widget.game) {
      NumberingGame.formulaWorkshop => FormulaWorkshopRound(
          problem: _problem as FormulaProblem,
          accent: visuals.accent,
          accentSoft: visuals.accentSoft,
          onSolved: _handleSolved,
        ),
      NumberingGame.sequenceDetective => SequenceDetectiveRound(
          problem: _problem as SequenceProblem,
          accent: visuals.accent,
          accentSoft: visuals.accentSoft,
          onSolved: _handleSolved,
          onInvalid: _showInvalid,
          onAttempt: _recordAttempt,
        ),
      NumberingGame.numberVault => NumberVaultRound(
          problem: _problem as VaultProblem,
          accent: visuals.accent,
          accentSoft: visuals.accentSoft,
          onSolved: _handleSolved,
        ),
    };
  }

  Object _generateProblem() {
    final difficulty = difficultyForRound(_round);
    return switch (widget.game) {
      NumberingGame.formulaWorkshop =>
        generateFormulaProblem(_random, difficulty),
      NumberingGame.sequenceDetective => generateSequenceProblem(
          _random,
          sequenceTermCountForRound(_round),
        ),
      NumberingGame.numberVault => generateVaultProblem(_random, difficulty),
    };
  }

  void _recordAttempt() {
    setState(() => _attempts++);
  }

  void _resetCurrentRound() {
    if (_roundLocked) return;
    setState(() {
      _roundVersion++;
      _feedback = null;
    });
  }

  void _showInvalid(String message) {
    setState(() => _feedback = message);
  }

  void _handleSolved() {
    if (_roundLocked) return;
    _roundLocked = true;
    _score++;
    widget.callbacks.onScoreChanged(_score);
    setState(() => _feedback = '정답입니다!'.tr);

    Future<void>.delayed(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final isSingleRound =
          widget.session.isDailyMode || widget.session.isTutorialMode;
      if (widget.session.isTutorialMode) {
        await Get.find<SettingsService>().completeTutorial();
        if (!mounted) return;
      }
      if (isSingleRound) {
        widget.callbacks.onFinished(
          GameResult(
            score: _score,
            detailLabel: '경과 시간'.tr,
            detailValue: _formatElapsed(DateTime.now().difference(_startedAt)),
          ),
        );
        return;
      }
      setState(() {
        _round++;
        _attempts = 0;
        _problem = _generateProblem();
        _roundLocked = false;
        _feedback = null;
      });
    });
  }
}

class FormulaWorkshopRound extends StatefulWidget {
  const FormulaWorkshopRound({
    super.key,
    required this.problem,
    required this.accent,
    required this.accentSoft,
    required this.onSolved,
  });

  final FormulaProblem problem;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onSolved;

  @override
  State<FormulaWorkshopRound> createState() => _FormulaWorkshopRoundState();
}

class _FormulaWorkshopRoundState extends State<FormulaWorkshopRound> {
  late final List<InlineOperator?> _operators;
  final List<ParenthesisRange> _parentheses = [];
  String? _message;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _operators = List.filled(widget.problem.digits.length - 1, null);
  }

  String get _expression => assembleInlineExpression(
        digits: widget.problem.digits,
        operators: _operators,
        parentheses: _parentheses,
      );

  @override
  Widget build(BuildContext context) {
    return _PuzzleCard(
      title: '숫자 순서를 바꾸지 않고 등식을 만드세요.'.tr,
      accent: widget.accent,
      child: Column(
        children: [
          _ExpressionPreview(
            expression: _expression,
            accent: widget.accent,
          ),
          const SizedBox(height: 18),
          _InlineEditor(
            digits: widget.problem.digits,
            operators: _operators,
            accent: widget.accent,
            accentSoft: widget.accentSoft,
            choices: const [
              null,
              InlineOperator.add,
              InlineOperator.subtract,
              InlineOperator.multiply,
              InlineOperator.divide,
              InlineOperator.equals,
            ],
            onOperatorChanged: (index, value) {
              setState(() => _operators[index] = value);
              _checkAnswer();
            },
          ),
          const SizedBox(height: 16),
          _ParenthesisControls(
            digitCount: widget.problem.digits.length,
            ranges: _parentheses,
            onChanged: (ranges) {
              setState(() {
                _parentheses
                  ..clear()
                  ..addAll(ranges);
              });
              _checkAnswer();
            },
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _checkAnswer() {
    if (_solved) return;
    final hasEquals = _operators.contains(InlineOperator.equals);
    if (!hasEquals) {
      setState(() => _message = null);
      return;
    }
    final result = validateFormulaWorkshop(
      digitString: widget.problem.digitString,
      expression: _expression,
    );
    if (result.valid) {
      _solved = true;
      widget.onSolved();
    } else {
      setState(() => _message = result.message);
    }
  }
}

class SequenceDetectiveRound extends StatefulWidget {
  const SequenceDetectiveRound({
    super.key,
    required this.problem,
    required this.accent,
    required this.accentSoft,
    required this.onSolved,
    required this.onInvalid,
    required this.onAttempt,
  });

  final SequenceProblem problem;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onSolved;
  final ValueChanged<String> onInvalid;
  final VoidCallback onAttempt;

  @override
  State<SequenceDetectiveRound> createState() => _SequenceDetectiveRoundState();
}

class _SequenceDetectiveRoundState extends State<SequenceDetectiveRound> {
  int _startA = 1;
  int _startB = 1;

  @override
  Widget build(BuildContext context) {
    return _PuzzleCard(
      title: '순서가 있는 두 시작 수를 맞혀보세요.'.tr,
      accent: widget.accent,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: '전체 항 개수'.tr,
                  value: '${widget.problem.termCount}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: '마지막 값'.tr,
                  value: '${widget.problem.lastValue}',
                  accent: true,
                  accentColor: widget.accent,
                  accentSoft: widget.accentSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumberPicker(
                label: '첫 번째 수'.tr,
                value: _startA,
                onChanged: (value) => setState(() => _startA = value),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 24, 14, 0),
                child: Icon(Icons.arrow_forward_rounded),
              ),
              _NumberPicker(
                label: '두 번째 수'.tr,
                value: _startB,
                onChanged: (value) => setState(() => _startB = value),
              ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () {
              widget.onAttempt();
              if (_startA == widget.problem.startA &&
                  _startB == widget.problem.startB) {
                widget.onSolved();
              } else {
                widget.onInvalid('두 수의 순서와 값을 다시 확인하세요.'.tr);
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text('정답 확인'.tr),
          ),
        ],
      ),
    );
  }
}

class NumberVaultRound extends StatefulWidget {
  const NumberVaultRound({
    super.key,
    required this.problem,
    required this.accent,
    required this.accentSoft,
    required this.onSolved,
  });

  final VaultProblem problem;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onSolved;

  @override
  State<NumberVaultRound> createState() => _NumberVaultRoundState();
}

class _NumberVaultRoundState extends State<NumberVaultRound> {
  late final List<String> _digits;
  late final List<InlineOperator?> _operators;
  final List<ParenthesisRange> _parentheses = [];
  String? _message;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _digits = widget.problem.numbers.map((number) => '$number').toList();
    _operators =
        List.filled(_digits.length - 1, InlineOperator.add, growable: false);
  }

  String get _expression => assembleInlineExpression(
        digits: _digits,
        operators: _operators,
        parentheses: _parentheses,
      );

  @override
  Widget build(BuildContext context) {
    return _PuzzleCard(
      title: '모든 숫자를 사용해 목표값을 만드세요.'.tr,
      accent: widget.accent,
      child: Column(
        children: [
          _MetricTile(
            label: '목표값'.tr,
            value: '${widget.problem.target}',
            accent: true,
            accentColor: widget.accent,
            accentSoft: widget.accentSoft,
          ),
          const SizedBox(height: 16),
          _ExpressionPreview(
            expression: _expression,
            accent: widget.accent,
          ),
          const SizedBox(height: 14),
          Text(
            '화살표로 숫자 순서를 바꾸세요.'.tr,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_digits.length, (index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: index == 0 ? null : () => _move(index, -1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      _digits[index],
                      style: GoogleFonts.blackHanSans(fontSize: 22),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: index == _digits.length - 1
                          ? null
                          : () => _move(index, 1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          _InlineEditor(
            digits: _digits,
            operators: _operators,
            accent: widget.accent,
            accentSoft: widget.accentSoft,
            choices: const [
              InlineOperator.add,
              InlineOperator.subtract,
              InlineOperator.multiply,
              InlineOperator.divide,
            ],
            onOperatorChanged: (index, value) {
              setState(() => _operators[index] = value);
              _checkAnswer();
            },
          ),
          const SizedBox(height: 16),
          _ParenthesisControls(
            digitCount: _digits.length,
            ranges: _parentheses,
            onChanged: (ranges) {
              setState(() {
                _parentheses
                  ..clear()
                  ..addAll(ranges);
              });
              _checkAnswer();
            },
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _move(int index, int delta) {
    final next = index + delta;
    setState(() {
      final value = _digits.removeAt(index);
      _digits.insert(next, value);
      _parentheses.clear();
      _message = null;
    });
    _checkAnswer();
  }

  void _checkAnswer() {
    if (_solved) return;
    final result = validateNumberVault(
      numbers: widget.problem.numbers,
      target: widget.problem.target,
      expression: _expression,
    );
    if (result.valid) {
      _solved = true;
      widget.onSolved();
    } else {
      setState(() => _message = result.message);
    }
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.title,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.round,
    required this.score,
    required this.difficulty,
    required this.elapsed,
    required this.attempts,
    required this.onReset,
    required this.onExit,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final int round;
  final int score;
  final NumberingDifficulty difficulty;
  final Duration elapsed;
  final int? attempts;
  final VoidCallback onReset;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              SoftIconButton(
                icon: Icons.close_rounded,
                label: '홈'.tr,
                onPressed: onExit,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.blackHanSans(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SoftIconButton(
                icon: Icons.refresh_rounded,
                label: '초기화'.tr,
                onPressed: onReset,
                size: 44,
                iconSize: 22,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  difficulty.label,
                  style: AppTypography.label.copyWith(
                    color: accent,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${'라운드'.tr} $round',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${'점수'.tr} $score',
                style: GoogleFonts.blackHanSans(
                  fontSize: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                attempts == null
                    ? Icons.timer_outlined
                    : Icons.touch_app_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                attempts == null
                    ? _formatElapsed(elapsed)
                    : '${'시도'.tr} $attempts',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PuzzleCard extends StatelessWidget {
  const _PuzzleCard({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class _InlineEditor extends StatelessWidget {
  const _InlineEditor({
    required this.digits,
    required this.operators,
    required this.choices,
    required this.accent,
    required this.accentSoft,
    required this.onOperatorChanged,
  });

  final List<String> digits;
  final List<InlineOperator?> operators;
  final List<InlineOperator?> choices;
  final Color accent;
  final Color accentSoft;
  final void Function(int index, InlineOperator? value) onOperatorChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(digits.length * 2 - 1, (visualIndex) {
          if (visualIndex.isEven) {
            final digitIndex = visualIndex ~/ 2;
            return Container(
              width: 46,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: accent.withValues(alpha: 0.55)),
              ),
              child: Text(
                digits[digitIndex],
                style: GoogleFonts.blackHanSans(fontSize: 25),
              ),
            );
          }
          final slotIndex = visualIndex ~/ 2;
          final current = operators[slotIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () {
                final currentIndex = choices.indexOf(current);
                final next = choices[(currentIndex + 1) % choices.length];
                onOperatorChanged(slotIndex, next);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: current == null ? AppColors.background : accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  current?.symbol ?? '·',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 21,
                    color: current == null ? AppColors.textSecondary : accent,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ParenthesisControls extends StatefulWidget {
  const _ParenthesisControls({
    required this.digitCount,
    required this.ranges,
    required this.onChanged,
  });

  final int digitCount;
  final List<ParenthesisRange> ranges;
  final ValueChanged<List<ParenthesisRange>> onChanged;

  @override
  State<_ParenthesisControls> createState() => _ParenthesisControlsState();
}

class _ParenthesisControlsState extends State<_ParenthesisControls> {
  int _start = 0;
  int _end = 1;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('괄호'.tr, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 10),
            _IndexDropdown(
              value: _start,
              count: widget.digitCount,
              onChanged: (value) => setState(() => _start = value),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('~'),
            ),
            _IndexDropdown(
              value: _end.clamp(0, widget.digitCount - 1),
              count: widget.digitCount,
              onChanged: (value) => setState(() => _end = value),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _add,
              child: Text('추가'.tr),
            ),
          ],
        ),
        if (widget.ranges.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: widget.ranges.map((range) {
              final normalized = range.normalized();
              return InputChip(
                label: Text(
                  '(${normalized.startDigitIndex + 1}~${normalized.endDigitIndex + 1})',
                ),
                onDeleted: () {
                  final next = [...widget.ranges]..remove(range);
                  widget.onChanged(next);
                },
              );
            }).toList(),
          ),
        ],
        if (_error != null)
          Text(
            _error!,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
      ],
    );
  }

  void _add() {
    final candidate = ParenthesisRange(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      startDigitIndex: _start,
      endDigitIndex: _end,
    );
    final validation = validateParenthesisRange(
      digitCount: widget.digitCount,
      candidate: candidate,
      existing: widget.ranges,
    );
    if (!validation.valid) {
      setState(() => _error = validation.message);
      return;
    }
    setState(() => _error = null);
    widget.onChanged([...widget.ranges, candidate.normalized()]);
  }
}

class _IndexDropdown extends StatelessWidget {
  const _IndexDropdown({
    required this.value,
    required this.count,
    required this.onChanged,
  });

  final int value;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      items: List.generate(
        count,
        (index) => DropdownMenuItem(value: index, child: Text('${index + 1}')),
      ),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _NumberPicker extends StatelessWidget {
  const _NumberPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButton<int>(
            value: value,
            underline: const SizedBox.shrink(),
            style: GoogleFonts.blackHanSans(
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
            items: List.generate(
              9,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1}'),
              ),
            ),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ],
    );
  }
}

class _ExpressionPreview extends StatelessWidget {
  const _ExpressionPreview({
    required this.expression,
    required this.accent,
  });

  final String expression;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.all(AppSpacing.lg),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          expression,
          style: GoogleFonts.blackHanSans(fontSize: 30),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.accent = false,
    this.accentColor = AppColors.blue,
    this.accentSoft = const Color(0xFFE5F4FF),
  });

  final String label;
  final String value;
  final bool accent;
  final Color accentColor;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent ? accentSoft : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.blackHanSans(
              fontSize: 30,
              color: accent ? accentColor : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.text,
    required this.accent,
    required this.accentSoft,
    this.success = false,
  });

  final String text;
  final Color accent;
  final Color accentSoft;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: success ? AppColors.green.withValues(alpha: 0.16) : accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text(
        text.tr,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(
          color: success ? AppColors.green : accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
