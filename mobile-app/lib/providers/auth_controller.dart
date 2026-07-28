import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/auth_state.dart';
import 'package:footfalls_app/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:footfalls_app/core/constants/app_constants.dart';

final StateNotifierProvider<AuthController, AuthState> authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authServiceProvider));
});

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthState()) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Check if there is a cached session first
    final cachedUser = await _authService.getCachedUser();
    if (cachedUser != null) {
      state = state.copyWith(status: AuthStatus.authenticated, user: cachedUser);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }

    // Listen to Firebase Auth state changes
    _authService.repository.authStateChanges.listen((user) async {
      if (user != null) {
        await _authService.cacheUser(user);
        
        // Also get the Firebase token and save it to Secure Storage for Dio requests
        final token = await _authService.repository.getIdToken();
        if (token != null) {
          const storage = FlutterSecureStorage();
          await storage.write(key: AppConstants.jwtKey, value: token);
        }
        
        state = state.copyWith(status: AuthStatus.authenticated, user: user, errorMessage: null);
      } else {
        await _authService.clearCache();
        const storage = FlutterSecureStorage();
        await storage.delete(key: AppConstants.jwtKey);
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      }
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.repository.loginWithEmail(email, password);
      if (user != null) {
        await _authService.cacheUser(user);
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: 'Login failed.');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  Future<void> signupWithEmail(String email, String password, String name) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.repository.signupWithEmail(email, password, name);
      if (user != null) {
        await _authService.cacheUser(user);
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: 'Signup failed.');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.repository.loginWithGoogle();
      if (user != null) {
        await _authService.cacheUser(user);
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        // User canceled the flow
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.repository.sendPasswordResetEmail(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authService.repository.logout();
      await _authService.clearCache();
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.authenticated, errorMessage: e.toString());
    }
  }
}
