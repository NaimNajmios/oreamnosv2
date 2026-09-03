library;

sealed class Result<T> {
  const Result();

  R fold<R>(R Function(T data) onSuccess, R Function(Failure failure) onError) {
    if (this is ResultSuccess<T>) {
      return onSuccess((this as ResultSuccess<T>).data);
    } else if (this is ResultError<T>) {
      return onError((this as ResultError<T>).failure);
    }
    throw StateError('Unreachable code in Result.fold');
  }

  T? get dataOrNull {
    if (this is ResultSuccess<T>) return (this as ResultSuccess<T>).data;
    return null;
  }
}

class ResultSuccess<T> extends Result<T> {
  const ResultSuccess(this.data);
  final T data;
}

class ResultError<T> extends Result<T> {
  const ResultError(this.failure);
  final Failure failure;
}

sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message, {this.retryDelayMs, this.providerName});

  /// Milliseconds the provider asked us to wait (Gemini
  /// `error.details.retryDelay` or `Retry-After` header). Null if unknown.
  final int? retryDelayMs;

  /// Provider that rate-limited us (e.g. `gemini`), for fallback messaging.
  final String? providerName;

  /// Human wait-time message, e.g. "Retry in 34s" or "Retry shortly".
  String get waitTimeMessage {
    if (retryDelayMs == null) return 'Retry shortly';
    final s = (retryDelayMs! / 1000).ceil();
    if (s < 60) return 'Retry in ${s}s';
    return 'Retry in ${s ~/ 60}m ${s % 60}s';
  }
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
