class DashboardMetrics {
  final int todayEntries;
  final int todayExits;
  final int currentOccupancy;
  final String peakHour;
  final int activeCameras;

  DashboardMetrics({
    required this.todayEntries,
    required this.todayExits,
    required this.currentOccupancy,
    required this.peakHour,
    required this.activeCameras,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      todayEntries: json['today_entries'] ?? 0,
      todayExits: json['today_exits'] ?? 0,
      currentOccupancy: json['current_occupancy'] ?? 0,
      peakHour: json['peak_hour'] ?? 'N/A',
      activeCameras: json['active_cameras'] ?? 0,
    );
  }

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      todayEntries: 0,
      todayExits: 0,
      currentOccupancy: 0,
      peakHour: 'N/A',
      activeCameras: 0,
    );
  }

  DashboardMetrics copyWith({
    int? todayEntries,
    int? todayExits,
    int? currentOccupancy,
    String? peakHour,
    int? activeCameras,
  }) {
    return DashboardMetrics(
      todayEntries: todayEntries ?? this.todayEntries,
      todayExits: todayExits ?? this.todayExits,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      peakHour: peakHour ?? this.peakHour,
      activeCameras: activeCameras ?? this.activeCameras,
    );
  }
}

class WsEvent {
  final String cameraId;
  final int entries;
  final int exits;
  final int occupancy;
  final double fps;
  final String cameraStatus;

  WsEvent({
    required this.cameraId,
    required this.entries,
    required this.exits,
    required this.occupancy,
    required this.fps,
    required this.cameraStatus,
  });

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    return WsEvent(
      cameraId: json['camera_id'] ?? '',
      entries: json['entries'] ?? 0,
      exits: json['exits'] ?? 0,
      occupancy: json['occupancy'] ?? 0,
      fps: (json['fps'] ?? 0).toDouble(),
      cameraStatus: json['camera_status'] ?? 'offline',
    );
  }
}
