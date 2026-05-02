import '../core/constants/app_constants.dart';
import 'api_service.dart';

/// Service for posting dwell time data to the backend user-scores API.
class UserScoreService {
  final ApiService _apiService = ApiService();

  /// Posts incremental dwell time for an artifact to the backend.
  ///
  /// [artifactId]     - The nearest artifact's location ID (maps to artifact in backend)
  /// [durationMs]     - Incremental milliseconds to add since last POST
  /// [activity]       - Must be "standing" for the backend to accept it
  ///
  /// Returns the updated UserScore response map, or throws on error.
  Future<Map<String, dynamic>> trackDwellTime({
    required int artifactId,
    required int durationMs,
    String activity = 'standing',
  }) async {
    final body = {
      'artifactId': artifactId,
      'activity': activity,
      'durationMs': durationMs,
    };

    final response = await _apiService.post(
      '${AppConstants.userScoresEndpoint}/track-dwell-time',
      body,
    );

    return response as Map<String, dynamic>;
  }
}
