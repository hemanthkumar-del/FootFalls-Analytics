import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:footfalls_app/core/config/api_constants.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> updateStoreProfile({
    String? storeName, 
    String? storeAddress,
    String? phoneNumber,
    String? bio,
  }) async {
    await _dio.put(ApiConstants.storeProfile, data: {
      if (storeName != null) 'store_name': storeName,
      if (storeAddress != null) 'address': storeAddress,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (bio != null) 'bio': bio,
    });
  }

  Future<String> saveProfileImageLocally(File file) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Delete old file if it exists at the same path, or we can just overwrite.
      // Copying automatically overwrites on most platforms, but to be safe and handle user requirement #12:
      // "Handle image replacement safely by deleting the previous local image only after the new image is successfully saved."
      // So we use a unique timestamped name or just save over it. Wait, the user wants us to delete the OLD image only AFTER saving the new one.
      
      // Get the existing photoUrl to delete it later
      final oldPhotoUrl = user.photoURL;
      
      final String newFileName = 'profile_image_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newPath = '${directory.path}/$newFileName';
      
      final File newFile = await file.copy(newPath);
      
      // If the new file is saved successfully, delete the old file if it exists and is local
      if (oldPhotoUrl != null && !oldPhotoUrl.startsWith('http')) {
        final oldFile = File(oldPhotoUrl);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
            debugPrint('Successfully deleted old local profile image.');
          } catch (e) {
            debugPrint('Warning: Could not delete old local profile image: $e');
          }
        }
      }
      
      return newFile.path;
    } catch (e) {
      debugPrint('Local storage save exception: $e');
      throw Exception('Failed to save image locally. Please try again. Error: $e');
    }
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    if (displayName != null) await user.updateDisplayName(displayName);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
  }
}
