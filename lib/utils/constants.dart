// lib/utils/constants.dart

import 'api_config.dart';

/// Application constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Western Area Rural District Council';
  static const String appVersion = '1.0.0';

  // API - Use ApiConfig for base URL management
  static String get baseUrl => ApiConfig.baseUrl;
  static Duration get apiTimeout => ApiConfig.timeout;

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';
  static const String keyThemeMode = 'theme_mode';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

