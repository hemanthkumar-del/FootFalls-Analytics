import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:footfalls_app/repositories/profile_repository.dart';

class SyncService {
  final ProfileRepository _profileRepo = ProfileRepository();
  StreamSubscription? _connectivitySub;

  void startListening() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        syncPendingData();
      }
    });
  }

  Future<void> syncPendingData() async {
    final uid = _profileRepo.currentUid;
    if (uid == null) return;

    await _profileRepo.initializeUserDocument();

    // Placeholder for future offline syncing of retail logs (e.g. visitor_logs, camera_events)
    // The actual AI pushes data to Firestore directly, so mobile app mostly acts as a reader.
    // However, if the store manager performs offline actions (like changing settings), 
    // this batch operation will push them when re-connected.
  }

  void stopListening() {
    _connectivitySub?.cancel();
  }
}
