import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/map_navigation_provider.dart';
import '../../core/constants/app_constants.dart';
import 'poi_marker.dart';
import 'route_overlay.dart';
import 'user_position_marker.dart';
import 'activity_status_widget.dart';

class InteractiveMapViewer extends StatefulWidget {
  const InteractiveMapViewer({super.key});

  @override
  State<InteractiveMapViewer> createState() => _InteractiveMapViewerState();
}

class _InteractiveMapViewerState extends State<InteractiveMapViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationNormal,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateToPosition(Offset position, {double scale = 3.0}) {
    final size = MediaQuery.of(context).size;
    final targetX = -position.dx * scale + size.width / 2;
    final targetY = -position.dy * scale + size.height / 2;

    final targetMatrix = Matrix4.identity()
      ..setTranslationRaw(targetX, targetY, 0.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.reset();
    _animationController.forward();

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapNavigationProvider>(
      builder: (context, provider, child) {
        if (provider.selectedPOI != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animateToPosition(provider.selectedPOI!.position);
          });
        }

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              constrained: false,
              child: SizedBox(
                width: 1000,
                height: 800,
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: SvgPicture.asset(
                        'assets/maps/museum_floor_plan.svg',
                        width: 1000,
                        height: 800,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (provider.activeRoute != null)
                      RouteOverlay(route: provider.activeRoute!),
                    if (provider.userPosition != null)
                      UserPositionMarker(position: provider.userPosition!),
                    ...provider.pois.map((poi) => POIMarker(poi: poi)),
                  ],
                ),
              ),
            ),
            // Activity status overlay (fixed position, top-right corner)
            const ActivityStatusWidget(),
          ],
        );
      },
    );
  }
}
