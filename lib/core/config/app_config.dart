/// Application configuration
class AppConfig {
  AppConfig._();

  // App Info
  static const String appName = 'SoluFácil';
  static const String appVersion = '1.0.0';

  // Environment: 'emulator', 'local', or 'production'
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'emulator',
  );

  // API Configuration based on environment
  static String get apiBaseUrl {
    switch (environment) {
      case 'production':
        // DigitalOcean App Platform API
        return 'https://seal-app-zz2t8.ondigitalocean.app';
      case 'local':
        // For real phone on same WiFi network
        return 'http://192.168.1.67:4000';
      case 'emulator':
      default:
        // Android emulator uses 10.0.2.2 for host localhost
        return 'http://10.0.2.2:4000';
    }
  }

  static String get graphqlUrl => '$apiBaseUrl/graphql';

  // PowerSync Configuration based on environment
  static String get powerSyncUrl {
    switch (environment) {
      case 'production':
        // PowerSync Cloud URL
        return 'https://6958967030605f245ffeff59.powersync.journeyapps.com';
      case 'local':
        // For real phone on same WiFi network
        return 'http://192.168.1.67:8080';
      case 'emulator':
      default:
        // Android emulator uses 10.0.2.2 for host localhost
        return 'http://10.0.2.2:8080';
    }
  }

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Search
  static const int searchDebounceMs = 300;
  static const int searchMinChars = 2;
  static const int searchMaxResults = 15;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheDuration = Duration(hours: 24);
}
