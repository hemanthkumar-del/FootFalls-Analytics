import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/profile_state.dart';
import 'package:footfalls_app/repositories/profile_repository.dart';
import 'package:footfalls_app/services/sync_service.dart';

final Provider<SyncService> syncServiceProvider = Provider<SyncService>((ref) {
  final syncSvc = SyncService();
  syncSvc.startListening();
  return syncSvc;
});

final StateNotifierProvider<ProfileController, ProfileState> profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  // Ensure sync service is running when profile is active
  ref.read(syncServiceProvider);
  return ProfileController(ProfileRepository());
});

class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  StreamSubscription? _profileSub;

  ProfileController(this._repository) : super(const ProfileState(isLoading: true)) {
    _init();
  }

  void _init() {
    _repository.initializeUserDocument().then((_) {
      _profileSub = _repository.getUserProfileStream().listen((snapshot) {
        if (snapshot.exists) {
          state = state.copyWith(isLoading: false, userData: snapshot.data());
        }
      }, onError: (e) {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load profile data.');
      });
    });
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.updateProfile(displayName: displayName, photoUrl: photoUrl);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update profile: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}
