class BackendConfig {
  static const String _awsUrl = 'http://13.203.195.62:8000';
  
  static String get restApiUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (definedUrl.isNotEmpty) return definedUrl;
    
    return _awsUrl;
  }
  
  static String get webSocketUrl {
    if (restApiUrl.startsWith('https://')) {
      return '${restApiUrl.replaceFirst('https://', 'wss://')}/ws/live';
    }
    return '${restApiUrl.replaceFirst('http://', 'ws://')}/ws/live';
  }
}

