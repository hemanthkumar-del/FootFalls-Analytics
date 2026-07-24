import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/constants/app_constants.dart';
import 'package:footfalls_app/core/config/backend_config.dart';
import 'package:footfalls_app/providers/auth_controller.dart';

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: BackendConfig.restApiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  const storage = FlutterSecureStorage();

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: AppConstants.jwtKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException error, handler) async {
      if (error.response?.statusCode == 401) {
        // Trigger logout if token is expired/invalid
        ref.read(authProvider.notifier).logout();
      }
      return handler.next(error);
    },
  ));

  return dio;
});
