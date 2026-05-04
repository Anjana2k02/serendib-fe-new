import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/dev_options_provider.dart';

class ScoreOverlay extends StatefulWidget {
  const ScoreOverlay({super.key});

  @override
  State<ScoreOverlay> createState() => _ScoreOverlayState();
}

class _ScoreOverlayState extends State<ScoreOverlay>
    with SingleTickerProviderStateMixin {
  Offset _pos = const Offset(16, 120);
  bool _isExpanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    setState(() {
      _pos = Offset(
        (_pos.dx + details.delta.dx).clamp(0, size.width - 180),
        (_pos.dy + details.delta.dy).clamp(0, size.height - 60),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: Consumer<DevOptionsProvider>(
        builder: (context, devOptions, _) {
          final dwells = devOptions.allCategoryDwells;
          final totalPts = dwells.fold<int>(
            0,
            (sum, e) => sum + (e.dwellTimeMs ~/ 1000),
          );

          return GestureDetector(
            onPanUpdate: _onPanUpdate,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBrown.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Card
                  Container(
                    constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(
                        color: AppColors.primaryBrown.withValues(alpha: 0.25),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header / collapsed pill
                        GestureDetector(
                          onTap: _toggleExpand,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBrown,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(AppConstants.radiusMd - 1),
                                topRight: Radius.circular(AppConstants.radiusMd - 1),
                                bottomLeft: Radius.circular(
                                    _isExpanded ? 0 : AppConstants.radiusMd - 1),
                                bottomRight: Radius.circular(
                                    _isExpanded ? 0 : AppConstants.radiusMd - 1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: AppColors.accentGold,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    dwells.isEmpty
                                        ? 'Visit Score'
                                        : 'Score: ${totalPts}pts',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AnimatedRotation(
                                  turns: _isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 250),
                                  child: const Icon(
                                    Icons.expand_more,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Expanded body
                        SizeTransition(
                          sizeFactor: _expandAnim,
                          axisAlignment: -1,
                          child: _ScoreBody(
                            dwells: dwells,
                            totalPts: totalPts,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScoreBody extends StatelessWidget {
  final List<CategoryDwellEntry> dwells;
  final int totalPts;

  const _ScoreBody({required this.dwells, required this.totalPts});

  @override
  Widget build(BuildContext context) {
    if (dwells.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.explore, color: AppColors.lightBrown, size: 16),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Start exploring to\nearn points!',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Max dwell among categories (for bar scaling)
    final maxMs = dwells
        .map((e) => e.dwellTimeMs)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY BREAKDOWN',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          ...dwells.map((e) => _CategoryScoreRow(entry: e, maxMs: maxMs)),
          const Divider(height: 12, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBrown,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  '${totalPts}pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryScoreRow extends StatelessWidget {
  final CategoryDwellEntry entry;
  final int maxMs;

  const _CategoryScoreRow({required this.entry, required this.maxMs});

  @override
  Widget build(BuildContext context) {
    final pts = entry.dwellTimeMs ~/ 1000;
    final barFraction = maxMs > 0 ? entry.dwellTimeMs / maxMs : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primaryBrown.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.primaryBrown.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '#${entry.categoryId}',
                  style: TextStyle(
                    color: AppColors.primaryBrown,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.artifactName,
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${pts}pt${pts == 1 ? '' : 's'}',
                style: TextStyle(
                  color: AppColors.primaryBrown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: barFraction,
              minHeight: 4,
              backgroundColor: AppColors.lightCream,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBrown),
            ),
          ),
        ],
      ),
    );
  }
}
