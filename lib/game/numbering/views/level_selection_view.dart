part of '../numbering_game_page.dart';

// ─── 레벨 선택 뷰 ─────────────────────────────────────────

// ─── 레벨 선택 뷰 ─────────────────────────────────────────

class _LevelSelectionView extends StatefulWidget {
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
  State<_LevelSelectionView> createState() => _LevelSelectionViewState();
}

class _LevelSelectionViewState extends State<_LevelSelectionView> {
  late final TransformationController _transformationController;
  late final List<Offset> _coords;
  LevelData? _selectedLevelForPopup;
  bool _hasCentered = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _coords = List.generate(200, (index) => _getNodeCoords(index + 1));
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Offset _getNodeCoords(int levelId) {
    const double mapWidth = 1200.0;
    const double mapHeight = 4200.0;
    const double gapX = 125.0;
    const double gapY = 150.0;
    const double marginX = (mapWidth - 7 * gapX) / 2;
    const double marginY = 120.0;

    int index = levelId - 1;
    int row = index ~/ 8;
    int col = index % 8;

    if (row % 2 == 1) {
      col = 7 - col;
    }

    double offsetX = sin(levelId * 1.5) * 18.0;
    double offsetY = cos(levelId * 1.2) * 12.0;

    double x = marginX + col * gapX + offsetX;
    double y = mapHeight - marginY - row * gapY + offsetY;

    return Offset(x, y);
  }

  void _centerOnLevel(int levelId, Size viewportSize) {
    final coords = _getNodeCoords(levelId);
    double dx = viewportSize.width / 2 - coords.dx;
    double dy = viewportSize.height / 2 - coords.dy;

    final double minX = viewportSize.width > 1200.0 ? 0.0 : viewportSize.width - 1200.0;
    final double maxX = viewportSize.width > 1200.0 ? (viewportSize.width - 1200.0) / 2 : 0.0;
    final double minY = viewportSize.height > 4200.0 ? 0.0 : viewportSize.height - 4200.0;
    final double maxY = viewportSize.height > 4200.0 ? (viewportSize.height - 4200.0) / 2 : 0.0;

    dx = dx.clamp(minX, maxX);
    dy = dy.clamp(minY, maxY);

    _transformationController.value = Matrix4.translationValues(dx, dy, 0.0);
  }

  String _getZoneName(int levelId) {
    int zoneIdx = (levelId - 1) ~/ 5;
    int cycle = zoneIdx ~/ 6;
    int type = zoneIdx % 6;

    String prefix = cycle == 0
        ? ''
        : cycle == 1
            ? '고급 '
            : cycle == 2
                ? '고차원 '
                : '마스터 ';

    String name = switch (type) {
      0 => '기본 숫자 섬',
      1 => '연산 마을',
      2 => '등호 다리',
      3 => '괄호 숲',
      4 => '조합 사막',
      _ => '최종 수식 성',
    };

    return '$prefix$name';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Obx(() {
          final highestLevel = widget.progress.highestUnlockedLevel;
          final records = Map<int, LevelProgress>.of(widget.progress.progress);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_hasCentered) {
              _hasCentered = true;
              _centerOnLevel(highestLevel, viewportSize);
            }
          });

          return Stack(
            children: [
              Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: const Color(0xFFF0F4F8),
                child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 1.5,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(80.0),
                    child: SizedBox(
                      width: 1200.0,
                      height: 4200.0,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MapPathPainter(
                                highestUnlocked: highestLevel,
                                nodeCoords: _coords,
                              ),
                            ),
                          ),
                          for (int i = 1; i <= 200; i += 5) ...[
                            _buildZoneTitle(i),
                          ],
                          for (final level in LevelCatalog.all) ...[
                            _buildMapNode(
                              level,
                              records[level.id] ?? LevelProgress(levelId: level.id),
                              level.id <= highestLevel,
                              level.id == highestLevel,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: SoftIconButton(
                          icon: Icons.arrow_back_rounded,
                          label: '뒤로 가기'.tr,
                          onPressed: widget.onExit,
                          size: 44,
                          iconSize: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '$highestLevel / 200',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedLevelForPopup != null) ...[
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 180),
                      builder: (context, anim, child) {
                        return Transform.translate(
                          offset: Offset(0, (1.0 - anim) * 20),
                          child: Opacity(
                            opacity: anim,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 340),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.borderLight, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'LEVEL ${_selectedLevelForPopup!.id}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0095FF),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => setState(() => _selectedLevelForPopup = null),
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getZoneName(_selectedLevelForPopup!.id),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Divider(height: 20, color: Color(0xFFE5E7EB)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '난이도',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '★' * _selectedLevelForPopup!.difficulty,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFFFFB800), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '목표 점수',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_selectedLevelForPopup!.targetScore}점',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      '최고 기록',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      records[_selectedLevelForPopup!.id]?.bestScore != null
                                          ? '${records[_selectedLevelForPopup!.id]!.bestScore}점'
                                          : '기록 없음',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  final id = _selectedLevelForPopup!.id;
                                  setState(() => _selectedLevelForPopup = null);
                                  widget.onSelect(id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0095FF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  '도전하기'.tr,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        });
      },
    );
  }

  Widget _buildMapNode(LevelData level, LevelProgress record, bool unlocked, bool isCurrent) {
    final coords = _coords[level.id - 1];

    return Positioned(
      left: coords.dx - 28,
      top: coords.dy - 28,
      child: GestureDetector(
        onTap: () {
          if (unlocked) {
            setState(() {
              _selectedLevelForPopup = level;
            });
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF0095FF)
                    : unlocked
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent
                      ? Colors.white
                      : unlocked
                          ? AppColors.green.withValues(alpha: 0.5)
                          : AppColors.borderLight,
                  width: isCurrent ? 3 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0095FF).withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Center(
                child: !unlocked
                    ? const Icon(Icons.lock_rounded, size: 20, color: Color(0xFFAAB0BA))
                    : Text(
                        '${level.id}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrent
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            if (unlocked && record.cleared)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (starIdx) {
                  final isLit = starIdx < record.stars;
                  return Icon(
                    isLit ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 11,
                    color: isLit ? const Color(0xFFFFB800) : AppColors.borderLight,
                  );
                }),
              )
            else if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0095FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PLAY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else
              const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneTitle(int levelId) {
    final coords = _coords[levelId - 1];

    return Positioned(
      left: coords.dx - 80,
      top: coords.dy - 72,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _getZoneName(levelId),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPathPainter extends CustomPainter {
  const _MapPathPainter({
    required this.highestUnlocked,
    required this.nodeCoords,
  });

  final int highestUnlocked;
  final List<Offset> nodeCoords;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCoords.isEmpty) return;

    final activePaint = Paint()
      ..color = const Color(0xFF0095FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < nodeCoords.length - 1; i++) {
      final p1 = nodeCoords[i];
      final p2 = nodeCoords[i + 1];
      final levelId = i + 1;
      final isActive = levelId < highestUnlocked;

      canvas.drawLine(p1, p2, isActive ? activePaint : inactivePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPathPainter oldDelegate) {
    return oldDelegate.highestUnlocked != highestUnlocked;
  }
}

