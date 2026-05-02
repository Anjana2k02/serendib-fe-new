import 'dart:async';
import 'package:flutter/material.dart';

/// Provider for Developer Options including dwell time tracking.
/// Tracks how long a user is "standing" near an artifact in milliseconds.
class DevOptionsProvider extends ChangeNotifier {
  bool _developerOptionsEnabled = true;
  String _selectedLocation = 'Location A';
  String _selectedActivity = 'Standing';

  // Dwell time tracking
  int _dwellTimeMs = 0;         // total accumulated dwell time
  int _sessionBaseMs = 0;       // dwell time at the start of this standing session
  Timer? _dwellTimer;
  String? _nearbyArtifactName;
  int? _nearbyCategoryId;
  DateTime? _sessionStart;      // when current standing session started

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

  /// Current accumulated dwell time in milliseconds (always increasing)
  int get dwellTimeMs => _dwellTimeMs;

  /// Name of the nearest artifact (null if none nearby)
  String? get nearbyArtifactName => _nearbyArtifactName;

  /// Category ID of the nearest artifact (null if none nearby)
  int? get nearbyCategoryId => _nearbyCategoryId;

  /// Whether the dwell time timer is currently running
  bool get isDwellTimerActive => _dwellTimer != null && _dwellTimer!.isActive;

  // ---- Setters ----

  void setDeveloperOptions(bool value) {
    _developerOptionsEnabled = value;
    if (!value) {
      _stopDwellTimer();
      _dwellTimeMs = 0;
      _sessionBaseMs = 0;
      _nearbyArtifactName = null;
      _nearbyCategoryId = null;
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
      _startDwellTimer();
    } else {
      _stopDwellTimer();
    }

    notifyListeners();
  }

  // ---- Dwell time methods ----

  /// Called when user enters proximity of an artifact while standing.
  void setNearbyArtifact(String artifactName, int? categoryId) {
    final changed = _nearbyArtifactName != artifactName;
    _nearbyArtifactName = artifactName;
    _nearbyCategoryId = categoryId;

    if (_selectedActivity.toLowerCase() == 'standing') {
      if (changed) {
        // New artifact — freeze current accumulated time and restart session
        _stopDwellTimer();
      }
      _startDwellTimer();
    }

    notifyListeners();
  }

  /// Called when user leaves artifact proximity.
  void clearNearbyArtifact() {
    _nearbyArtifactName = null;
    _nearbyCategoryId = null;
    _stopDwellTimer();
    notifyListeners();
  }

  /// Reset accumulated dwell time to zero.
  void resetDwellTime() {
    _stopDwellTimer();
    _dwellTimeMs = 0;
    _sessionBaseMs = 0;
    notifyListeners();
  }

  void _startDwellTimer() {
    if (_dwellTimer != null && _dwellTimer!.isActive) return;

    _sessionBaseMs = _dwellTimeMs;
    _sessionStart = DateTime.now();

    // Update at ~20fps for smooth live display
    _dwellTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_sessionStart != null) {
        final elapsed =
            DateTime.now().difference(_sessionStart!).inMilliseconds;
        _dwellTimeMs = _sessionBaseMs + elapsed;
        notifyListeners();
      }
    });
  }

  void _stopDwellTimer() {
    if (_dwellTimer != null) {
      // Freeze the final accumulated value
      if (_sessionStart != null) {
        final elapsed =
            DateTime.now().difference(_sessionStart!).inMilliseconds;
        _dwellTimeMs = _sessionBaseMs + elapsed;
      }
      _dwellTimer!.cancel();
      _dwellTimer = null;
    }
    _sessionStart = null;
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    super.dispose();
  }
}
