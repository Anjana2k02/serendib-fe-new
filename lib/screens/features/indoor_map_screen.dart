import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/dev_options_provider.dart';
import '../../providers/artifact_provider.dart';
import '../../widgets/category_artifacts_sheet.dart';
import '../../widgets/navigation/dwell_time_overlay.dart';
import '../../models/route_graph.dart';
import '../../services/geojson_route_service.dart';
import '../../services/onboarding_api_service.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
class _MapLocation {
  final int id;
  final int? cId;
  final String name;
  final double px;
  final double py;
  const _MapLocation(
      {required this.id,
      this.cId,
      required this.name,
      required this.px,
      required this.py});
}

// ---------------------------------------------------------------------------
// Theme colours
// ---------------------------------------------------------------------------
const _kDarkBrown = Color(0xFF4E342E);
const _kMedBrown = Color(0xFF6D4C41);
const _kLightBrown = Color(0xFF8D6E63);
const _kCreamBrown = Color(0xFFBCAAA4);

// ---------------------------------------------------------------------------
// Category → icon / colour helpers
// ---------------------------------------------------------------------------
IconData _categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('ancient') || n.contains('artifact')) return Icons.auto_awesome;
  if (n.contains('coin')) return Icons.monetization_on;
  if (n.contains('traditional') || n.contains('art')) return Icons.palette;
  if (n.contains('architect')) return Icons.account_balance;
  if (n.contains('kandy')) return Icons.history_edu;
  if (n.contains('king') || n.contains('royal')) return Icons.workspace_premium;
  if (n.contains('culture')) return Icons.language;
  if (n.contains('statue') || n.contains('skulture')) return Icons.accessibility_new;
  if (n.contains('tech')) return Icons.precision_manufacturing;
  return Icons.place;
}

Color _categoryColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('ancient') || n.contains('artifact')) return const Color(0xFF5D4037);
  if (n.contains('coin')) return const Color(0xFF6D4C41);
  if (n.contains('traditional') || n.contains('art')) return const Color(0xFF795548);
  if (n.contains('architect')) return const Color(0xFF4E342E);
  if (n.contains('kandy')) return const Color(0xFF5D4037);
  if (n.contains('king') || n.contains('royal')) return const Color(0xFF4A2C2A);
  if (n.contains('culture')) return const Color(0xFF6D4C41);
  if (n.contains('statue')) return const Color(0xFF5D4037);
  if (n.contains('tech')) return const Color(0xFF795548);
  return _kMedBrown;
}

IconData _utilityIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('entran') || n.contains('entrance')) return Icons.login;
  if (n.contains('exit')) return Icons.logout;
  if (n.contains('toilet') || n.contains('wc')) return Icons.wc;
  if (n.contains('ticket')) return Icons.confirmation_number;
  if (n.contains('rest')) return Icons.chair;
  return Icons.place;
}

Color _utilityColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('entran') || n.contains('entrance')) return const Color(0xFF2E7D32);
  if (n.contains('exit')) return const Color(0xFFC62828);
  if (n.contains('toilet') || n.contains('wc')) return const Color(0xFF1565C0);
  if (n.contains('ticket')) return const Color(0xFFE65100);
  return const Color(0xFF546E7A);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class IndoorMapScreen extends StatefulWidget {
  const IndoorMapScreen({super.key});

  @override
  State<IndoorMapScreen> createState() => _IndoorMapScreenState();
}

class _IndoorMapScreenState extends State<IndoorMapScreen> {
  static const double _minMapScale = 0.3;
  static const double _maxMapScale = 5.0;

  final TransformationController _transformationController =
      TransformationController();

  List<List<Offset>> routeSegments = [];
  List<_MapLocation> _locations = [];
  List<_MapLocation> _otherLocations = [];
  List<_MapLocation> _userLocations = [];
  _MapLocation? _selectedUserLocation;

