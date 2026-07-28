class ApiConstants {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  
  // Cameras
  static const String getCameras = '/cameras';
  static const String getCameraStatus = '/cameras/status';
  static const String addCamera = '/cameras';
  static String cameraDetail(String id) => '/cameras/$id';
  static String enableCamera(String id) => '/cameras/$id/enable';
  static String disableCamera(String id) => '/cameras/$id/disable';
  
  // Analytics
  static const String dashboard = '/analytics/dashboard';
  static const String advanced = '/analytics/advanced';
  static const String heatmap = '/analytics/heatmap';
  static const String exportCsv = '/analytics/export/csv';
  static const String exportPdf = '/analytics/export/pdf';
  
  // Store Profile
  static const String storeProfile = '/store/profile';
  static const String getStoreProfile = '/store/profile';
  static const String updateStoreProfile = '/store/profile';
  
  // Notifications
  static const String getNotifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static String deleteNotification(String id) => '/notifications/$id';
}
