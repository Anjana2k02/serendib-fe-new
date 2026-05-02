import 'dart:async';
import 'package:flutter/material.dart';
import '../services/user_score_service.dart';

/// Holds per-category accumulated dwell time data.
class CategoryDwellEntry {
  final int categoryId;
  final String artifactName;
  int dwellTimeMs;

  CategoryDwellEntry({
    required this.categoryId,
    required this.artifactName,
    this.dwellTimeMs = 0,
  });
}

/// Provider for Developer Options including category-wise dwell time tracking.
///
/// Design:
///   - A per-category map tracks total accumulated dwell time (always increasing).
///   - A 50ms UI timer ticks while the user is "standing" near an artifact,
///     incrementing the current category's counter for a live display.
///   - A separate 5-second POST timer sends incremental dwell time to the
///     backend (track-dwell-time endpoint) for real-time persistence.
class DevOptionsProvider extends ChangeNotifier {
  bool _developerOptionsEnabled = true;
  String _selectedLocation = 'Location A';
  String _selectedActivity = 'Standing';

  // ---- Per-category dwell state ----
  /// categoryId → accumulated dwell time in ms (for UI display)
  final Map<int, CategoryDwellEntry> _categoryDwell = {};

  // ---- Current artifact context ----
  String? _nearbyArtifactName;
  int? _nearbyCategoryId;
  int? _nearbyArtifactId;       // location/artifact id for API call

  // ---- UI tick timer (50ms) ----
  Timer? _uiTimer;
  int _sessionBaseMs = 0;       // category total at session start
  DateTime? _sessionStart;

  // ---- Backend sync timer (5s) ----
  Timer? _syncTimer;
  int _lastSyncedMs = 0;        // what we last sent to backend

  final UserScoreService _userScoreService = UserScoreService();

  // ---- Dev bar options ----
  static const List<String> locations = [
    'Location A',
    'Location B',
    'Location C',
    'Location D',
    'Location E',
    'Location F',
    'Location G',
  ];

  static const List<String> activities = [
    'Standing',
    'Sitting',
    'Walking',
    'Not Found',
  ];

  // ---- Getters ----

  bool get developerOptionsEnabled => _developerOptionsEnabled;
  String get selectedLocation => _selectedLocation;
  String get selectedActivity => _selectedActivity;

  /// Name of the nearest artifact (null if none nearby)
  String? get nearbyArtifactName => _nearbyArtifactName;

  /// Category ID of the nearest artifact (null if none nearby)
  int? get nearbyCategoryId => _nearbyCategoryId;

  /// Whether the UI dwell timer is currently running
  bool get isDwellTimerActive => _uiTimer != null && _uiTimer!.isActive;

  /// Current accumulated dwell time (ms) for the active artifact's category.
  /// Returns 0 if no artifact is nearby.
  int get dwellTimeMs {
    if (_nearbyCategoryId == null) return 0;
    return _categoryDwell[_nearbyCategoryId!]?.dwellTimeMs ?? 0;
  }

  /// All per-category dwell entries (for overlay display).
  List<CategoryDwellEntry> get allCategoryDwells =>
      _categoryDwell.values.toList();

  // ---- Setters ----

  void setDeveloperOptions(bool value) {
    _developerOptionsEnabled = value;
    if (!value) {
      _stopAll();
      _categoryDwell.clear();
      _nearbyArtifactName = null;
      _nearbyCategoryId = null;
      _nearbyArtifactId = null;
    }
    notifyListeners();
  }

  void setSelectedLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void setSelectedActivity(String activity) {
    _selectedActivity = activity;

    if (activity.toLowerCase() == 'standing' && _nearbyArtifactName != null) {
      _startTimers();
    } else {
      _stopTimers();
    }

    notifyListeners();
  }

  // ---- Dwell time methods ----

