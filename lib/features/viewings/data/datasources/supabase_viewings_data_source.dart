import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/features/viewings/data/datasources/viewings_data_source.dart';
import 'package:property_manager/features/viewings/data/viewing_json.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseViewingsDataSource implements ViewingsDataSource {
  const new(this._client);

  final SupabaseClient _client;

  static const _table = 'viewings';

  @override
  Future<List<Viewing>> listForClient(String clientId, {required int limit}) =>
      supabaseGuard(() async {
        final rows = await _client
            .from(_table)
            .select(viewingSelect)
            .eq('client_id', clientId)
            .order('scheduled_at', ascending: false)
            .order('id', ascending: true)
            .limit(limit);
        return rows.map(viewingFromJson).toList();
      });

  @override
  Future<List<Viewing>> listForAgent(String agentId, {required int limit}) =>
      supabaseGuard(() async {
        // Inner join + filter on the embedded column = "listings I own now".
        final rows = await _client
            .from(_table)
            .select(viewingSelectInner)
            .eq('properties.agent_id', agentId)
            .order('scheduled_at', ascending: false)
            .order('id', ascending: true)
            .limit(limit);
        return rows.map(viewingFromJson).toList();
      });

  @override
  Future<Viewing> getById(String id) => supabaseGuard(() async {
    final row = await _client
        .from(_table)
        .select(viewingSelect)
        .eq('id', id)
        .single();
    return viewingFromJson(row);
  });

  @override
  Future<Viewing?> findActive(String clientId, String propertyId) =>
      supabaseGuard(() async {
        // A partial unique index allows at most one active row per pair.
        final row = await _client
            .from(_table)
            .select(viewingSelect)
            .eq('client_id', clientId)
            .eq('property_id', propertyId)
            .inFilter('status', [
              ViewingStatus.requested.wireName,
              ViewingStatus.confirmed.wireName,
            ])
            .maybeSingle();
        return row == null ? null : viewingFromJson(row);
      });

  @override
  Future<Viewing> request({
    required String propertyId,
    required String clientId,
    required DateTime scheduledAt,
  }) => supabaseGuard(() async {
    final row = await _client
        .from(_table)
        .insert({
          'property_id': propertyId,
          'client_id': clientId,
          // DateTime can't go through JSON; send UTC explicitly.
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        })
        .select(viewingSelect)
        .single();
    return viewingFromJson(row);
  });

  @override
  Future<Viewing> setStatus(
    String id,
    ViewingStatus status, {
    String? declineReason,
  }) => supabaseGuard(() async {
    final row = await _client
        .from(_table)
        .update({
          'status': status.wireName,
          if (status == ViewingStatus.declined) 'decline_reason': declineReason,
        })
        .eq('id', id)
        .select(viewingSelect)
        .single();
    return viewingFromJson(row);
  });
}
