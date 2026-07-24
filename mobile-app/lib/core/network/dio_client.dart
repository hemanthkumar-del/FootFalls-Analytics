import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:footfalls_app/core/constants/app_constants.dart';
import 'package:footfalls_app/core/config/backend_config.dart';
import 'package:footfalls_app/providers/auth_controller.dart';

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: BackendConfig.restApiUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ));

  const storage = FlutterSecureStorage();

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Check for internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: "No internet connection. Please check your network and try again.",
          )
        );
      }

      final token = await storage.read(key: AppConstants.jwtKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException error, handler) async {
      if (!kReleaseMode) {
        debugPrint("API Error: ${error.message}");
      }
      if (error.response?.statusCode == 401) {
        // Trigger logout if token is expired/invalid
        ref.read(authProvider.notifier).logout();
      }
      
      // Friendly error handling
      String message = "An unexpected error occurred. Please try again.";
      if (error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout) {
        message = "Connection timed out. Please try again later.";
      } else if (error.type == DioExceptionType.connectionError) {
        message = error.error?.toString() ?? "Could not connect to the server.";
      } else if (error.response != null) {
        message = error.response?.data?['detail'] ?? error.response?.statusMessage ?? message;
      }
      
      return handler.next(error.copyWith(error: message));
    },
  ));

  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    logPrint: kReleaseMode ? null : print, 
    retries: 3, 
    retryDelays: const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
  ));

  return dio;
});
