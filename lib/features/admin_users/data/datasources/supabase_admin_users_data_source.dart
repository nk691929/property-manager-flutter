import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/features/admin_users/data/datasources/admin_users_data_source.dart';
import 'package:property_manager/features/auth/data/models/profile_model.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseAdminUsersDataSource implements AdminUsersDataSource {
  const new(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ProfileModel>> listProfiles() => supabaseGuard(() async {
    final rows = await _client.from('profiles').select().order('created_at');
    return rows.map(ProfileModel.fromJson).toList();
  });

  @override
  Future<ProfileModel> updateRole(String userId, Role role) =>
      supabaseGuard(() async {
        final row = await _client
            .from('profiles')
            .update({'role': role.wireName})
            .eq('id', userId)
            .select()
            .single();
        return ProfileModel.fromJson(row);
      });
}
