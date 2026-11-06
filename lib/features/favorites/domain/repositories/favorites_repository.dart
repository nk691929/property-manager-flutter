import 'package:property_manager/core/result/result.dart';

abstract interface class FavoritesRepository {
  /// Saved property ids, newest first.
  Future<Result<List<String>>> listIds(String userId);

  /// Idempotent: saving an already-saved property is a success.
  Future<Result<void>> add(String userId, String propertyId);

  /// Idempotent: removing something that isn't saved is a success.
  Future<Result<void>> remove(String userId, String propertyId);
}
