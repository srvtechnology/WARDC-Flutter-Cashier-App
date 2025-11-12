// lib/utils/api_config.dart

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
  static const String _devBaseUrl = 'https://wardc-dev.srvtechnology.com/public/api/';
  static const String _prodBaseUrl = 'https://wardc.srvtechnology.com/public/api/';

  /// Get base URL based on current environment
  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return _devBaseUrl;
      case Environment.production:
        return _prodBaseUrl;
    }
  }

  /// API timeout duration
  static const Duration timeout = Duration(seconds: 15);

  /// Content type for API requests
  static const String contentType = 'application/json';
}

/// Environment enumeration
enum Environment {
  development,
  production,
}



