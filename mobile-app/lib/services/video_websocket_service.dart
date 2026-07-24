import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:footfalls_app/core/config/backend_config.dart';
import 'package:footfalls_app/models/video_frame_model.dart';

final videoWebsocketProvider = Provider((ref) => VideoWebsocketService());

class VideoWebsocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  
  final _frameController = StreamController<VideoFrame>.broadcast();
  Stream<VideoFrame> get frameStream => _frameController.stream;
  
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  String? _currentCameraId;
  bool _isConnecting = false;

  void connect(String cameraId) {
    if (_currentCameraId == cameraId && _channel != null) return;
    
    _currentCameraId = cameraId;
    _connect();
  }

  void _connect() {
    if (_currentCameraId == null || _isConnecting) return;
    
    _isConnecting = true;
    _connectionStateController.add(false); // Connecting/Disconnected state
    disconnect();

    final url = 'ws://${BackendConfig.baseUrl}/ws/video/$_currentCameraId';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _subscription = _channel!.stream.listen(
        (message) {
          _isConnecting = false;
          _connectionStateController.add(true); // Connected state
          _handleMessage(message);
        },
        onError: (error) {
          _isConnecting = false;
          _connectionStateController.add(false);
          _scheduleReconnect();
        },
        onDone: () {
          _isConnecting = false;
          _connectionStateController.add(false);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    if (message is Uint8List) {
      try {
        final byteData = ByteData.view(message.buffer);
        // Read 4-byte little endian JSON length
        final jsonLength = byteData.getUint32(0, Endian.little);
        
        if (jsonLength > 0 && message.length > jsonLength + 4) {
          final jsonBytes = message.sublist(4, 4 + jsonLength);
          final jsonString = utf8.decode(jsonBytes);
          final metadataMap = jsonDecode(jsonString);
          
          final metadata = VideoMetadata.fromJson(metadataMap);
          final imageBytes = message.sublist(4 + jsonLength);
          
          _frameController.add(VideoFrame(
            metadata: metadata,
            imageBytes: imageBytes,
          ));
        }
      } catch (e) {
        // Skip malformed frames
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_currentCameraId != null) {
        _connect();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
  }

  void dispose() {
    disconnect();
    _frameController.close();
    _connectionStateController.close();
  }
}
