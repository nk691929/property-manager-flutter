/// Implementations throw typed `Failure`s, never SDK exceptions.
abstract interface class FavoritesDataSource {
  Future<List<String>> listIds(String userId);

  Future<void> add(String userId, String propertyId);

  Future<void> remove(String userId, String propertyId);
}
