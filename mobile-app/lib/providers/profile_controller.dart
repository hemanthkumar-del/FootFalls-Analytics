import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/profile_state.dart';
import 'package:footfalls_app/repositories/profile_repository.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(ref.watch(profileRepositoryProvider));
});

class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileController(this._repository) : super(const ProfileState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    if (!mounted) return;
    try {
      final data = await _repository.getStoreProfile();
      if (mounted) {
        state = state.copyWith(isLoading: false, userData: data);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load profile data.');
      }
    }
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
}
