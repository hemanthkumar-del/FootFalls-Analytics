import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:footfalls_app/core/config/backend_config.dart';
import 'package:footfalls_app/models/analytics_model.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final _eventController = StreamController<WsEvent>.broadcast();
  
  bool _isConnecting = false;
  bool _isDisposed = false;

  Stream<WsEvent> get eventStream => _eventController.stream;

  WebSocketService() {
    connect();
  }

  void connect() {
    if (_isConnecting || _isDisposed) return;
    _isConnecting = true;
    
    try {
      debugPrint('Connecting to WebSocket...');
      _channel = WebSocketChannel.connect(Uri.parse(BackendConfig.webSocketUrl));
      
      _channel!.stream.listen(
        (message) {
          _isConnecting = false;
          _reconnectTimer?.cancel();
          
          try {
            final data = jsonDecode(message);
            final event = WsEvent.fromJson(data);
            _eventController.add(event);
          } catch (e) {
            debugPrint('Error parsing WS message: $e');
          }
        },
        onDone: () {
          debugPrint('WebSocket disconnected.');
          _isConnecting = false;
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('WebSocket Error: $error');
          _isConnecting = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('Exception while connecting: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      debugPrint('Attempting to reconnect...');
      connect();
    });
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _eventController.close();
  }
}
