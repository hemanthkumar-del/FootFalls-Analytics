class ProfileState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  const ProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.userData,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? userData,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userData: userData ?? this.userData,
    );
  }

  // Getters for Retail Analytics
  String get storeName => userData?['storeName'] ?? 'Unknown Store';
  String get storeAddress => userData?['storeAddress'] ?? 'No address';
  int get camerasInstalled => userData?['camerasInstalled'] ?? 0;
  int get todayVisitors => userData?['todayVisitors'] ?? 0;
  int get weeklyVisitors => userData?['weeklyVisitors'] ?? 0;
  int get monthlyVisitors => userData?['monthlyVisitors'] ?? 0;
  int get totalVisitors => userData?['totalVisitors'] ?? 0;
  String get peakHour => userData?['peakHour'] ?? 'N/A';
}
