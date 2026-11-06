import 'package:property_manager/core/result/result.dart';

abstract interface class UserDirectoryRepository {
  /// Display names keyed by user id. Ids the caller may not see, and users
  /// without a name, are simply absent from the map.
  Future<Result<Map<String, String>>> namesFor(Set<String> userIds);
}
