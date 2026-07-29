import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/profile_state.dart';
import 'package:footfalls_app/repositories/profile_repository.dart';
import 'package:footfalls_app/providers/auth_controller.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(
    ref.watch(profileRepositoryProvider),
    ref.read(authProvider.notifier),
  );
});

class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final AuthController _authController;

  ProfileController(this._repository, this._authController) : super(const ProfileState(isLoading: true)) {
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
      await _authController.updateLocalUserProfile(displayName: displayName, photoUrl: photoUrl);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update profile: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveProfile({
    required String fullName,
    required String phoneNumber,
    required String storeName,
    required String storeAddress,
    required String bio,
    File? newProfileImage,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      String? photoUrl;
      if (newProfileImage != null) {
        photoUrl = await _repository.saveProfileImageLocally(newProfileImage);
      }

      await _repository.updateStoreProfile(
        storeName: storeName,
        storeAddress: storeAddress,
        phoneNumber: phoneNumber,
        bio: bio,
      );

      await _repository.updateProfile(
        displayName: fullName,
        photoUrl: photoUrl,
      );

      await _authController.updateLocalUserProfile(
        displayName: fullName,
        photoUrl: photoUrl,
      );

      await _init(); // Refresh data
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save profile: $e');
      rethrow;
    }
  }
}
