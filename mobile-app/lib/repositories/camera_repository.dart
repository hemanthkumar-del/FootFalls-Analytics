import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:footfalls_app/models/camera_model.dart';

final cameraRepositoryProvider = Provider((ref) {
  return CameraRepository(ref.watch(dioProvider));
});

class CameraRepository {
  final Dio _dio;

  CameraRepository(this._dio);

  Future<List<CameraModel>> getCameras() async {
    try {
      final response = await _dio.get('/cameras/');
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((e) => CameraModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching cameras: $e');
    }
  }

  Future<CameraModel> addCamera(String name, String url) async {
    try {
      final response = await _dio.post('/cameras/', data: {
        'name': name,
        'url': url,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CameraModel.fromJson(response.data);
      }
      throw Exception('Failed to add camera');
    } catch (e) {
      throw Exception('Error adding camera: $e');
    }
  }

  Future<void> deleteCamera(String id) async {
    try {
      await _dio.delete('/cameras/$id');
    } catch (e) {
      throw Exception('Error deleting camera: $e');
    }
  }
}
