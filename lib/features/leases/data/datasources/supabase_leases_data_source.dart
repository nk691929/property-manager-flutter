import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/leases/data/datasources/leases_data_source.dart';
import 'package:property_manager/features/leases/data/lease_json.dart';
import 'package:property_manager/features/leases/domain/entities/leasable_property.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseLeasesDataSource implements LeasesDataSource {
  const new(this._client);

  final SupabaseClient _client;

  static const _leases = 'leases';

  @override
  Future<List<Lease>> listForTenant(String tenantId, {required int limit}) =>
      supabaseGuard(() async {
        final rows = await _client
            .from(_leases)
            .select(leaseSelect)
            .eq('tenant_id', tenantId)
            .order('created_at', ascending: false)
            .order('id', ascending: true)
            .limit(limit);
        return rows.map(leaseFromJson).toList();
      });

  @override
  Future<List<Lease>> listForAgent(String agentId, {required int limit}) =>
      supabaseGuard(() async {
        // Inner join + filter on the embedded column = "listings I own now".
        final rows = await _client
            .from(_leases)
            .select(leaseSelectInner)
            .eq('properties.agent_id', agentId)
            .order('created_at', ascending: false)
            .order('id', ascending: true)
            .limit(limit);
        return rows.map(leaseFromJson).toList();
      });

  @override
  Future<Lease> getById(String id) => supabaseGuard(() async {
    final row = await _client
        .from(_leases)
        .select(leaseSelect)
        .eq('id', id)
        .single();
    return leaseFromJson(row);
  });

  @override
  Future<List<String>> tenantCandidateIds(String propertyId) =>
      supabaseGuard(() async {
        // Mirrors the rule in `create_lease`: the tenant sent an inquiry or
        // completed a viewing. RLS lets the listing's agent read both.
        final inquiries = await _client
            .from('inquiries')
            .select('client_id')
            .eq('property_id', propertyId);
        final viewings = await _client
            .from('viewings')
            .select('client_id')
            .eq('property_id', propertyId)
            .eq('status', 'completed');
        return {
          for (final row in [...inquiries, ...viewings])
            row['client_id'] as String,
        }.toList();
      });

  @override
  Future<List<LeasableProperty>> leasableProperties(String agentId) =>
      supabaseGuard(() async {
        final rows = await _client
            .from('properties')
            .select('id, title, city, price, currency')
            .eq('agent_id', agentId)
            .eq('listing_type', 'rent')
            .inFilter('status', ['published', 'archived'])
            .order('updated_at', ascending: false)
            .limit(100);
        if (rows.isEmpty) return const <LeasableProperty>[];

        final leased = await _client
            .from(_leases)
            .select('property_id')
            .eq('status', 'active')
            .inFilter('property_id', [for (final r in rows) r['id'] as String]);
        final leasedIds = {for (final r in leased) r['property_id'] as String};

        return [
          for (final row in rows)
            if (!leasedIds.contains(row['id']))
              LeasableProperty(
                id: row['id'] as String,
                title: row['title'] as String,
                city: row['city'] as String,
                monthlyRent: Money.parse(
                  row['price'],
                  currency: row['currency'] as String? ?? 'PKR',
                ),
              ),
        ];
      });

  @override
  Future<Lease> create(NewLease draft) => supabaseGuard(() async {
    // One transaction: the lease and its whole schedule, or nothing.
    final dynamic id = await _client.rpc<dynamic>(
      'create_lease',
      params: {
        'p_property_id': draft.propertyId,
        'p_tenant_id': draft.tenantId,
        'p_start': Calendar.formatIso(draft.startDate),
        'p_end': Calendar.formatIso(draft.endDate),
        'p_monthly_rent': draft.monthlyRent.toDecimalString(),
        'p_due_day': draft.dueDay,
        'p_deposit': draft.securityDeposit.toDecimalString(),
      },
    );
    return await getById(id as String);
  });
}