  /// Called by IndoorMapScreen when a nearby artifact is detected.
  /// [artifactLocationId] is the location `id` from location.geojson (used as artifactId in API).
  void setNearbyArtifact(String artifactName, int? categoryId, {int? artifactLocationId}) {
    final previousCategoryId = _nearbyCategoryId;
    final categoryChanged = categoryId != previousCategoryId;

    _nearbyArtifactName = artifactName;
    _nearbyCategoryId = categoryId;
    _nearbyArtifactId = artifactLocationId;

    if (categoryId != null) {
      // Ensure an entry exists for this category
      _categoryDwell.putIfAbsent(
        categoryId,
        () => CategoryDwellEntry(
          categoryId: categoryId,
          artifactName: artifactName,
        ),
      );
    }

    if (_selectedActivity.toLowerCase() == 'standing') {
      if (categoryChanged) {
        // Flush current accumulated delta to backend before switching categories
        _syncToBackend();
        _stopTimers();
        _lastSyncedMs = _categoryDwell[categoryId]?.dwellTimeMs ?? 0;
      }
      _startTimers();
    }

    notifyListeners();
  }

  /// Called when user moves out of range of all artifacts.
  void clearNearbyArtifact() {
    _syncToBackend(); // flush before clearing
    _stopTimers();
    _nearbyArtifactName = null;
    _nearbyCategoryId = null;
    _nearbyArtifactId = null;
    notifyListeners();
  }

  /// Reset all accumulated dwell times.
  void resetAllDwellTimes() {
    _stopAll();
    _categoryDwell.clear();
    _lastSyncedMs = 0;
    notifyListeners();
  }

  // ---- Timer management ----

  void _startTimers() {
    _startUiTimer();
    _startSyncTimer();
  }

  void _stopTimers() {
    _stopUiTimer();
    _stopSyncTimer();
  }

  void _stopAll() {
    _stopTimers();
    _sessionStart = null;
    _lastSyncedMs = 0;
  }

  // -- UI timer (50ms tick) --

  void _startUiTimer() {
    if (_uiTimer != null && _uiTimer!.isActive) return;
    if (_nearbyCategoryId == null) return;

    _sessionBaseMs = _categoryDwell[_nearbyCategoryId!]?.dwellTimeMs ?? 0;
    _sessionStart = DateTime.now();

    _uiTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_sessionStart != null && _nearbyCategoryId != null) {
        final elapsed =
            DateTime.now().difference(_sessionStart!).inMilliseconds;
        final entry = _categoryDwell[_nearbyCategoryId!];
        if (entry != null) {
          entry.dwellTimeMs = _sessionBaseMs + elapsed;
        }
        notifyListeners();
      }
    });
  }

  void _stopUiTimer() {
    if (_uiTimer != null) {
      // Freeze final value
      if (_sessionStart != null && _nearbyCategoryId != null) {
        final elapsed =
            DateTime.now().difference(_sessionStart!).inMilliseconds;
        final entry = _categoryDwell[_nearbyCategoryId!];
        if (entry != null) {
          entry.dwellTimeMs = _sessionBaseMs + elapsed;
        }
      }
      _uiTimer!.cancel();
      _uiTimer = null;
    }
    _sessionStart = null;
  }

  // -- Backend sync timer (5s) --

  void _startSyncTimer() {
    if (_syncTimer != null && _syncTimer!.isActive) return;

    // Initial sync delay of 5 seconds, then every 5 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _syncToBackend();
    });
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Calculates the incremental delta since last sync and POSTs to backend.
  void _syncToBackend() {
    if (_nearbyCategoryId == null || _nearbyArtifactId == null) return;

    final entry = _categoryDwell[_nearbyCategoryId!];
    if (entry == null) return;

    final currentMs = entry.dwellTimeMs;
    final deltaMs = currentMs - _lastSyncedMs;

    if (deltaMs <= 0) return; // nothing new to send

    _lastSyncedMs = currentMs;

    final artifactId = _nearbyArtifactId!;
    final delta = deltaMs;

    // Fire-and-forget POST — errors are logged but don't break the UI
    _userScoreService
        .trackDwellTime(
          artifactId: artifactId,
          durationMs: delta,
        )
        .then((_) {
          debugPrint(
              '[DwellSync] ✓ Synced ${delta}ms for category $_nearbyCategoryId (artifact $artifactId)');
        })
        .catchError((e) {
          debugPrint('[DwellSync] ✗ POST failed: $e');
          // Revert the sync pointer so we retry on next tick
          _lastSyncedMs -= delta;
        });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
