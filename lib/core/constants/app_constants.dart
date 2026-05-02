import 'package:flutter/material.dart';
import 'package:serendib/core/config/env_config.dart';

/// App-wide constants
class AppConstants {
  AppConstants._();

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 999.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Icons Sizes
  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  // Elevation
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;

  // Edge Insets
  static const EdgeInsets paddingAll = EdgeInsets.all(spacingMd);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets paddingHorizontal =
      EdgeInsets.symmetric(horizontal: spacingMd);
  static const EdgeInsets paddingVertical =
      EdgeInsets.symmetric(vertical: spacingMd);

  // App Specific
  static const int onboardingQuestionCount = 5;
  static const String onboardingKey = 'onboarding_completed';
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // API Configuration
  static String get baseUrl => EnvConfig.backendUrl;
  static const String apiVersion = '/api/v1';
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  // API Endpoints
  static String get loginEndpoint => '$apiBaseUrl/auth/login';
  static String get registerEndpoint => '$apiBaseUrl/auth/register';
  static String get googleAuthEndpoint => '$apiBaseUrl/auth/google';
  static String get artifactsEndpoint => '$apiBaseUrl/artifacts';
  static String get feedbackEndpoint => '$apiBaseUrl/feedback';
  static String get usersEndpoint => '$apiBaseUrl/users';
  static String get userScoresEndpoint => '$apiBaseUrl/user-scores';

  // FastAPI ML Backend
  static const String mlBaseUrl = 'http://192.168.1.170:8000';
  static const String predictEndpoint = '$mlBaseUrl/predict';
  static const String translateEndpoint = '$mlBaseUrl/translate';
  static const String artifactByIdEndpoint = '$mlBaseUrl/artifact';
  static const String generateDescriptionEndpoint =
      '$mlBaseUrl/generate-description';

  // Google OAuth2
  // Replace with your Web Client ID from Google Cloud Console / Firebase
  static const String googleWebClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  // HTTP Headers
  static const String contentTypeJson = 'application/json';
  static const String authorizationHeader = 'Authorization';

  // Timeout
  static const Duration requestTimeout = Duration(seconds: 30);
}
