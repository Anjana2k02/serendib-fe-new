/// Activity prediction response from Python server
/// Matches PredictionResponse schema from museum-model1/api/schemas.py
class ActivityPrediction {
  final String label; // WALKING, SITTING, or STANDING
  final double confidence; // 0.0 to 1.0
  final Map<String, double> probabilities; // All class probabilities
  final double processingMs; // Inference time
  final double serverTimestamp;
  final double windowStartTimestamp;
  final double windowEndTimestamp;
  final int windowSize;

  ActivityPrediction({
    required this.label,
    required this.confidence,
    required this.probabilities,
    required this.processingMs,
    required this.serverTimestamp,
    required this.windowStartTimestamp,
    required this.windowEndTimestamp,
    required this.windowSize,
  });

  /// Create from JSON response
  factory ActivityPrediction.fromJson(Map<String, dynamic> json) {
    return ActivityPrediction(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: (json['probabilities'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      processingMs: (json['processing_ms'] as num).toDouble(),
      serverTimestamp: (json['server_timestamp'] as num).toDouble(),
      windowStartTimestamp: (json['window_start_timestamp'] as num).toDouble(),
      windowEndTimestamp: (json['window_end_timestamp'] as num).toDouble(),
      windowSize: json['window_size'] as int,
    );
  }

  /// Get confidence percentage (0-100)
  int get confidencePercent => (confidence * 100).round();

  /// Get confidence level for UI coloring
  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.8) return ConfidenceLevel.high;
    if (confidence >= 0.6) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  /// Get icon for activity
  String get icon {
    switch (label) {
      case 'WALKING':
        return '🚶';
      case 'SITTING':
        return '🪑';
      case 'STANDING':
        return '🧍';
      default:
        return '❓';
    }
  }

  /// Get display label (title case)
  String get displayLabel {
    if (label.isEmpty) return '';
    return label[0] + label.substring(1).toLowerCase();
  }

  @override
  String toString() {
    return 'ActivityPrediction(label: $label, confidence: $confidencePercent%, '
        'processing: ${processingMs.toStringAsFixed(1)}ms)';
  }
}

/// Confidence level for UI styling
enum ConfidenceLevel {
  high,   // >= 80%
  medium, // 60-79%
  low,    // < 60%
}
