class CameraModel {
  final String id;
  final String name;
  final String url;
  final String status;

  CameraModel({
    required this.id,
    required this.name,
    required this.url,
    required this.status,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      status: json['status'] ?? 'offline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'status': status,
    };
  }
}
