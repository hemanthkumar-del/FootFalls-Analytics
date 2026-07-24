import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/auth_controller.dart';
import 'package:footfalls_app/providers/auth_state.dart';

// Imports for screens
import 'package:footfalls_app/screens/splash_screen.dart';
import 'package:footfalls_app/screens/login_screen.dart';
import 'package:footfalls_app/screens/signup_screen.dart';
import 'package:footfalls_app/screens/forgot_password_screen.dart';
import 'package:footfalls_app/screens/dashboard_screen.dart';
import 'package:footfalls_app/screens/profile_screen.dart';
import 'package:footfalls_app/screens/camera_management_screen.dart';
import 'package:footfalls_app/screens/other_screens.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isSplash = state.uri.path == '/splash';
      final isLoggingIn = state.uri.path == '/login';
      final isSigningUp = state.uri.path == '/signup';
      final isForgotPass = state.uri.path == '/forgot-password';

      if (authState.status == AuthStatus.initial) return null;

      // Unauthenticated users can access login, signup, forgot-password
      if (!isAuth && !isLoggingIn && !isSigningUp && !isForgotPass) return '/login';
      
      // Authenticated users go straight to dashboard
      if (isAuth && (isLoggingIn || isSigningUp || isForgotPass || isSplash)) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(path: 'live', builder: (context, state) => const LiveMonitoringScreen()),
          GoRoute(path: 'stores', builder: (context, state) => const StoresScreen()),
          GoRoute(path: 'cameras', builder: (context, state) => const CameraManagementScreen()),
          GoRoute(path: 'profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
        ]
      ),
    ],
  );
});
