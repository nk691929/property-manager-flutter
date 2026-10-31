import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';

/// Runs [body] and converts the outcome into a [Result].
///
/// Data sources throw [Failure]s; anything else is unexpected and becomes
/// an [UnknownFailure] so no raw exception ever crosses the repository.
Future<Result<T>> runCatching<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on Failure catch (failure) {
    return Err(failure);
  } on Object catch (error, stackTrace) {
    return Err(UnknownFailure(cause: error, stackTrace: stackTrace));
  }
}
