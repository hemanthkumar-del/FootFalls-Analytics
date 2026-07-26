import 'package:flutter/foundation.dart';

class BackendConfig {
  static const String _productionUrl = 'https://footfalls-analytics.onrender.com';
  static const String _localUrl = 'http://10.0.2.2:8000';
  
  static String get restApiUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (definedUrl.isNotEmpty) return definedUrl;
    
    return kReleaseMode ? _productionUrl : _localUrl;
  }
  
  static String get webSocketUrl {
    if (restApiUrl.startsWith('https://')) {
      return '${restApiUrl.replaceFirst('https://', 'wss://')}/ws/live';
    }
    return '${restApiUrl.replaceFirst('http://', 'ws://')}/ws/live';
  }
}