  // Routing state
  RouteGraph? _routeGraph;
  List<String> _userInterests = [];
  bool _isNavigating = false;
  List<Offset> _navigationPath = [];
  List<_MapLocation> _navigationStops = []; // Points in visit order
  final OnboardingApiService _onboardingService = OnboardingApiService();

  bool isLoading = true;
  String errorMessage = '';
  bool _hasInitializedMapView = false;

  // Tap detection inside InteractiveViewer
  Offset? _interactionStartFocalPoint;
  bool _isInteractionPan = false;

  // Map dimensions for the indoor map raster asset.
  static const double mapWidth = 940;
  static const double mapHeight = 1281;

  // Proximity radius (in map pixels) for nearby artifact detection.
  static const double _proximityThreshold = 120.0;

  @override
  void initState() {
    super.initState();
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ArtifactProvider>();
      if (provider.artifacts.isEmpty && !provider.isLoading) {
        provider.fetchArtifacts();
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Tap detection via InteractiveViewer interaction callbacks
  // -------------------------------------------------------------------------
  void _onInteractionStart(ScaleStartDetails details) {
    _interactionStartFocalPoint = details.focalPoint;
    _isInteractionPan = false;
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    if (details.focalPointDelta.distance > 6.0 ||
        (details.scale - 1.0).abs() > 0.02) {
      _isInteractionPan = true;
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    if (!_isInteractionPan && _interactionStartFocalPoint != null) {
      _handleMapTap(_interactionStartFocalPoint!);
    }
    _interactionStartFocalPoint = null;
    _isInteractionPan = false;
  }

  void _handleMapTap(Offset globalFocalPoint) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPos = box.globalToLocal(globalFocalPoint);
    final matrix = _transformationController.value;
    final inverse = Matrix4.inverted(matrix);
    final mapPos = MatrixUtils.transformPoint(inverse, localPos);

    const double hitRadius = 28.0;
    for (final loc in _locations) {
      final dx = loc.px - mapPos.dx;
      final dy = loc.py - mapPos.dy;
      if (dx * dx + dy * dy <= hitRadius * hitRadius) {
        _onCategoryTap(loc);
        return;
      }
    }
  }

  void _onCategoryTap(_MapLocation loc) {
    final artifacts =
        context.read<ArtifactProvider>().getArtifactsForLocation(loc.name);
    showCategoryArtifactsSheet(context, loc.name, artifacts);
  }

  void _onUtilityTap(_MapLocation loc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_utilityIcon(loc.name), color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(loc.name),
          ],
        ),
        backgroundColor: _utilityColor(loc.name),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Nearby artifact detection
  // -------------------------------------------------------------------------

  /// Checks for a nearby artifact when the user is standing.
  /// [userLoc] and [activity] can be passed directly to avoid setState timing issues;
  /// if omitted, falls back to [_selectedUserLocation] and [DevOptionsProvider.selectedActivity].
  void _checkNearbyArtifacts({_MapLocation? userLoc, String? activity}) {
    final loc = userLoc ?? _selectedUserLocation;
    if (loc == null) return;

    final act =
        activity ?? context.read<DevOptionsProvider>().selectedActivity;

    if (act.toLowerCase() != 'standing') {
      debugPrint('[Proximity] Activity="$act" — skipping check.');
      return;
    }

    debugPrint(
        '[Proximity] STANDING at (${loc.px.toStringAsFixed(1)}, ${loc.py.toStringAsFixed(1)}). Scanning artifacts...');

    _MapLocation? nearest;
    double nearestDist = double.infinity;
    for (final artifact in _locations) {
      final dx = artifact.px - loc.px;
      final dy = artifact.py - loc.py;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = artifact;
      }
    }

    if (nearest != null && nearestDist <= _proximityThreshold) {
      debugPrint(
          '[Proximity] ✓ Nearby: "${nearest.name}" | c_id=${nearest.cId} | dist=${nearestDist.toStringAsFixed(1)}px');

      // Update the dev options provider with the nearest artifact for dwell tracking
      context.read<DevOptionsProvider>().setNearbyArtifact(
            nearest.name,
            nearest.cId,
            artifactLocationId: nearest.id,
          );

      _promptNearbyArtifact(nearest, nearestDist);
    } else {
      debugPrint(
          '[Proximity] ✗ No artifact within ${_proximityThreshold}px. Closest: "${nearest?.name}" at ${nearestDist.toStringAsFixed(1)}px');

      // Clear the nearby artifact when out of range
      context.read<DevOptionsProvider>().clearNearbyArtifact();
    }
  }

