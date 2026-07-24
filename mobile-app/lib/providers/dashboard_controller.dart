import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/models/analytics_model.dart';
import 'package:footfalls_app/repositories/dashboard_repository.dart';
import 'package:footfalls_app/services/websocket_service.dart';

class DashboardState {
  final DashboardMetrics metrics;
  final bool isLoading;
  final String? error;

  DashboardState({
    required this.metrics,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardMetrics? metrics,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      metrics: metrics ?? this.metrics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final dashboardControllerProvider = StateNotifierProvider.autoDispose<DashboardController, DashboardState>((ref) {
  return DashboardController(
    ref.watch(dashboardRepositoryProvider),
    ref.watch(webSocketServiceProvider),
  );
});

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;
  final WebSocketService _wsService;
  StreamSubscription? _wsSubscription;

  DashboardController(this._repository, this._wsService) 
      : super(DashboardState(metrics: DashboardMetrics.empty(), isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await fetchInitialData();
    _listenToWebSockets();
  }

  Future<void> fetchInitialData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await _repository.getDashboardData();
      if (mounted) {
        state = state.copyWith(metrics: data, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  void _listenToWebSockets() {
    _wsSubscription?.cancel();
    _wsSubscription = _wsService.eventStream.listen((event) {
      if (!mounted) return;
      final current = state.metrics;
      final updated = current.copyWith(
        todayEntries: event.entries,
        todayExits: event.exits,
        currentOccupancy: event.occupancy,
      );
      state = state.copyWith(metrics: updated);
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}
