/// Result type for handling success/failure patterns
sealed class Result<T> {
  const Result();
  
  /// Create a success result
  factory Result.success(T data) = Success<T>;
  
  /// Create a failure result
  factory Result.failure(String message, [Object? error]) = Failure<T>;
  
  /// Map the result to another type
  Result<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      Success<T>(data: final data) => Result.success(mapper(data)),
      Failure<T>(message: final msg, error: final err) => Result.failure(msg, err),
    };
  }
  
  /// Handle both success and failure cases
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success(data),
      Failure<T>(message: final msg, error: final err) => failure(msg, err),
    };
  }
  
  /// Get the data if success, otherwise null
  T? get dataOrNull => switch (this) {
    Success<T>(data: final data) => data,
    Failure<T>() => null,
  };
  
  /// Check if this is a success
  bool get isSuccess => this is Success<T>;
  
  /// Check if this is a failure
  bool get isFailure => this is Failure<T>;
}

/// Success result
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Failure result
class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, [this.error]);
}
