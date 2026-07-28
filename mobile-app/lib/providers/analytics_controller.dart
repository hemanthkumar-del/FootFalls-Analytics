import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/repositories/analytics_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final analyticsControllerProvider = StateNotifierProvider.autoDispose<AnalyticsController, AnalyticsState>((ref) {
  return AnalyticsController(ref.watch(analyticsRepositoryProvider));
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
  final AnalyticsRepository _repository;

  AnalyticsController(this._repository) : super(AnalyticsState()) {
    fetchData();
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final responses = await Future.wait([
        _repository.getAdvancedAnalytics(),
        _repository.getHeatmapData(),
      ]);
      
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          advancedData: responses[0],
          heatmapData: responses[1],
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<String?> exportReport(String type) async {
    if (!mounted) return null;
    state = state.copyWith(isExporting: true, error: null);
    try {
      final response = await _repository.downloadReport(type);
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/footfalls_report.$type');
      if (response.data != null) {
        await file.writeAsBytes(response.data!);
      }
      
      if (mounted) state = state.copyWith(isExporting: false);
      return file.path;
    } catch (e) {
      if (mounted) state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }
}
