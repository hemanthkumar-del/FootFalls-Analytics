// lib/repositories/analytics_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:footfalls_app/core/config/api_constants.dart';

final analyticsRepositoryProvider = Provider((ref) {
  return AnalyticsRepository(ref.watch(dioProvider));
});

class AnalyticsRepository {
  final Dio _dio;
  
  AnalyticsRepository(this._dio);

  Future<Map<String, dynamic>> getAdvancedAnalytics() async {
    final res = await _dio.get(ApiConstants.advanced);
    return res.data;
  }

  Future<Map<String, dynamic>> getHeatmapData() async {
    final res = await _dio.get(ApiConstants.heatmap);
    return res.data;
  }

  Future<Response<List<int>>> downloadReport(String type) async {
    final url = type == 'pdf' ? ApiConstants.exportPdf : ApiConstants.exportCsv;
    return await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
  }
}
