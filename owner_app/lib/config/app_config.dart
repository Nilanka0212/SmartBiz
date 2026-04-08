class AppConfig {
  // Default LAN IP for the local XAMPP server.
  // Override when needed:
  // flutter run --dart-define=SMARTBIZ_HOST=10.0.2.2
  static const String host = String.fromEnvironment(
    'SMARTBIZ_HOST',
    defaultValue: '192.168.1.17',
  );

  static const String scheme = 'http';
  static const String projectPath = 'SmartBiz';

  static String get baseUrl => '$scheme://$host/$projectPath';
  static String get apiBaseUrl => '$baseUrl/api';
  static String get customerShopBaseUrl => '$baseUrl/customer/index.php';

  static String apiAssetUrl(String relativePath) {
    final normalizedPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return '$apiBaseUrl/$normalizedPath';
  }
}
