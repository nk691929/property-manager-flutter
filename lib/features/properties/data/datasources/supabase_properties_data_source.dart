import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/properties/data/datasources/properties_data_source.dart';
import 'package:property_manager/features/properties/data/property_json.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabasePropertiesDataSource implements PropertiesDataSource {
  const new(this._client);

  final SupabaseClient _client;

  static const _table = 'properties';

  /// User text goes into a PostgREST filter string, so strip the characters
  /// that carry meaning there (commas, parentheses, wildcards, quotes).
  static String _clean(String raw) =>
      raw.replaceAll(RegExp(r'[,()%*\\"]'), ' ').trim();

  @override
  Future<List<Property>> search(
    PropertyFilter filter, {
    required int offset,
    required int limit,
  }) => supabaseGuard(() async {
    var query = _client
        .from(_table)
        .select()
        .eq('status', PropertyStatus.published.wireName);

    final text = _clean(filter.query);
    if (text.isNotEmpty) {
      query = query.or('title.ilike.*$text*,city.ilike.*$text*');
    }
    final city = _clean(filter.city);
    if (city.isNotEmpty) query = query.ilike('city', '%$city%');
    if (filter.listingType case final type?) {
      query = query.eq('listing_type', type.wireName);
    }
    if (filter.propertyType case final type?) {
      query = query.eq('property_type', type.wireName);
    }
    if (filter.minPrice case final min?) query = query.gte('price', min);
    if (filter.maxPrice case final max?) query = query.lte('price', max);
    if (filter.minBedrooms case final min?) {
      query = query.gte('bedrooms', min);
    }

    final ordered = switch (filter.sort) {
      PropertySort.newest => query.order('published_at', ascending: false),
      PropertySort.priceAsc => query.order('price', ascending: true),
      PropertySort.priceDesc => query.order('price', ascending: false),
    };
    // `id` is a tie-breaker so pages never overlap or skip rows.
    final rows = await ordered
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    return rows.map(propertyFromJson).toList();
  });

  @override
  Future<List<Property>> listByAgent(
    String agentId, {
    required int offset,
    required int limit,
    PropertyStatus? status,
  }) => supabaseGuard(() async {
    var query = _client.from(_table).select().eq('agent_id', agentId);
    if (status case final s?) query = query.eq('status', s.wireName);
    final rows = await query
        .order('updated_at', ascending: false)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    return rows.map(propertyFromJson).toList();
  });

  @override
  Future<List<Property>> listAll({
    required int offset,
    required int limit,
    PropertyStatus? status,
  }) => supabaseGuard(() async {
    var query = _client.from(_table).select();
    if (status case final s?) query = query.eq('status', s.wireName);
    final rows = await query
        .order('updated_at', ascending: false)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    return rows.map(propertyFromJson).toList();
  });

  @override
  Future<Property> getById(String id) => supabaseGuard(() async {
    final row = await _client.from(_table).select().eq('id', id).single();
    return propertyFromJson(row);
  });

  @override
  Future<Property> create(PropertyDraft draft, String agentId) =>
      supabaseGuard(() async {
        final row = await _client
            .from(_table)
            .insert({...draftToJson(draft), 'agent_id': agentId})
            .select()
            .single();
        return propertyFromJson(row);
      });

  @override
  Future<Property> update(String id, PropertyDraft draft) =>
      supabaseGuard(() async {
        final row = await _client
            .from(_table)
            .update(draftToJson(draft))
            .eq('id', id)
            .select()
            .single();
        return propertyFromJson(row);
      });

  @override
  Future<Property> setStatus(
    String id,
    PropertyStatus status, {
    String? rejectionReason,
  }) => supabaseGuard(() async {
    final row = await _client
        .from(_table)
        .update({
          'status': status.wireName,
          if (status == PropertyStatus.rejected)
            'rejection_reason': rejectionReason,
        })
        .eq('id', id)
        .select()
        .single();
    return propertyFromJson(row);
  });

  @override
  Future<Property> reassign(String id, String agentId) =>
      supabaseGuard(() async {
        final row = await _client
            .from(_table)
            .update({'agent_id': agentId})
            .eq('id', id)
            .select()
            .single();
        return propertyFromJson(row);
      });

  @override
  Future<void> delete(String id) => supabaseGuard(() async {
    // RLS hides rows silently, so check that something was deleted.
    final rows = await _client.from(_table).delete().eq('id', id).select();
    if (rows.isEmpty) throw const NotFoundFailure();
  });
}
