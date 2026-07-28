import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/models/camera_model.dart';
import 'package:footfalls_app/repositories/camera_repository.dart';

class CameraState {
  final List<CameraModel> cameras;
  final bool isLoading;
  final String? error;

  CameraState({
    this.cameras = const [],
    this.isLoading = false,
    this.error,
  });

  CameraState copyWith({
    List<CameraModel>? cameras,
    bool? isLoading,
    String? error,
  }) {
    return CameraState(
      cameras: cameras ?? this.cameras,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear error by default or override
    );
  }
}

final cameraControllerProvider = StateNotifierProvider<CameraController, CameraState>((ref) {
  return CameraController(ref.watch(cameraRepositoryProvider));
});

class CameraController extends StateNotifier<CameraState> {
  final CameraRepository _repository;

  CameraController(this._repository) : super(CameraState(isLoading: true)) {
    fetchCameras();
  }

  Future<void> fetchCameras() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cameras = await _repository.getCameras();
      if (mounted) {
        state = state.copyWith(cameras: cameras, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> addCamera(String name, String url) async {
    try {
      await _repository.addCamera(name, url);
      await fetchCameras();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateCamera(String id, String name, String url) async {
    try {
      await _repository.updateCamera(id, name, url);
      await fetchCameras();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  Future<void> enableCamera(String id) async {
    try {
      await _repository.enableCamera(id);
      await fetchCameras();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  Future<void> disableCamera(String id) async {
    try {
      await _repository.disableCamera(id);
      await fetchCameras();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteCamera(String id) async {
    try {
      await _repository.deleteCamera(id);
      await fetchCameras();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }
}
