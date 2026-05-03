import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/activity_provider.dart';
import '../../models/activity_prediction.dart';

/// Activity status overlay widget for displaying real-time activity recognition
/// Positioned at the top-right corner of the map viewer
class ActivityStatusWidget extends StatelessWidget {
  const ActivityStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppConstants.spacingMd,
      right: AppConstants.spacingMd,
      child: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          // Don't show if not active
          if (!provider.isActive) {
            return const SizedBox.shrink();
          }

          return Container(
            decoration: BoxDecoration(
              color: AppColors.offWhite.withOpacity(0.95),
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkOverlay,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingSm,
              ),
              child: _buildContent(provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ActivityProvider provider) {
    // Show error state
    if (provider.error != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppConstants.iconSizeMd,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            'Connection Error',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // Show buffering state
    if (provider.isBuffering) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBrown),
              value: provider.bufferingProgress / 100,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Collecting data...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${provider.bufferingReceived}/${provider.bufferingRequired}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Show activity prediction
    final activity = provider.currentActivity;
    if (activity != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Activity icon
          Text(
            activity.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          
          // Activity label and confidence
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activity.displayLabel,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Confidence indicator dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(activity.confidenceLevel),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.confidencePercent}%',
                    style: TextStyle(
                      color: _getConfidenceColor(activity.confidenceLevel),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    // Fallback (shouldn't reach here)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.sensors,
          color: AppColors.textSecondary,
          size: AppConstants.iconSizeMd,
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          'Initializing...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Get color based on confidence level
  Color _getConfidenceColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return AppColors.success;
      case ConfidenceLevel.medium:
        return AppColors.warning;
      case ConfidenceLevel.low:
        return AppColors.error;
    }
  }
}
