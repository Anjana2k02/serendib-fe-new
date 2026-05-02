import 'dart:math';

// ---------------------------------------------------------------------------
// RouteNode
// ---------------------------------------------------------------------------

class RouteNode {
  final String key;

  /// X coordinate in canvas space (same as GeoJSON X — no flip needed).
  final double canvasX;

  /// Y coordinate in canvas space (= mapHeight − geoJsonY, Y-flip already applied
  /// by GeoJsonRouteService.load()). Matches the px/py values from _MapLocation.
  final double canvasY;

  const RouteNode({
    required this.key,
    required this.canvasX,
    required this.canvasY,
  });
}

// ---------------------------------------------------------------------------
// RouteEdge
// ---------------------------------------------------------------------------

class RouteEdge {
  final String toKey;
  final double weight;

  const RouteEdge({required this.toKey, required this.weight});
}

// ---------------------------------------------------------------------------
// GeoBBox  (kept for GeoJsonRouteService coordinate converters — raw GeoJSON space)
// ---------------------------------------------------------------------------

class GeoBBox {
  final double minX, maxX, minY, maxY;

  const GeoBBox({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  double get width => maxX - minX;
  double get height => (maxY - minY).abs();
}

// ---------------------------------------------------------------------------
// SnapPathResult  —  returned by RouteGraph.snapAndPath()
// ---------------------------------------------------------------------------

/// Holds the result of a snap-to-network + Dijkstra operation.
class SnapPathResult {
  /// Ordered list of graph nodes forming the shortest indoor path.
  /// Empty if no path was found.
  final List<RouteNode> path;

  /// The graph node that was snapped to from the [from] canvas-space point.
  final RouteNode fromSnap;

  /// The graph node that was snapped to from the [to] canvas-space point.
  final RouteNode toSnap;

  const SnapPathResult({
    required this.path,
    required this.fromSnap,
    required this.toSnap,
  });

  /// True when a valid path was found between the two snapped nodes.
  bool get hasPath => path.isNotEmpty;
}

// ---------------------------------------------------------------------------
// RouteGraph
// ---------------------------------------------------------------------------

class RouteGraph {
  final Map<String, RouteNode> nodes;
  final Map<String, List<RouteEdge>> adjacency;

  const RouteGraph({required this.nodes, required this.adjacency});

  bool get isEmpty => nodes.isEmpty;

  // -------------------------------------------------------------------------
  // nearestNode
  // -------------------------------------------------------------------------

  /// Find the nearest graph node to a canvas-space coordinate.
  ///
  /// [canvasX] and [canvasY] must be in canvas space (Y-flipped, origin = top-left),
  /// matching [RouteNode.canvasX] / [RouteNode.canvasY] and the px/py values
  /// produced by IndoorMapScreen._loadLocations() and _loadUserLocations().
  RouteNode? nearestNode(double canvasX, double canvasY) {
    RouteNode? nearest;
    double bestDist = double.infinity;

    for (final node in nodes.values) {
      final dx = node.canvasX - canvasX;
      final dy = node.canvasY - canvasY;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < bestDist) {
        bestDist = dist;
        nearest = node;
      }
    }

    return nearest;
  }

  // -------------------------------------------------------------------------
  // snapAndPath  —  Fix 5: snap-to-network + Dijkstra in one call
  // -------------------------------------------------------------------------

  /// Snaps two canvas-space points onto the route network, then runs Dijkstra
  /// between the snapped nodes.
  ///
  /// This is the primary entry point for all indoor routing. Callers pass
  /// canvas-space [fromX]/[fromY] and [toX]/[toY] (i.e. [_MapLocation.px] /
  /// [_MapLocation.py] directly) and receive a [SnapPathResult] containing the
  /// ordered path nodes and the snap anchors used.
  ///
  /// Returns a result with an empty [SnapPathResult.path] if the graph is empty
  /// or no route exists between the two points.
  ///
  /// Example:
  /// ```dart
  /// final result = graph.snapAndPath(
  ///   fromX: startLoc.px, fromY: startLoc.py,
  ///   toX:   destLoc.px,  toY:   destLoc.py,
  /// );
  /// if (result.hasPath) {
  ///   final offsets = result.path.map((n) => Offset(n.canvasX, n.canvasY)).toList();
  ///   // draw offsets on canvas …
  /// }
  /// ```
  SnapPathResult? snapAndPath({
    required double fromX,
    required double fromY,
    required double toX,
    required double toY,
  }) {
    if (isEmpty) return null;

    // Step 1 — Snap both points to the nearest graph node on the corridor network.
    final fromSnap = nearestNode(fromX, fromY);
    final toSnap   = nearestNode(toX,   toY);
    if (fromSnap == null || toSnap == null) return null;

    // Step 2 — Run Dijkstra between the two snapped node keys.
    final path = dijkstra(fromSnap.key, toSnap.key);

    return SnapPathResult(path: path, fromSnap: fromSnap, toSnap: toSnap);
  }

  // -------------------------------------------------------------------------
  // dijkstra
  // -------------------------------------------------------------------------

  /// Run Dijkstra from [startKey] to [endKey].
  /// Returns an ordered list of nodes forming the shortest path, or [] if unreachable.
  List<RouteNode> dijkstra(String startKey, String endKey) {
    if (startKey == endKey) {
      final n = nodes[startKey];
      return n != null ? [n] : [];
    }

    final dist    = <String, double>{startKey: 0.0};
    final prev    = <String, String>{};
    final visited = <String>{};

    final queue = _PriorityQueue<_DNode>((a, b) => a.dist.compareTo(b.dist));
    queue.add(_DNode(startKey, 0.0));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (visited.contains(current.key)) continue;
      visited.add(current.key);

      if (current.key == endKey) break;

      final edges = adjacency[current.key] ?? [];
      for (final edge in edges) {
        if (visited.contains(edge.toKey)) continue;
        final newDist = (dist[current.key] ?? double.infinity) + edge.weight;
        if (newDist < (dist[edge.toKey] ?? double.infinity)) {
          dist[edge.toKey] = newDist;
          prev[edge.toKey] = current.key;
          queue.add(_DNode(edge.toKey, newDist));
        }
      }
    }

    if (!prev.containsKey(endKey) && startKey != endKey) return [];

    // Reconstruct path
    final path = <RouteNode>[];
    String? cur = endKey;
    while (cur != null) {
      final node = nodes[cur];
      if (node != null) path.insert(0, node);
      cur = prev[cur];
    }

    return path;
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _DNode {
  final String key;
  final double dist;
  _DNode(this.key, this.dist);
}

class _PriorityQueue<T> {
  final List<T> _items = [];
  final Comparator<T> _cmp;

  _PriorityQueue(this._cmp);

  void add(T item) {
    _items.add(item);
    _items.sort(_cmp);
  }

  T removeFirst() => _items.removeAt(0);

  bool get isNotEmpty => _items.isNotEmpty;
}

