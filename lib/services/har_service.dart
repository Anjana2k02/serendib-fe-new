import 'dart:async';
import 'dart:convert';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/sensor_data.dart';
import '../models/activity_prediction.dart';
import '../core/config/env_config.dart';

/// Human Activity Recognition (HAR) Service
/// Streams accelerometer and gyroscope data to Python server via WebSocket
/// and receives activity predictions (WALKING, SITTING, STANDING)
class HARService {
  WebSocketChannel? _channel;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  final _activityController = StreamController<ActivityPrediction>.broadcast();
  final _bufferingController = StreamController<BufferingStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  // Sensor data buffers
  AccelerometerEvent? _latestAccel;
  GyroscopeEvent? _latestGyro;
  Timer? _sensorTimer;
  Timer? _reconnectTimer;
  
  bool _isConnected = false;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectInterval = Duration(seconds: 5);
  
  // Target 50 Hz sampling rate (20ms interval)
  static const Duration _samplingInterval = Duration(milliseconds: 20);

  /// Stream of activity predictions
  Stream<ActivityPrediction> get activityStream => _activityController.stream;
  
  /// Stream of buffering status updates
  Stream<BufferingStatus> get bufferingStream => _bufferingController.stream;
  
  /// Stream of error messages
  Stream<String> get errorStream => _errorController.stream;
  
  /// Whether the service is currently connected to the server
  bool get isConnected => _isConnected;

  /// Start streaming sensor data to server
  Future<void> start() async {
    if (_isDisposed) {
      throw StateError('HARService has been disposed');
    }
    
    if (_isConnected) {
      print('HARService: Already connected');
      return;
    }

    await _connect();
  }

  /// Connect to WebSocket server
  Future<void> _connect() async {
    try {
      final wsUrl = EnvConfig.pythonServer1Url.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/stream');
      
      print('HARService: Connecting to $uri');
      
      _channel = WebSocketChannel.connect(uri);
      
      // Listen for messages from server
      _channel!.stream.listen(
        _handleServerMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClosed,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      print('HARService: Connected successfully');
      
      // Start sensor streaming
      _startSensorStreaming();
      
    } catch (e) {
      print('HARService: Connection error: $e');
      _errorController.add('Failed to connect: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// Start streaming sensor data
  void _startSensorStreaming() {
    // Subscribe to accelerometer
    _accelSubscription = accelerometerEventStream().listen(
      (event) {
        _latestAccel = event;
      },
      onError: (e) {
        print('HARService: Accelerometer error: $e');
        _errorController.add('Accelerometer error: $e');
      },
    );

    // Subscribe to gyroscope
    _gyroSubscription = gyroscopeEventStream().listen(
      (event) {
        _latestGyro = event;
      },
      onError: (e) {
        print('HARService: Gyroscope error: $e');
        _errorController.add('Gyroscope error: $e');
      },
    );

    // Sample and send data at 50 Hz
    _sensorTimer = Timer.periodic(_samplingInterval, (_) {
      _sendSensorData();
    });
  }

  /// Send current sensor readings to server
  void _sendSensorData() {
    if (!_isConnected || _channel == null) return;
    
    final accel = _latestAccel;
    final gyro = _latestGyro;
    
    if (accel == null || gyro == null) {
      // Waiting for both sensors to initialize
      return;
    }

    final sensorData = SensorData(
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      ax: accel.x,
      ay: accel.y,
      az: accel.z,
      gx: gyro.x,
      gy: gyro.y,
      gz: gyro.z,
    );

    try {
      final jsonString = jsonEncode(sensorData.toJson());
      _channel!.sink.add(jsonString);
    } catch (e) {
      print('HARService: Error sending sensor data: $e');
      _errorController.add('Error sending data: $e');
    }
  }

  /// Handle incoming messages from server
  void _handleServerMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final messageType = data['type'] as String?;

      if (messageType == 'buffering') {
        // Server is still collecting initial samples
        final received = data['received'] as int;
        final required = data['required'] as int;
        _bufferingController.add(BufferingStatus(
          received: received,
          required: required,
        ));
      } else if (messageType == 'prediction') {
        // Received activity prediction
        final prediction = ActivityPrediction.fromJson(data);
        _activityController.add(prediction);
      } else {
        print('HARService: Unknown message type: $messageType');
      }
    } catch (e) {
      print('HARService: Error parsing server message: $e');
      _errorController.add('Error parsing response: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(dynamic error) {
    print('HARService: WebSocket error: $error');
    _errorController.add('Connection error: $error');
    _isConnected = false;
    _stopSensorStreaming();
    _scheduleReconnect();
  }

  /// Handle WebSocket connection closed
  void _handleWebSocketClosed() {
    print('HARService: WebSocket connection closed');
    _isConnected = false;
    _stopSensorStreaming();
    
    if (!_isDisposed) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_isDisposed || _reconnectAttempts >= _maxReconnectAttempts) {
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        _errorController.add('Max reconnection attempts reached');
      }
      return;
    }

    _reconnectAttempts++;
    print('HARService: Scheduling reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () {
      if (!_isDisposed && !_isConnected) {
        _connect();
      }
    });
  }

  /// Stop sensor streaming
  void _stopSensorStreaming() {
    _sensorTimer?.cancel();
    _sensorTimer = null;
    _accelSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }

  /// Stop streaming and disconnect
  Future<void> stop() async {
    print('HARService: Stopping service');
    _stopSensorStreaming();
    _reconnectTimer?.cancel();
    
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    
    _isConnected = false;
  }

  /// Dispose of all resources
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    stop();
    
    _activityController.close();
    _bufferingController.close();
    _errorController.close();
  }
}

/// Buffering status while collecting initial samples
class BufferingStatus {
  final int received;
  final int required;

  BufferingStatus({
    required this.received,
    required this.required,
  });

  /// Get buffering progress (0.0 to 1.0)
  double get progress => received / required;

  /// Get buffering percentage (0 to 100)
  int get progressPercent => (progress * 100).round();

  @override
  String toString() => 'BufferingStatus($received/$required - $progressPercent%)';
}
