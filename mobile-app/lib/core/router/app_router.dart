import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/auth_controller.dart';
import 'package:footfalls_app/providers/auth_state.dart';

// Imports for screens
import 'package:footfalls_app/screens/splash_screen.dart';
import 'package:footfalls_app/screens/onboarding_screen.dart';
import 'package:footfalls_app/screens/login_screen.dart';
import 'package:footfalls_app/screens/signup_screen.dart';
import 'package:footfalls_app/screens/forgot_password_screen.dart';
import 'package:footfalls_app/screens/dashboard_screen.dart';
import 'package:footfalls_app/screens/profile_screen.dart';
import 'package:footfalls_app/screens/camera_monitoring_screen.dart';
import 'package:footfalls_app/screens/reports_screen.dart';
import 'package:footfalls_app/screens/camera_management_screen.dart';
import 'package:footfalls_app/screens/store_profile_screen.dart';
import 'package:footfalls_app/screens/settings_screen.dart';
import 'package:footfalls_app/screens/notification_screen.dart';
import 'package:footfalls_app/screens/notification_prefs_screen.dart';
import 'package:footfalls_app/screens/edit_profile_screen.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isSplash = state.uri.path == '/splash';
      final isOnboarding = state.uri.path == '/onboarding';
      final isLoggingIn = state.uri.path == '/login';
      final isSigningUp = state.uri.path == '/signup';
      final isForgotPass = state.uri.path == '/forgot-password';

      if (authState.status == AuthStatus.initial) return null;

      // Unauthenticated users can access splash, onboarding, login, signup, forgot-password
      if (!isAuth && !isLoggingIn && !isSigningUp && !isForgotPass && !isSplash && !isOnboarding) return '/login';
      
      // Authenticated users go straight to dashboard
      if (isAuth && (isLoggingIn || isSigningUp || isForgotPass || isSplash || isOnboarding)) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(path: 'live', builder: (context, state) => const CameraMonitoringScreen()),
          GoRoute(path: 'stores', builder: (context, state) => const StoreProfileScreen()),
          GoRoute(path: 'cameras', builder: (context, state) => const CameraManagementScreen()),
          GoRoute(path: 'reports', builder: (context, state) => const ReportsScreen()),
          GoRoute(path: 'profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: 'profile/edit', builder: (context, state) => const EditProfileScreen()),
          GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(path: 'notifications', builder: (context, state) => const NotificationScreen()),
          GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
          GoRoute(path: 'notifications_prefs', builder: (context, state) => const NotificationPreferencesScreen()),
        ]
      ),
    ],
  );
});
