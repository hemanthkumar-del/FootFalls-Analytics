import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final analyticsControllerProvider = StateNotifierProvider.autoDispose<AnalyticsController, AnalyticsState>((ref) {
  final dio = ref.watch(dioProvider);
  return AnalyticsController(dio);
});

class AnalyticsState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? advancedData;
  final Map<String, dynamic>? heatmapData;
  final bool isExporting;

  AnalyticsState({
    this.isLoading = false,
    this.error,
    this.advancedData,
    this.heatmapData,
    this.isExporting = false,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? advancedData,
    Map<String, dynamic>? heatmapData,
    bool? isExporting,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      advancedData: advancedData ?? this.advancedData,
      heatmapData: heatmapData ?? this.heatmapData,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

class AnalyticsController extends StateNotifier<AnalyticsState> {
  final Dio _dio;

  AnalyticsController(this._dio) : super(AnalyticsState()) {
    fetchData();
  }

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final responses = await Future.wait([
        _dio.get('/analytics/advanced'),
        _dio.get('/analytics/heatmap'),
      ]);
      
      state = state.copyWith(
        isLoading: false,
        advancedData: responses[0].data,
        heatmapData: responses[1].data,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> exportReport(String type) async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      final response = await _dio.get(
        '/analytics/export/$type',
        options: Options(responseType: ResponseType.bytes),
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/footfalls_report.$type');
      await file.writeAsBytes(response.data);
      
      state = state.copyWith(isExporting: false);
      return file.path;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }
}
