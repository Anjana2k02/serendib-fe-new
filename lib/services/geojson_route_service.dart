import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/route_graph.dart';

class GeoJsonRouteService {
  /// Must match IndoorMapScreen.mapHeight — the pixel height of the indoor map
  /// raster asset. Used to flip GeoJSON Y (origin = bottom-left) into canvas
  /// space (origin = top-left), so route graph nodes live in the same
  /// coordinate system as locations loaded by IndoorMapScreen._loadLocations().
  static const double _mapHeight = 1281.0;
  static const String _assetPath = 'assets/map-routes/routes.geojson';

  /// Loads and parses the GeoJSON, builds the route graph, and computes the bounding box.
  static Future<({RouteGraph graph, GeoBBox bbox})> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final features = json['features'] as List<dynamic>;
    if (features.isEmpty) {
      return (graph: const RouteGraph(nodes: {}, adjacency: {}), bbox: const GeoBBox(minX: 0, maxX: 1, minY: -1, maxY: 0));
    }

    // The first feature holds the MultiLineString
    final geometry = features[0]['geometry'] as Map<String, dynamic>;
    final multiLine = geometry['coordinates'] as List<dynamic>;

    final nodes = <String, RouteNode>{};
    final adjacency = <String, List<RouteEdge>>{};

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    String nodeKey(double x, double y) => '${x.round()}_${y.round()}';

    RouteNode getOrCreateNode(double x, double y) {
      // Node key uses raw GeoJSON coords for stable uniqueness within this file.
      // Stored canvasX/canvasY are flipped to canvas space so that nearestNode()
      // can accept canvas-space px/py values directly from _MapLocation.
      final key = nodeKey(x, y);
      return nodes.putIfAbsent(
        key,
        () => RouteNode(key: key, canvasX: x, canvasY: _mapHeight - y),
      );
    }

    for (final lineRaw in multiLine) {
      final line = lineRaw as List<dynamic>;
      if (line.length < 2) continue;

      for (final coordRaw in line) {
        final coord = coordRaw as List<dynamic>;
        final x = (coord[0] as num).toDouble();
        final y = (coord[1] as num).toDouble();
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }

      for (int i = 0; i < line.length - 1; i++) {
        final a = line[i] as List<dynamic>;
        final b = line[i + 1] as List<dynamic>;
        final ax = (a[0] as num).toDouble();
        final ay = (a[1] as num).toDouble();
        final bx = (b[0] as num).toDouble();
        final by = (b[1] as num).toDouble();

        final nodeA = getOrCreateNode(ax, ay);
        final nodeB = getOrCreateNode(bx, by);

        if (nodeA.key == nodeB.key) continue; // skip zero-length segments

        final dx = ax - bx;
        final dy = ay - by;
        final weight = sqrt(dx * dx + dy * dy);

        adjacency.putIfAbsent(nodeA.key, () => []).add(RouteEdge(toKey: nodeB.key, weight: weight));
        adjacency.putIfAbsent(nodeB.key, () => []).add(RouteEdge(toKey: nodeA.key, weight: weight));
      }
    }

    final bbox = GeoBBox(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
    return (graph: RouteGraph(nodes: nodes, adjacency: adjacency), bbox: bbox);
  }

  // ---------------------------------------------------------------------------
  // Coordinate converters (raw GeoJSON space ↔ display space)
  // NOTE: These helpers operate in raw GeoJSON coordinate space (Y not flipped).
  // They are kept for legacy use and are independent of the route graph nodes,
  // which are stored in canvas space after the Y-flip applied in load().
  // ---------------------------------------------------------------------------

  /// Converts a tap offset in display space back to raw GeoJSON coordinate space.
  /// [tapLocal] is relative to the top-left of the image as rendered (after letterboxing).
  static Offset displayToGeo(Offset tapLocal, Size imageDisplaySize, GeoBBox bbox) {
    final geoX = bbox.minX + (tapLocal.dx / imageDisplaySize.width) * (bbox.maxX - bbox.minX);
    // Y is flipped: top of image = maxY (less negative), bottom = minY (more negative)
    final geoY = bbox.maxY - (tapLocal.dy / imageDisplaySize.height) * (bbox.maxY - bbox.minY);
    return Offset(geoX, geoY);
  }

  /// Converts a raw GeoJSON coordinate to display-space offset within the rendered image rect.
  static Offset geoToDisplay(double geoX, double geoY, Size imageDisplaySize, GeoBBox bbox) {
    final dx = (geoX - bbox.minX) / (bbox.maxX - bbox.minX) * imageDisplaySize.width;
    // Flip Y
    final dy = (bbox.maxY - geoY) / (bbox.maxY - bbox.minY) * imageDisplaySize.height;
    return Offset(dx, dy);
  }

  /// Computes the letterbox rect for an image with [imageAspect] displayed BoxFit.contain
  /// inside [containerSize].
  static Rect letterboxRect(double imageAspect, Size containerSize) {
    final containerAspect = containerSize.width / containerSize.height;
    double w, h, left, top;
    if (imageAspect > containerAspect) {
      // Image is wider — letterbox top/bottom
      w = containerSize.width;
      h = w / imageAspect;
      left = 0;
      top = (containerSize.height - h) / 2;
    } else {
      // Image is taller — letterbox left/right
      h = containerSize.height;
      w = h * imageAspect;
      top = 0;
      left = (containerSize.width - w) / 2;
    }
    return Rect.fromLTWH(left, top, w, h);
  }
}