  /// Shows a floating SnackBar with the nearby artifact's name and c_id.
  void _promptNearbyArtifact(_MapLocation loc, double distance) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearby: ${loc.name}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Category ID: ${loc.cId}  •  ${distance.toStringAsFixed(0)}px away',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _kMedBrown,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }


  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------
  Future<void> _loadAll() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final futures = await Future.wait([
        _loadRoutes(),
        _loadLocations(),
        _loadOtherLocations(),
        _loadUserLocations(),
        GeoJsonRouteService.load(),
        _loadUserInterests(),
      ]);
      final graphResult = futures[4] as ({RouteGraph graph, GeoBBox bbox});
      _routeGraph = graphResult.graph;

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load map data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadRoutes() async {
    final raw = await rootBundle.loadString('assets/map-routes/routes.geojson');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    final segments = <List<Offset>>[];

    for (final feature in features) {
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;

      List<List<dynamic>> lines = [];
      if (type == 'LineString') {
        lines = [geometry['coordinates'] as List<dynamic>];
      } else if (type == 'MultiLineString') {
        lines = (geometry['coordinates'] as List<dynamic>)
            .map((l) => l as List<dynamic>)
            .toList();
      }

      for (final line in lines) {
        final seg = <Offset>[];
        for (final coord in line) {
          final c = coord as List<dynamic>;
          seg.add(Offset(
            (c[0] as num).toDouble(),
            mapHeight - (c[1] as num).toDouble(),
          ));
        }
        if (seg.isNotEmpty) segments.add(seg);
      }
    }

    routeSegments = segments;
  }

  Future<void> _loadLocations() async {
    final raw =
        await rootBundle.loadString('assets/map-routes/location.geojson');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    final locs = <_MapLocation>[];

    for (final feature in features) {
      final props = feature['properties'] as Map<String, dynamic>;
      final coords = (feature['geometry']['coordinates'] as List<dynamic>);
      locs.add(_MapLocation(
        id: (props['id'] as num).toInt(),
        cId: props['c_id'] != null ? (props['c_id'] as num).toInt() : null,
        name: (props['Category Name'] ?? props['name'] ?? '') as String,
        px: (coords[0] as num).toDouble(),
        py: mapHeight - (coords[1] as num).toDouble(),
      ));
    }

    _locations = locs;
  }

  Future<void> _loadOtherLocations() async {
    final raw =
        await rootBundle.loadString('assets/map-routes/other.geojson');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    final locs = <_MapLocation>[];

    for (final feature in features) {
      final props = feature['properties'] as Map<String, dynamic>;
      final coords = (feature['geometry']['coordinates'] as List<dynamic>);
      locs.add(_MapLocation(
        id: (props['id'] as num).toInt(),
        name: (props['Category Name'] ?? props['name'] ?? '') as String,
        px: (coords[0] as num).toDouble(),
        py: mapHeight - (coords[1] as num).toDouble(),
      ));
    }

    _otherLocations = locs;
  }

  Future<void> _loadUserLocations() async {
    final raw =
        await rootBundle.loadString('assets/user/userlocation.geojson');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    final locs = <_MapLocation>[];

    for (final feature in features) {
      final props = feature['properties'] as Map<String, dynamic>;
      final coords = (feature['geometry']['coordinates'] as List<dynamic>);
      locs.add(_MapLocation(
        id: (props['id'] as num).toInt(),
        name: props['name'] as String,
        px: (coords[0] as num).toDouble(),
        py: mapHeight - (coords[1] as num).toDouble(),
      ));
    }

    _userLocations = locs;
  }

