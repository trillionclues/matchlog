// Auth token, logging, retry

library;

import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        options.headers['Authorization'] = 'Bearer $token';
      } catch (_) {
        // If token refresh fails, server will return 401 for re-auth.
      }
    }
    handler.next(options);
  }
}

class RequestLoggerInterceptor extends Interceptor {
  static const _tag = 'HTTP';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final uri = options.uri;
    dev.log(
      '→ $method $uri',
      name: _tag,
    );

    if (options.queryParameters.isNotEmpty) {
      dev.log('  Query: ${options.queryParameters}', name: _tag);
    }

    if (options.data != null) {
      final body = options.data.toString();
      final preview = body.length > 500 ? '${body.substring(0, 500)}…' : body;
      dev.log('  Body: $preview', name: _tag);
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri;
    final status = response.statusCode;
    dev.log(
      '← $status $method $uri',
      name: _tag,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final method = err.requestOptions.method.toUpperCase();
    final uri = err.requestOptions.uri;
    final status = err.response?.statusCode ?? 'N/A';
    dev.log(
      '✗ $status $method $uri — ${err.message}',
      name: _tag,
      level: 1000,
    );
    handler.next(err);
  }
}
