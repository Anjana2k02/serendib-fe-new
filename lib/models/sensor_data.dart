/// Sensor data point matching Python server's SensorPoint schema
/// Contains accelerometer (ax, ay, az) and gyroscope (gx, gy, gz) readings
class SensorData {
  final double timestamp;
  final double ax; // Accelerometer X (m/s²)
  final double ay; // Accelerometer Y (m/s²)
  final double az; // Accelerometer Z (m/s²)
  final double gx; // Gyroscope X (rad/s)
  final double gy; // Gyroscope Y (rad/s)
  final double gz; // Gyroscope Z (rad/s)

  SensorData({
    required this.timestamp,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });

  /// Convert to JSON for sending to Python server
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'ax': ax,
      'ay': ay,
      'az': az,
      'gx': gx,
      'gy': gy,
      'gz': gz,
    };
  }

  /// Create from JSON
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: (json['timestamp'] as num).toDouble(),
      ax: (json['ax'] as num).toDouble(),
      ay: (json['ay'] as num).toDouble(),
      az: (json['az'] as num).toDouble(),
      gx: (json['gx'] as num).toDouble(),
      gy: (json['gy'] as num).toDouble(),
      gz: (json['gz'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'SensorData(t: ${timestamp.toStringAsFixed(2)}, '
        'a: [${ax.toStringAsFixed(2)}, ${ay.toStringAsFixed(2)}, ${az.toStringAsFixed(2)}], '
        'g: [${gx.toStringAsFixed(2)}, ${gy.toStringAsFixed(2)}, ${gz.toStringAsFixed(2)}])';
  }
}
