import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/dev_options_provider.dart';

/// Live dwell time overlay displayed over the map.
/// Only visible when developer options are enabled and the user is in "Standing" mode
/// near an artifact. Shows per-category accumulated dwell time in real time.
/// Can be dragged anywhere on screen.
class DwellTimeOverlay extends StatefulWidget {
  const DwellTimeOverlay({super.key});

  @override
  State<DwellTimeOverlay> createState() => _DwellTimeOverlayState();
}

class _DwellTimeOverlayState extends State<DwellTimeOverlay> {
  Offset? _pos; // null until first layout (initialised to bottom-right)

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    setState(() {
      final current = _pos!;
      _pos = Offset(
        (current.dx + details.delta.dx).clamp(0, size.width - 20),
        (current.dy + details.delta.dy).clamp(0, size.height - 20),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DevOptionsProvider>(
      builder: (context, devOptions, child) {
        if (!devOptions.developerOptionsEnabled) {
          return const SizedBox.shrink();
        }

        // Initialise position to bottom-right on first visible render
        if (_pos == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final size = MediaQuery.of(context).size;
            setState(() {
              _pos = Offset(
                size.width - 256,
                size.height - 220,
              );
            });
          });
          return const SizedBox.shrink();
        }

        final isStanding =
            devOptions.selectedActivity.toLowerCase() == 'standing';
        final nearbyArtifact = devOptions.nearbyArtifactName;
        final nearbyCategoryId = devOptions.nearbyCategoryId;
        final allDwells = devOptions.allCategoryDwells;

        return Positioned(
          left: _pos!.dx,
          top: _pos!.dy,
          child: GestureDetector(
            onPanUpdate: _onPanUpdate,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              decoration: BoxDecoration(
                color: isStanding
                    ? AppColors.darkBrown.withValues(alpha: 0.95)
                    : Colors.grey.shade800.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color: isStanding
                      ? AppColors.accentGold.withValues(alpha: 0.6)
                      : Colors.grey.shade600,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _Header(
                      isStanding: isStanding, nearbyArtifact: nearbyArtifact),

                  // ── Active category timer ──
                  if (nearbyArtifact != null && nearbyCategoryId != null)
                    _ActiveTimer(
                      devOptions: devOptions,
                      isStanding: isStanding,
                      categoryId: nearbyCategoryId,
                      artifactName: nearbyArtifact,
                    ),

                  // ── History: all categories visited ──
                  if (allDwells.isNotEmpty) ...[
                    const Divider(color: Colors.white12, height: 1),
                    _CategoryHistory(
                      entries: allDwells,
                      activeCategoryId: nearbyCategoryId,
                    ),
                  ],

                  // ── Sync status ──
                  _SyncStatus(
                      isStanding: isStanding,
                      hasCategoryId: nearbyCategoryId != null),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isStanding;
  final String? nearbyArtifact;

  const _Header({required this.isStanding, required this.nearbyArtifact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isStanding
            ? AppColors.accentGold.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusMd - 1),
          topRight: Radius.circular(AppConstants.radiusMd - 1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.developer_mode,
              color: AppColors.accentGold, size: 13),
          const SizedBox(width: 5),
          const Text(
            'DWELL TRACKER',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          // Drag hint icon
          const Icon(Icons.drag_indicator,
              color: Colors.white30, size: 14),
          if (isStanding && nearbyArtifact != null) ...[
            const SizedBox(width: 4),
            const _PulsingDot(),
          ],
        ],
      ),
    );
  }
}

// ── Active category timer ───────────────────────────────────────────────────
class _ActiveTimer extends StatelessWidget {
  final DevOptionsProvider devOptions;
  final bool isStanding;
  final int categoryId;
  final String artifactName;

  const _ActiveTimer({
    required this.devOptions,
    required this.isStanding,
    required this.categoryId,
    required this.artifactName,
  });

  @override
  Widget build(BuildContext context) {
    final ms = devOptions.dwellTimeMs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer display
          Row(
            children: [
              Icon(
                isStanding ? Icons.timer : Icons.timer_off,
                color:
                    isStanding ? AppColors.accentGold : Colors.grey.shade500,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTime(ms),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${ms}ms',
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          // Category row
          Row(
            children: [
              _Badge(
                label: 'c_id',
                value: '#$categoryId',
                color: AppColors.softGold,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  artifactName,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final cents = (ms % 1000) ~/ 10;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}.${cents.toString().padLeft(2, '0')}';
  }
}

// ── Category history ────────────────────────────────────────────────────────
class _CategoryHistory extends StatelessWidget {
  final List<CategoryDwellEntry> entries;
  final int? activeCategoryId;

  const _CategoryHistory({
    required this.entries,
    required this.activeCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CATEGORY DWELL LOG',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          ...entries.map((e) => _CategoryRow(
                entry: e,
                isActive: e.categoryId == activeCategoryId,
              )),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryDwellEntry entry;
  final bool isActive;

  const _CategoryRow({required this.entry, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final ms = entry.dwellTimeMs;
    final s = (ms / 1000).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Active indicator
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.success : Colors.white24,
            ),
          ),
          _Badge(
            label: 'c_id',
            value: '#${entry.categoryId}',
            color: isActive ? AppColors.softGold : Colors.white38,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entry.artifactName,
              style: TextStyle(
                color: isActive ? Colors.white70 : Colors.white38,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${s}s',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sync status bar ─────────────────────────────────────────────────────────
class _SyncStatus extends StatelessWidget {
  final bool isStanding;
  final bool hasCategoryId;

  const _SyncStatus({required this.isStanding, required this.hasCategoryId});

  @override
  Widget build(BuildContext context) {
    final syncing = isStanding && hasCategoryId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0x18FFFFFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.radiusMd - 1),
          bottomRight: Radius.circular(AppConstants.radiusMd - 1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            syncing ? Icons.sync : Icons.sync_disabled,
            color: syncing ? AppColors.success : Colors.white24,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            syncing ? 'Syncing to backend every 5s' : 'Sync paused',
            style: TextStyle(
              color: syncing ? Colors.white54 : Colors.white24,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small badge ─────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Badge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing dot ──────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: _anim.value * 0.5),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
