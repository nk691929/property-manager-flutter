import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/features/platform_settings/data/datasources/platform_settings_data_source.dart';
import 'package:property_manager/features/platform_settings/domain/entities/platform_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabasePlatformSettingsDataSource
    implements PlatformSettingsDataSource {
  const new(this._client);

  final SupabaseClient _client;

  static PlatformSettings _fromJson(Map<String, dynamic> json) =>
      PlatformSettings(
        requireListingApproval: json['require_listing_approval'] as bool,
      );

  @override
  Future<PlatformSettings> fetch() => supabaseGuard(() async {
    final row = await _client.from('app_settings').select().single();
    return _fromJson(row);
  });

  @override
  Future<PlatformSettings> setRequireListingApproval({required bool value}) =>
      supabaseGuard(() async {
        final row = await _client
            .from('app_settings')
            .update({'require_listing_approval': value})
            .eq('id', true)
            .select()
            .single();
        return _fromJson(row);
      });
}
