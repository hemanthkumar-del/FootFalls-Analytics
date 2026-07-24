import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/models/video_frame_model.dart';
import 'package:footfalls_app/services/video_websocket_service.dart';
import 'package:footfalls_app/repositories/camera_repository.dart';
import 'package:footfalls_app/models/camera_model.dart';

final monitoringControllerProvider = StateNotifierProvider.autoDispose<MonitoringController, MonitoringState>((ref) {
  final wsService = ref.watch(videoWebsocketProvider);
  final cameraRepo = ref.watch(cameraRepositoryProvider);
  return MonitoringController(wsService, cameraRepo);
});

class MonitoringState {
  final bool isConnected;
  final VideoFrame? latestFrame;
  final List<CameraModel> availableCameras;
  final CameraModel? selectedCamera;
  final bool isFullScreen;
  final bool isLoading;

  MonitoringState({
    this.isConnected = false,
    this.latestFrame,
    this.availableCameras = const [],
    this.selectedCamera,
    this.isFullScreen = false,
    this.isLoading = false,
  });

  MonitoringState copyWith({
    bool? isConnected,
    VideoFrame? latestFrame,
    List<CameraModel>? availableCameras,
    CameraModel? selectedCamera,
    bool? isFullScreen,
    bool? isLoading,
  }) {
    return MonitoringState(
      isConnected: isConnected ?? this.isConnected,
      latestFrame: latestFrame ?? this.latestFrame,
      availableCameras: availableCameras ?? this.availableCameras,
      selectedCamera: selectedCamera ?? this.selectedCamera,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MonitoringController extends StateNotifier<MonitoringState> {
  final VideoWebsocketService _wsService;
  final CameraRepository _cameraRepo;

  MonitoringController(this._wsService, this._cameraRepo) : super(MonitoringState()) {
    _init();
  }

  void _init() {
    _wsService.connectionStateStream.listen((isConnected) {
      if (mounted) {
        state = state.copyWith(isConnected: isConnected);
      }
    });

    _wsService.frameStream.listen((frame) {
      if (mounted) {
        state = state.copyWith(latestFrame: frame);
      }
    });

    loadCameras();
  }

  Future<void> loadCameras() async {
    state = state.copyWith(isLoading: true);
    try {
      final cameras = await _cameraRepo.getCameras();
      if (mounted) {
        state = state.copyWith(
          availableCameras: cameras,
          selectedCamera: cameras.isNotEmpty ? cameras.first : null,
          isLoading: false,
        );
        
        if (cameras.isNotEmpty) {
          selectCamera(cameras.first);
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void selectCamera(CameraModel camera) {
    state = state.copyWith(selectedCamera: camera, latestFrame: null, isConnected: false);
    _wsService.connect(camera.id);
  }

  void toggleFullScreen() {
    state = state.copyWith(isFullScreen: !state.isFullScreen);
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
