import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/features/favorites/data/datasources/favorites_data_source.dart';
import 'package:property_manager/features/favorites/domain/paging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseFavoritesDataSource implements FavoritesDataSource {
  const new(this._client);

  final SupabaseClient _client;

  static const _table = 'favorites';

  @override
  Future<List<String>> listIds(String userId) => supabaseGuard(() async {
    final rows = await _client
        .from(_table)
        .select('property_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(favoritesLimit);
    return [for (final row in rows) row['property_id'] as String];
  });

  @override
  Future<void> add(String userId, String propertyId) => supabaseGuard(() async {
    try {
      await _client.from(_table).insert({
        'user_id': userId,
        'property_id': propertyId,
      });
    } on PostgrestException catch (error) {
      // Already saved (perhaps from another device): same end state.
      if (error.code != '23505') rethrow;
    }
  });

  @override
  Future<void> remove(String userId, String propertyId) =>
      supabaseGuard(() async {
        await _client
            .from(_table)
            .delete()
            .eq('user_id', userId)
            .eq('property_id', propertyId);
      });
}