  Future<void> _loadUserInterests() async {
    try {
      final response = await _onboardingService.getOnboardingResponse();
      if (response != null && response['interests'] != null) {
        _userInterests = (response['interests'] as List).map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('Failed to load user interests: $e');
    }
  }

  void _scheduleInitialMapView(Size viewportSize) {
    if (_hasInitializedMapView ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasInitializedMapView) return;

      final fitScale = min(
        viewportSize.width / mapWidth,
        viewportSize.height / mapHeight,
      );
      final initialScale = min(1.0, max(_minMapScale, fitScale));
      final dx = (viewportSize.width - mapWidth * initialScale) / 2;
      final dy = (viewportSize.height - mapHeight * initialScale) / 2;

      _transformationController.value = Matrix4.identity()
        ..setTranslationRaw(dx, dy, 0.0)
        ..scaleByDouble(initialScale, initialScale, 1.0, 1.0);

      _hasInitializedMapView = true;
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final devOptions = context.watch<DevOptionsProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        title: const Text('Museum Indoor Map'),
        bottom: devOptions.developerOptionsEnabled
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildDevBar(devOptions),
              )
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _kMedBrown))
          : errorMessage.isNotEmpty
              ? _buildError()
              : Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        _scheduleInitialMapView(constraints.biggest);

                        return InteractiveViewer(
                          transformationController: _transformationController,
                          constrained: false,
                          minScale: _minMapScale,
                          maxScale: _maxMapScale,
                          onInteractionStart: _onInteractionStart,
                          onInteractionUpdate: _onInteractionUpdate,
                          onInteractionEnd: _onInteractionEnd,
                          child: SizedBox(
                            width: mapWidth,
                            height: mapHeight,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Base indoor map image
                                Image.asset(
                                  'assets/maps/indoor_map.png',
                                  width: mapWidth,
                                  height: mapHeight,
                                  fit: BoxFit.fill,
                                ),
                                // Walking paths
                                CustomPaint(
                                  size: const Size(mapWidth, mapHeight),
                                  painter: _NetworkPainter(
                                      routeSegments: routeSegments),
                                ),
                                // Navigation route (if any)
                                if (_navigationPath.isNotEmpty)
                                  CustomPaint(
                                    size: const Size(mapWidth, mapHeight),
                                    painter: _NavigationPainter(path: _navigationPath),
                                  ),
                                // Utility markers (other.geojson)
                                ..._otherLocations
                                    .map((loc) => _buildUtilityMarker(loc)),
                                // Category artifact markers (location.geojson)
                                ..._locations
                                    .map((loc) => _buildCategoryMarker(loc)),
                                // Selected user location marker
                                if (_selectedUserLocation != null)
                                  _buildUserLocationMarker(_selectedUserLocation!),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Live dwell time overlay (bottom-right, developer option)
                    const DwellTimeOverlay(),
                  ],
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleNavigation,
        backgroundColor: _isNavigating ? Colors.red.shade700 : _kDarkBrown,
        foregroundColor: Colors.white,
        icon: Icon(_isNavigating ? Icons.stop : Icons.directions),
        label: Text(_isNavigating ? 'Stop Navigation' : 'Start Navigation'),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9E7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Icon(Icons.error_outline,
                  color: Colors.red.shade700, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kMedBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Routing Logic
  // -------------------------------------------------------------------------

  int? _getCIdForInterest(String interest) {
    final lower = interest.toLowerCase();
    if (lower.contains('coin')) return 1;
    if (lower.contains('ancient') || lower.contains('artifact')) return 2;
    if (lower.contains('kandy') || lower.contains('king') || lower.contains('royal')) return 3;
    if (lower.contains('statue')) return 6;
    if (lower.contains('culture')) return 7;
    if (lower.contains('tech')) return 8;
    if (lower.contains('architect')) return 9;
    if (lower.contains('traditional') || lower.contains('art')) return 10;
    
    for (final loc in _locations) {
      if (loc.cId != null && loc.name.toLowerCase() == lower) {
        return loc.cId;
      }
    }
    return null;
  }

  void _toggleNavigation() {
    if (_isNavigating) {
      setState(() {
        _isNavigating = false;
        _navigationPath.clear();
        _navigationStops.clear();
      });
    } else {
      if (_selectedUserLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start location from the Dev Bar first.')),
        );
        return;
      }
      if (_userInterests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No interests found from your profile.')),
        );
        return;
      }
      _calculateRoute();
    }
  }

  void _calculateRoute() {
    if (_selectedUserLocation == null || _routeGraph == null) return;

    Set<int> selectedCIds = {};
    for (String interest in _userInterests) {
      int? cid = _getCIdForInterest(interest);
      if (cid != null) {
        selectedCIds.add(cid);
      }
    }

    if (selectedCIds.isEmpty) return;
    if (selectedCIds.length > 3) {
      selectedCIds = selectedCIds.take(3).toSet();
    }

    final targetsByCid = <int, List<_MapLocation>>{};
    for (final cid in selectedCIds) {
      targetsByCid[cid] = _locations.where((l) => l.cId == cid).toList();
    }

    _MapLocation current = _selectedUserLocation!;
    final List<_MapLocation> categoryBest = [];
    for (final cid in selectedCIds) {
      final list = targetsByCid[cid]!;
      if (list.isEmpty) continue;

      _MapLocation? nearest;
      double minDist = double.infinity;
      for (final loc in list) {
        final dist = pow(loc.px - current.px, 2) + pow(loc.py - current.py, 2);
        if (dist < minDist) {
          minDist = dist.toDouble();
          nearest = loc;
        }
      }
      if (nearest != null) categoryBest.add(nearest);
    }

    final List<_MapLocation> visitOrder = [];
    while (categoryBest.isNotEmpty) {
      _MapLocation? nextLoc;
      double minDist = double.infinity;
      for (final loc in categoryBest) {
        final dist = pow(loc.px - current.px, 2) + pow(loc.py - current.py, 2);
        if (dist < minDist) {
          minDist = dist.toDouble();
          nextLoc = loc;
        }
      }
      if (nextLoc != null) {
        visitOrder.add(nextLoc);
        categoryBest.remove(nextLoc);
        current = nextLoc;
      } else {
        break;
      }
    }

    final List<Offset> mergedPath = [];
    _MapLocation start = _selectedUserLocation!;
    for (final end in visitOrder) {
      final res = _routeGraph!.snapAndPath(
        fromX: start.px, fromY: start.py,
        toX: end.px, toY: end.py,
      );
      if (res != null && res.hasPath) {
        final seg = res.path.map((n) => Offset(n.canvasX, n.canvasY)).toList();
        if (mergedPath.isNotEmpty && seg.isNotEmpty) {
          mergedPath.addAll(seg.skip(1));
        } else {
          mergedPath.addAll(seg);
        }
      }
      start = end;
    }

    setState(() {
      _navigationPath = mergedPath;
      _navigationStops = visitOrder;
      _isNavigating = true;
    });
  }

  // -------------------------------------------------------------------------
  // Marker widgets
  // -------------------------------------------------------------------------

  /// Artifact category marker — tappable, brown gradient, opens artifact sheet.
  Widget _buildCategoryMarker(_MapLocation loc) {
    final color = _categoryColor(loc.name);
    final icon = _categoryIcon(loc.name);
    const double size = 38;

    int stopIndex = _navigationStops.indexOf(loc);
    bool isStop = stopIndex != -1;

    // Hide non-selected category markers during navigation
    if (_isNavigating && !isStop) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: loc.px - size / 2,
      top: loc.py - size / 2 - 10,
      child: GestureDetector(
        onTap: () => _onCategoryTap(loc),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle button
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(color, Colors.white, 0.25)!,
                        color,
                        Color.lerp(color, _kDarkBrown, 0.4)!,
                      ],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 2,
                        spreadRadius: 0,
                        offset: const Offset(-1, -1),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (isStop)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ]
                      ),
                      child: Text(
                        '${stopIndex + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            // Name label
            Container(
              constraints: const BoxConstraints(maxWidth: 80),
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                loc.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Utility marker (Entrance / Exit / Toilet / Ticket Counter) — tappable.
  Widget _buildUtilityMarker(_MapLocation loc) {
    final color = _utilityColor(loc.name);
    final icon = _utilityIcon(loc.name);
    const double size = 32;

    return Positioned(
      left: loc.px - size / 2,
      top: loc.py - size / 2 - 8,
      child: GestureDetector(
        onTap: () => _onUtilityTap(loc),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle button
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 2),
            // Name label
            Container(
              constraints: const BoxConstraints(maxWidth: 64),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                loc.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLocationMarker(_MapLocation loc) {
    return Positioned(
      left: loc.px - 18,
      top: loc.py - 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.person_pin, color: Colors.white, size: 20),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade700.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              loc.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Dev bar
  // -------------------------------------------------------------------------
  Widget _buildDevBar(DevOptionsProvider devOptions) {
    const labelStyle = TextStyle(color: Colors.white70, fontSize: 11);
    const dropdownStyle = TextStyle(color: Colors.white, fontSize: 12);

    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Text('Loc:', style: labelStyle),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: _selectedUserLocation?.name,
            hint: Text('Select...', style: dropdownStyle),
            isDense: true,
            dropdownColor: Colors.brown.shade800,
            style: dropdownStyle,
            underline: const SizedBox.shrink(),
            iconEnabledColor: Colors.white70,
            items: _userLocations
                .map((l) => DropdownMenuItem(
                    value: l.name,
                    child: Text(l.name, style: dropdownStyle)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                final newLoc = _userLocations.firstWhere((l) => l.name == v);
                setState(() {
                  _selectedUserLocation = newLoc;
                });
                _checkNearbyArtifacts(userLoc: newLoc);
              }
            },
          ),
          const SizedBox(width: 16),
          const Text('Activity:', style: labelStyle),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: devOptions.selectedActivity,
            isDense: true,
            dropdownColor: Colors.brown.shade800,
            style: dropdownStyle,
            underline: const SizedBox.shrink(),
            iconEnabledColor: Colors.white70,
            items: DevOptionsProvider.activities
                .map((a) => DropdownMenuItem(
                    value: a, child: Text(a, style: dropdownStyle)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                context.read<DevOptionsProvider>().setSelectedActivity(v);
                _checkNearbyArtifacts(activity: v);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------
class _NetworkPainter extends CustomPainter {
  final List<List<Offset>> routeSegments;
  _NetworkPainter({required this.routeSegments});

  @override
  void paint(Canvas canvas, Size size) {
    if (routeSegments.isEmpty) return;
    final pathPaint = Paint()
      ..color = _kLightBrown.withValues(alpha: 0.7)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final seg in routeSegments) {
      if (seg.isEmpty) continue;
      final path = Path()..moveTo(seg[0].dx, seg[0].dy);
      for (final pt in seg.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      _drawDashedPath(canvas, path, pathPaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLength = 10.0;
    const gapLength = 7.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_NetworkPainter old) =>
      old.routeSegments != routeSegments;
}

class _NavigationPainter extends CustomPainter {
  final List<Offset> path;
  _NavigationPainter({required this.path});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pathObj = Path()..moveTo(path[0].dx, path[0].dy);
    for (final pt in path.skip(1)) {
      pathObj.lineTo(pt.dx, pt.dy);
    }

    canvas.drawPath(pathObj, paint);
  }

  @override
  bool shouldRepaint(_NavigationPainter old) => old.path != path;
}
