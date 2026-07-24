class BackendConfig {
  // Use --dart-define=API_BASE_URL=https://api.footfalls.app for production builds.
  // Defaults to the Android Emulator local IP.
  static const String restApiUrl = String.fromEnvironment(
    'API_BASE_URL', 
    defaultValue: 'https://footfalls-analytics.onrender.com'
  );
  
  static String get webSocketUrl {
    if (restApiUrl.startsWith('https://')) {
      return restApiUrl.replaceFirst('https://', 'wss://') + '/ws/live';
    }
    return restApiUrl.replaceFirst('http://', 'ws://') + '/ws/live';
  }
}
