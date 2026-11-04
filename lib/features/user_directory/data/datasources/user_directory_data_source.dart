/// Implementations throw typed `Failure`s, never SDK exceptions.
abstract interface class UserDirectoryDataSource {
  Future<Map<String, String>> fetchNames(Set<String> userIds);
}
