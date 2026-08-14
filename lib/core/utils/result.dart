import '../../core/errors/app_exception.dart';

/// Functional result type used by repositories/services (Phase 2+).
///
/// Repositories return `Result<T>` so callers must explicitly handle both
/// success and failure — financial operations must never swallow errors.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppException error;
}

extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  /// Value when successful, otherwise `null`.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  /// Error when failed, otherwise `null`.
  AppException? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };
}
