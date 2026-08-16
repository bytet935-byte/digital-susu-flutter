/// Application-level exception hierarchy (spec §12, §27).
///
/// Every error surfaced by repositories/services is converted into a typed
/// [AppException] carrying a **friendly** message safe to show to users.
/// Raw technical errors must never reach the UI directly.
///
/// Phase 2 maps network/API failures onto these types; the sealed hierarchy
/// keeps `switch` statements exhaustive.
sealed class AppException implements Exception {
  const AppException({required this.message, this.code, this.cause});

  /// Human-friendly message intended for end users.
  final String message;

  /// Optional machine-readable code (e.g. API error code) for diagnostics.
  final String? code;

  /// Original error/exception, retained for logging only.
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType(message: $message, code: $code, cause: $cause)';
}

/// Device is offline or a request could not reach the server.
final class NetworkException extends AppException {
  const NetworkException({super.message = 'No internet connection. Please check your network and try again.', super.code, super.cause});
}

/// Request exceeded the configured timeout.
final class ApiTimeoutException extends AppException {
  const ApiTimeoutException({super.message = 'The request took too long. Please try again.', super.code, super.cause});
}

/// Input failed validation (client- or server-side).
final class ValidationException extends AppException {
  const ValidationException({required super.message, super.code, super.cause});
}

/// Authentication is missing or invalid.
final class UnauthorizedException extends AppException {
  const UnauthorizedException({super.message = 'Please log in to continue.', super.code, super.cause});
}

/// Authenticated but not permitted to perform the action (spec §5).
final class ForbiddenException extends AppException {
  const ForbiddenException({super.message = 'You do not have permission to do this.', super.code, super.cause});
}

/// Requested resource does not exist.
final class NotFoundException extends AppException {
  const NotFoundException({super.message = 'The requested item could not be found.', super.code, super.cause});
}

/// Request conflicts with the current state (duplicate, stale version, etc.).
final class ConflictException extends AppException {
  const ConflictException({super.message = 'This action conflicts with the current state. Please refresh and try again.', super.code, super.cause});
}

/// Too many requests; the server asked us to slow down.
final class RateLimitException extends AppException {
  const RateLimitException({super.message = 'Too many attempts. Please wait a moment and try again.', super.code, super.cause});
}

/// The server returned a 5xx error.
final class ServerException extends AppException {
  const ServerException({super.message = 'Our servers are having trouble. Please try again shortly.', super.code, super.cause});
}

/// The API responded with an unexpected/malformed payload.
final class MalformedResponseException extends AppException {
  const MalformedResponseException({super.message = 'We received an unexpected response. Please try again.', super.code, super.cause});
}

/// The access token is expired (used by the refresh flow; Phase 2).
final class TokenExpiredException extends AppException {
  const TokenExpiredException({super.message = 'Your session has expired. Please log in again.', super.code, super.cause});
}

/// The session ended (logout elsewhere, refresh failure, revocation).
final class SessionExpiredException extends AppException {
  const SessionExpiredException({super.message = 'Your session has ended. Please log in again.', super.code, super.cause});
}
