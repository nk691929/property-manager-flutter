import 'package:property_manager/features/favorites/data/datasources/favorites_data_source.dart';

final class FakeFavoritesDataSource implements FavoritesDataSource {
  final Map<String, List<String>> _byUser = {};

  @override
  Future<List<String>> listIds(String userId) async =>
      List.of(_byUser[userId] ?? const <String>[]);

  @override
  Future<void> add(String userId, String propertyId) async {
    final ids = _byUser.putIfAbsent(userId, () => []);
    if (!ids.contains(propertyId)) ids.insert(0, propertyId);
  }

  @override
  Future<void> remove(String userId, String propertyId) async =>
      _byUser[userId]?.remove(propertyId);
}
