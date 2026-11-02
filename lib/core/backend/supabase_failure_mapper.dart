import 'dart:async';
import 'dart:io';

import 'package:property_manager/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Runs [body]; any SDK exception is rethrown as a typed [Failure].
/// [customMapper] gets the first chance (feature-specific codes).
Future<T> supabaseGuard<T>(
  Future<T> Function() body, {
  Failure? Function(Object error, StackTrace stackTrace)? customMapper,
}) async {
  try {
    return await body();
  } on Object catch (error, stackTrace) {
    throw customMapper?.call(error, stackTrace) ??
        mapSupabaseError(error, stackTrace);
  }
}

Failure mapSupabaseError(Object error, StackTrace stackTrace) {
  if (error is Failure) return error;
  if (error is AuthRetryableFetchException ||
      error is SocketException ||
      error is TimeoutException) {
    return NetworkFailure(cause: error, stackTrace: stackTrace);
  }
  if (error is AuthException) {
    return switch (error.code) {
      'invalid_credentials' => InvalidCredentialsFailure(
        cause: error,
        stackTrace: stackTrace,
      ),
      _ => UnknownFailure(cause: error, stackTrace: stackTrace),
    };
  }
  if (error is PostgrestException) {
    return switch (error.code) {
      '42501' => ForbiddenFailure(cause: error, stackTrace: stackTrace),
      '23514' || '22P02' => ValidationFailure(
        const {},
        cause: error,
        stackTrace: stackTrace,
      ),
      'PGRST116' => NotFoundFailure(cause: error, stackTrace: stackTrace),
      'PGRST301' => UnauthorizedFailure(cause: error, stackTrace: stackTrace),
      _ => UnknownFailure(cause: error, stackTrace: stackTrace),
    };
  }
  return UnknownFailure(cause: error, stackTrace: stackTrace);
}
