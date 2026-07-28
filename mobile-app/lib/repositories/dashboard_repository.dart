import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:footfalls_app/models/analytics_model.dart';
import 'package:footfalls_app/core/config/api_constants.dart';

final dashboardRepositoryProvider = Provider((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardMetrics> getDashboardData() async {
    try {
      final response = await _dio.get(ApiConstants.dashboard);
      if (response.statusCode == 200) {
        return DashboardMetrics.fromJson(response.data);
      }
      throw Exception('Failed to load dashboard data');
    } catch (e) {
      throw Exception('Error fetching dashboard: $e');
    }
  }
}
