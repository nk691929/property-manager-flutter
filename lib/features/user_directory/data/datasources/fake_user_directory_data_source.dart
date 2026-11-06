import 'package:property_manager/features/user_directory/data/datasources/user_directory_data_source.dart';

/// Offline demo names; ids match the fake auth accounts and seeded listings.
final class FakeUserDirectoryDataSource implements UserDirectoryDataSource {
  const new();

  static const _names = {
    'u-admin': 'Ada Admin',
    'u-agent': 'Alex Agent',
    'u-client': 'Casey Client',
  };

  @override
  Future<Map<String, String>> fetchNames(Set<String> userIds) async => {
    for (final id in userIds) id: ?_names[id],
  };
}
