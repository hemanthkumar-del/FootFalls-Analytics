class BackendConfig {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS Simulator, or real IP for physical devices.
  static const String baseUrl = '10.0.2.2:8000';
  
  static String get restApiUrl => 'http://$baseUrl';
  static String get webSocketUrl => 'ws://$baseUrl/ws/live';
}
