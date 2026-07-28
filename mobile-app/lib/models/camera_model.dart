class CameraModel {
  final String id;
  final String name;
  final String url;
  final bool isRunningInMemory;
  final double fps;
  final double uptime;
  final bool isEnabled;
  final bool isStreaming;

  CameraModel({
    required this.id,
    required this.name,
    this.url = '',
    this.isRunningInMemory = false,
    this.fps = 0.0,
    this.uptime = 0.0,
    this.isEnabled = false,
    this.isStreaming = false,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      isRunningInMemory: json['is_running_in_memory'] ?? false,
      fps: (json['fps'] ?? 0).toDouble(),
      uptime: (json['uptime'] ?? 0).toDouble(),
      isEnabled: json['isEnabled'] ?? false,
      isStreaming: json['isStreaming'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'isEnabled': isEnabled,
    };
  }
}
