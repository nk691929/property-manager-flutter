import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/features/user_directory/data/datasources/user_directory_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseUserDirectoryDataSource implements UserDirectoryDataSource {
  const new(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, String>> fetchNames(Set<String> userIds) =>
      supabaseGuard(() async {
        // `visible_names` is the narrow SECURITY DEFINER window from migration
        final response = await _client.rpc<dynamic>(
          'visible_names',
          params: {'p_ids': userIds.toList()},
        );
        final rows = (response as List<dynamic>?) ?? const <dynamic>[];

        final names = <String, String>{};
        for (final raw in rows) {
          final row = raw as Map<String, dynamic>;
          final name = (row['full_name'] as String?)?.trim();
          if (name != null && name.isNotEmpty) {
            names[row['id'] as String] = name;
          }
        }
        return names;
      });
}
