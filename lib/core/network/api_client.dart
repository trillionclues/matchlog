// Dio instance + interceptors
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_interceptors.dart';

class ApiClient {
  static ApiClient? _instance;

  final Dio dio;

  ApiClient._({required this.dio});

  static ApiClient get instance {
    _instance ??= ApiClient._(dio: _createDio());
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        // baseUrl: 'https://api.matchlog.app/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth token injector — attaches Firebase ID token to every request
    dio.interceptors.add(AuthInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(RequestLoggerInterceptor());
    }

    return dio;
  }

  static void reset() {
    _instance?.dio.close();
    _instance = null;
  }
}
