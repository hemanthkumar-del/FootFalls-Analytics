import 'package:dio/dio.dart';
import 'package:footfalls_app/core/config/api_constants.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

class ProfileRepository {
  final Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileRepository(this._dio);

  String? get currentUid => _auth.currentUser?.uid;

  Future<void> initializeUserDocument() async {
    // No-op for backend since it's handled on the backend or we just use GET
  }

  Future<Map<String, dynamic>> getStoreProfile() async {
    final res = await _dio.get(ApiConstants.storeProfile);
    return res.data;
  }

  Future<void> updateStoreProfile({String? storeName, String? storeAddress}) async {
    await _dio.put(ApiConstants.storeProfile, data: {
      if (storeName != null) 'store_name': storeName,
      if (storeAddress != null) 'address': storeAddress,
    });
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    if (displayName != null) await user.updateDisplayName(displayName);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
  }
}
