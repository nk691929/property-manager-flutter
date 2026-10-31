import 'dart:developer' as developer;

abstract interface class AppLogger {
  void debug(String message);
  void info(String message);
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
}

/// Writes to the Dart developer log (visible in DevTools / IDE console).
/// A crash-reporting logger (Sentry/Crashlytics) can implement the same
/// interface later without touching callers.
final class DeveloperLogger implements AppLogger {
  const new({this.verbose = true});

  /// When false (prod), debug and info are dropped.
  final bool verbose;

  @override
  void debug(String message) {
    if (verbose) developer.log(message, name: 'PM', level: 500);
  }

  @override
  void info(String message) {
    if (verbose) developer.log(message, name: 'PM', level: 800);
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'PM',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'PM',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
