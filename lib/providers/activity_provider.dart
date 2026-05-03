import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/activity_prediction.dart';
import '../services/har_service.dart';

/// Provider for Human Activity Recognition state management
/// Wraps HARService and exposes activity detection state to UI
class ActivityProvider with ChangeNotifier {
  final HARService _harService = HARService();
  
  ActivityPrediction? _currentActivity;
  int _bufferingReceived = 0;
  int _bufferingRequired = 128;
  bool _isBuffering = false;
  bool _isActive = false;
  String? _error;
  
  StreamSubscription<ActivityPrediction>? _activitySubscription;
  StreamSubscription? _bufferingSubscription;
  StreamSubscription<String>? _errorSubscription;

  /// Current activity prediction (null if buffering or not started)
  ActivityPrediction? get currentActivity => _currentActivity;
  
  /// Whether the service is currently collecting initial samples
  bool get isBuffering => _isBuffering;
  
  /// Buffering progress (0 to 100)
  int get bufferingProgress => 
      _bufferingRequired > 0 
          ? ((_bufferingReceived / _bufferingRequired) * 100).round() 
          : 0;
  
  /// Number of samples received during buffering
  int get bufferingReceived => _bufferingReceived;
  
  /// Number of samples required before predictions start
  int get bufferingRequired => _bufferingRequired;
  
  /// Whether the service is currently active
  bool get isActive => _isActive;
  
  /// Current error message (null if no error)
  String? get error => _error;
  
  /// Whether the service is connected to the server
  bool get isConnected => _harService.isConnected;

  /// Start activity recognition
  Future<void> start() async {
    if (_isActive) {
      print('ActivityProvider: Already active');
      return;
    }

    try {
      _error = null;
      _isActive = true;
      _isBuffering = true;
      _bufferingReceived = 0;
      _currentActivity = null;
      notifyListeners();

      // Subscribe to activity predictions
      _activitySubscription = _harService.activityStream.listen(
        (prediction) {
          _currentActivity = prediction;
          _isBuffering = false;
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          _error = 'Activity stream error: $e';
          notifyListeners();
        },
      );

      // Subscribe to buffering status
      _bufferingSubscription = _harService.bufferingStream.listen(
        (status) {
          _bufferingReceived = status.received;
          _bufferingRequired = status.required;
          _isBuffering = true;
          notifyListeners();
        },
      );

      // Subscribe to errors
      _errorSubscription = _harService.errorStream.listen(
        (errorMessage) {
          _error = errorMessage;
          notifyListeners();
        },
      );

      // Start the HAR service
      await _harService.start();
      
      print('ActivityProvider: Started successfully');
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to start activity recognition: $e';
      _isActive = false;
      _isBuffering = false;
      notifyListeners();
      print('ActivityProvider: Start error: $e');
    }
  }

  /// Stop activity recognition
  Future<void> stop() async {
    if (!_isActive) {
      print('ActivityProvider: Already stopped');
      return;
    }

    try {
      await _activitySubscription?.cancel();
      await _bufferingSubscription?.cancel();
      await _errorSubscription?.cancel();
      
      _activitySubscription = null;
      _bufferingSubscription = null;
      _errorSubscription = null;

      await _harService.stop();

      _isActive = false;
      _isBuffering = false;
      _currentActivity = null;
      _bufferingReceived = 0;
      _error = null;
      
      print('ActivityProvider: Stopped successfully');
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to stop activity recognition: $e';
      notifyListeners();
      print('ActivityProvider: Stop error: $e');
    }
  }

  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    _bufferingSubscription?.cancel();
    _errorSubscription?.cancel();
    _harService.dispose();
    super.dispose();
  }
}
