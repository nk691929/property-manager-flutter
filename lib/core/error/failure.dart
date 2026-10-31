/// Typed, UI-agnostic errors. Messages are mapped to localized text in the
/// presentation layer, never stored here.
sealed class Failure implements Exception {
  const new({this.cause, this.stackTrace});

  final Object? cause;
  final StackTrace? stackTrace;

  /// Explicit fallback identity name for safe production logging.
  String get name => 'Failure';

  @override
  String toString() => '$name(cause: $cause)';
}

final class NetworkFailure extends Failure {
  const new({super.cause, super.stackTrace});

  @override
  String get name => 'NetworkFailure';
}

final class UnauthorizedFailure extends Failure {
  const new({super.cause, super.stackTrace});

  @override
  String get name => 'UnauthorizedFailure';
}

final class ForbiddenFailure extends Failure {
  const new({super.cause, super.stackTrace});

  @override
  String get name => 'ForbiddenFailure';
}

final class NotFoundFailure extends Failure {
  const new({super.cause, super.stackTrace});

  @override
  String get name => 'NotFoundFailure';
}

final class ValidationFailure extends Failure {
  const new(this.fieldErrors, {super.cause, super.stackTrace});

  /// field name -> error code (mapped to localized text in the UI).
  final Map<String, String> fieldErrors;

  @override
  String get name => 'ValidationFailure';

  @override
  String toString() => '$name(fieldErrors: $fieldErrors, cause: $cause)';
}

final class CacheFailure extends Failure {
  const new({super.cause, super.stackTrace});

  @override
  String get name => 'CacheFailure';
}

final class UnknownFailure extends Failure {
  const new({super.cause, super.stackTrace});

  @override
  String get name => 'UnknownFailure';
}

final class InvalidCredentialsFailure extends Failure {
  const new({super.cause, super.stackTrace});

  @override
  String get name => 'InvalidCredentialsFailure';
}

/// Converts any thrown value into a [Failure] (used at UI boundaries).
Failure toFailure(Object error) =>
    error is Failure ? error : UnknownFailure(cause: error);
