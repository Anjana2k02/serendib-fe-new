import 'dart:math';
import '../models/point_of_interest.dart';

/// DEPRECATED — Do NOT use this service for indoor routing.
///
/// This A* implementation requires [PointOfInterest.connectedPOIs] to be
/// populated for every POI, but [location.geojson] contains no connectivity
/// data — so this graph is always empty and [findRoute] always returns [].
///
/// ✅ Use [RouteGraph.snapAndPath] (via [GeoJsonRouteService.load]) instead.
/// That system builds its graph directly from [routes.geojson] and works
/// with the existing canvas-space coordinates out of the box.
@Deprecated('Use RouteGraph.snapAndPath() via GeoJsonRouteService instead.')
class PathfindingService {
  List<PointOfInterest> findRoute(
    PointOfInterest start,
    PointOfInterest end,
    Map<String, PointOfInterest> poiMap,
  ) {
    if (start.id == end.id) {
      return [start];
    }

    final openSet = PriorityQueue<_Node>((a, b) => a.fScore.compareTo(b.fScore));
    final closedSet = <String>{};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{};
    final fScore = <String, double>{};

    gScore[start.id] = 0;
    fScore[start.id] = _heuristic(start, end);
    openSet.add(_Node(start.id, fScore[start.id]!));

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst();
      final currentId = current.id;

      if (currentId == end.id) {
        return _reconstructPath(cameFrom, currentId, poiMap);
      }

      closedSet.add(currentId);

      final currentPOI = poiMap[currentId];
      if (currentPOI == null) continue;

      for (final neighborId in currentPOI.connectedPOIs) {
        if (closedSet.contains(neighborId)) continue;

        final neighbor = poiMap[neighborId];
        if (neighbor == null) continue;

        final tentativeGScore =
            (gScore[currentId] ?? double.infinity) +
            _distance(currentPOI, neighbor);

        if (tentativeGScore < (gScore[neighborId] ?? double.infinity)) {
          cameFrom[neighborId] = currentId;
          gScore[neighborId] = tentativeGScore;
          fScore[neighborId] = tentativeGScore + _heuristic(neighbor, end);

          if (!openSet.any((node) => node.id == neighborId)) {
            openSet.add(_Node(neighborId, fScore[neighborId]!));
          }
        }
      }
    }

    return [];
  }

  double _heuristic(PointOfInterest a, PointOfInterest b) {
    return _distance(a, b);
  }

  double _distance(PointOfInterest a, PointOfInterest b) {
    final dx = a.position.dx - b.position.dx;
    final dy = a.position.dy - b.position.dy;
    return sqrt(dx * dx + dy * dy);
  }

  List<PointOfInterest> _reconstructPath(
    Map<String, String> cameFrom,
    String current,
    Map<String, PointOfInterest> poiMap,
  ) {
    final path = <PointOfInterest>[];
    String? currentId = current;

    while (currentId != null) {
      final poi = poiMap[currentId];
      if (poi != null) {
        path.insert(0, poi);
      }
      currentId = cameFrom[currentId];
    }

    return path;
  }
}

class _Node {
  final String id;
  final double fScore;

  _Node(this.id, this.fScore);
}

class PriorityQueue<T> {
  final List<T> _items = [];
  final Comparator<T> _comparator;

  PriorityQueue(this._comparator);

  void add(T item) {
    _items.add(item);
    _items.sort(_comparator);
  }

  T removeFirst() {
    return _items.removeAt(0);
  }

  bool get isNotEmpty => _items.isNotEmpty;

  bool any(bool Function(T) test) {
    return _items.any(test);
  }
}
