import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Maps transport-level failures to the application exception hierarchy
/// (spec §12, §27). No raw technical error ever reaches the UI: every branch
/// produces a user-friendly [AppException].
abstract final class ApiExceptionMapper {
  static AppException fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiTimeoutException(cause: error);

      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return NetworkException(cause: error);

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'The request was cancelled.',
          cause: error,
        );

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status != null) return fromStatusCode(status, error);
        return MalformedResponseException(cause: error);

      case DioExceptionType.unknown:
        // Interceptors may reject with a pre-mapped AppException
        // (e.g. SessionExpiredException after a failed refresh).
        final raw = error.error;
        if (raw is AppException) return raw;
        // JSON decode failures / type errors mean the payload was malformed.
        if (raw is FormatException || raw is TypeError) {
          return MalformedResponseException(cause: error);
        }
        return NetworkException(cause: error);
    }
  }

  static AppException fromStatusCode(int statusCode, DioException error) {
    final message = _extractServerMessage(error.response?.data);
    switch (statusCode) {
      case 400:
      case 422:
        return ValidationException(
          message: message ?? 'Please check your input and try again.',
          code: '$statusCode',
          cause: error,
        );
      case 401:
        return TokenExpiredException(
          message:
              message ?? 'Your session has expired. Please log in again.',
          code: '$statusCode',
          cause: error,
        );
      case 403:
        return ForbiddenException(
          message:
              message ?? 'You do not have permission to do this.',
          code: '$statusCode',
          cause: error,
        );
      case 404:
        return NotFoundException(
          message:
              message ?? 'The requested item could not be found.',
          code: '$statusCode',
          cause: error,
        );
      case 409:
        return ConflictException(
          message:
              message ??
              'This action conflicts with the current state. '
                  'Please refresh and try again.',
          code: '$statusCode',
          cause: error,
        );
      case 429:
        return RateLimitException(
          message:
              message ??
              'Too many attempts. Please wait a moment and try again.',
          code: '$statusCode',
          cause: error,
        );
      default:
        if (statusCode >= 500) {
          return ServerException(
            message:
                message ??
                'Our servers are having trouble. Please try again shortly.',
            code: '$statusCode',
            cause: error,
          );
        }
        return MalformedResponseException(
          code: '$statusCode',
          cause: error,
        );
    }
  }

  /// Prefers the server's own `message`/`error` field when present and
  /// readable; ignores HTML error pages.
  static String? _extractServerMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final dynamic message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) return message;
    } else if (data is String && data.isNotEmpty && !data.startsWith('<')) {
      return data;
    }
    return null;
  }
}
