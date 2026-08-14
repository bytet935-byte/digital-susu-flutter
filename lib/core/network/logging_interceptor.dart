import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/environment.dart';

/// Console logging interceptor, active only when
/// `DEBUG_LOGGING=true` (via `--dart-define`).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppEnvironment.debugLogging) {
      debugPrint('[DS] → ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (AppEnvironment.debugLogging) {
      debugPrint(
        '[DS] ← ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppEnvironment.debugLogging) {
      debugPrint(
        '[DS] ✗ ${err.type} ${err.requestOptions.uri} '
        '(${err.response?.statusCode})',
      );
    }
    handler.next(err);
  }
}
