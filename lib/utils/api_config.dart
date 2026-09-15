// lib/utils/api_config.dart

import 'dart:developer';

/// API Configuration for managing base URLs across different environments
class ApiConfig {
  ApiConfig._();

  /// Environment type
  static Environment _environment = Environment.production;

  /// Get current environment
  static Environment get environment => _environment;

  /// Set environment (call this in main.dart before runApp)
  static void setEnvironment(Environment env) {
    _environment = env;
  }

  /// Base URLs for different environments
  static const String _devBaseUrl =
      'https://wardc.srvtechnology.com/public/api/';
  static const String _prodBaseUrl = 'https://www.wardc.online/apis/api/';

  /// Storage URLs for different environments
  static const String _devStorageUrl =
      'https://wardc.srvtechnology.com/storage/app/public/';
  static const String _prodStorageUrl =
      'https://www.wardc.online/apis/storage/app/public/';

  /// Get base URL based on current environment
  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return _devBaseUrl;
      case Environment.production:
        return _prodBaseUrl;
    }
  }

  /// Get storage URL based on current environment
  static String get storageUrl {
    switch (_environment) {
      case Environment.development:
        return _devStorageUrl;
      case Environment.production:
        return _prodStorageUrl;
    }
  }

  /// Build full image URL from relative path
  /// Example: /property/assessment/image/abc.jpg -> http://13.232.84.109/apis/storage/app/public/property/assessment/image/abc.jpg
  static String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    // Remove leading slash if present
    final cleanPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;

    // Remove trailing slash from storage URL if present
    final baseUrl = storageUrl.endsWith('/')
        ? storageUrl.substring(0, storageUrl.length - 1)
        : storageUrl;
    log('$baseUrl/$cleanPath');
    return '$baseUrl/$cleanPath';
  }

  /// API timeout duration (minimum 1 minute)
  static const Duration timeout = Duration(minutes: 1);

  /// Content type for API requests
  static const String contentType = 'application/json';
}

/// Environment enumeration
enum Environment { development, production }
