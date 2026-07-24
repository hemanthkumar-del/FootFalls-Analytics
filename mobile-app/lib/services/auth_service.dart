import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/models/user_model.dart';
import 'package:footfalls_app/repositories/auth_repository.dart';

final Provider<AuthService> authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(authRepositoryProvider));
});

class AuthService {
  final AuthRepository _repository;
  final _storage = const FlutterSecureStorage();
  static const _userKey = 'cached_user';

  AuthService(this._repository);

  AuthRepository get repository => _repository;

  Future<void> cacheUser(UserModel user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<UserModel?> getCachedUser() async {
    final data = await _storage.read(key: _userKey);
    if (data != null) {
      return UserModel.fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<void> clearCache() async {
    await _storage.delete(key: _userKey);
  }
}
