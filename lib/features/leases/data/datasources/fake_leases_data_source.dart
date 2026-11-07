import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/features/leases/data/datasources/leases_data_source.dart';
import 'package:property_manager/features/leases/domain/entities/leasable_property.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';
import 'package:property_manager/features/leases/domain/entities/new_payment.dart';
import 'package:property_manager/features/leases/domain/entities/rent_charge.dart';
import 'package:property_manager/features/leases/domain/entities/rent_payment.dart';
import 'package:property_manager/features/leases/domain/rules/lease_ending.dart';
import 'package:property_manager/features/leases/domain/rules/lease_schedule.dart';
import 'package:property_manager/features/properties/data/datasources/properties_data_source.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';

/// In-memory backend for dev (no config) and tests. Like the other fakes it
/// does NOT emulate RLS or the SQL function; those are verified in Supabase.
/// It does mirror the main rules of `create_lease`, in the same order.
final class FakeLeasesDataSource implements LeasesDataSource {
  new({
    required this._properties,

    this._candidates = const {},
    Iterable<Lease> leases = const [],
  }) {
    for (final lease in leases) {
      _leases[lease.id] = lease;
    }
  }

  final PropertiesDataSource _properties;
  final Map<String, Set<String>> _candidates;
  final Map<String, Lease> _leases = {};
  int _nextId = 1;

  Lease _require(String id) => _leases[id] ?? (throw const NotFoundFailure());

  static List<Lease> _newest(Iterable<Lease> source, int limit) {
    final sorted = source.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<Lease>> listForTenant(
    String tenantId, {
    required int limit,
  }) async =>
      _newest(_leases.values.where((l) => l.tenantId == tenantId), limit);

  @override
  Future<List<Lease>> listForAgent(
    String agentId, {
    required int limit,
  }) async => _newest(_leases.values.where((l) => l.agentId == agentId), limit);

  @override
  Future<Lease> getById(String id) async => _require(id);

  @override
  Future<List<String>> tenantCandidateIds(String propertyId) async =>
      (_candidates[propertyId] ?? const <String>{}).toList();

  @override
  Future<List<LeasableProperty>> leasableProperties(String agentId) async {
    final owned = await _properties.listByAgent(agentId, offset: 0, limit: 200);
    final leased = {
      for (final lease in _leases.values)
        if (lease.isActive) lease.propertyId,
    };
    return [
      for (final property in owned)
        if (property.listingType == ListingType.rent &&
            (property.status == PropertyStatus.published ||
                property.status == PropertyStatus.archived) &&
            !leased.contains(property.id))
          LeasableProperty(
            id: property.id,
            title: property.title,
            city: property.city,
            monthlyRent: Money.parse(
              property.price,
              currency: property.currency,
            ),
          ),
    ];
  }

  @override
  Future<Lease> create(NewLease draft) async {
    final property = await _properties.getById(draft.propertyId);
    if (property.listingType != ListingType.rent) {
      throw const ValidationFailure({});
    }
    if (property.status != PropertyStatus.published &&
        property.status != PropertyStatus.archived) {
      throw const ValidationFailure({});
    }
    final contacted =
        _candidates[draft.propertyId]?.contains(draft.tenantId) ?? false;
    if (!contacted) throw const ForbiddenFailure();
    final hasActive = _leases.values.any(
      (l) => l.propertyId == draft.propertyId && l.isActive,
    );
    if (hasActive) throw const ConflictFailure();

    final id = 'l-${_nextId++}';
    final dates = LeaseSchedule.dueDates(
      start: draft.startDate,
      end: draft.endDate,
      dueDay: draft.dueDay,
    );
    final lease = Lease(
      id: id,
      propertyId: draft.propertyId,
      propertyTitle: property.title,
      tenantId: draft.tenantId,
      startDate: draft.startDate,
      endDate: draft.endDate,
      monthlyRent: draft.monthlyRent,
      securityDeposit: draft.securityDeposit,
      dueDay: draft.dueDay,
      status: LeaseStatus.active,
      createdAt: DateTime.now(),
      agentId: property.agentId,
      charges: [
        for (final (index, due) in dates.indexed)
          RentCharge(
            id: '$id-c$index',
            leaseId: id,
            dueDate: due,
            amount: draft.monthlyRent,
          ),
      ],
    );
    return _leases[id] = lease;
  }

  Lease _replace(String id, Lease Function(Lease) change) =>
      _leases[id] = change(_require(id));

  @override
  Future<RentPayment> recordPayment(NewPayment payment) async {
    final lease = _require(payment.leaseId);
    final charge = lease.charges
        .where((c) => c.id == payment.chargeId)
        .firstOrNull;
    if (charge == null) throw const NotFoundFailure();
    if (charge.isCancelled) throw const ConflictFailure();
    if (payment.amount > charge.balance) {
      throw const ValidationFailure({'amount': 'exceedsBalance'});
    }

    final created = RentPayment(
      id: 'pay-${_nextId++}',
      chargeId: charge.id,
      amount: payment.amount,
      paidOn: payment.paidOn,
      method: payment.method,
      reference: payment.reference.trim().isEmpty
          ? null
          : payment.reference.trim(),
      recordedBy: lease.agentId ?? '',
      createdAt: DateTime.now(),
    );
    _replace(
      lease.id,
      (l) => l.copyWith(
        charges: [
          for (final c in l.charges)
            if (c.id == charge.id)
              c.copyWith(payments: [...c.payments, created])
            else
              c,
        ],
      ),
    );
    return created;
  }

  @override
  Future<RentPayment> voidPayment(String paymentId, String reason) async {
    for (final lease in _leases.values) {
      for (final charge in lease.charges) {
        final match = charge.payments
            .where((p) => p.id == paymentId)
            .firstOrNull;
        if (match == null) continue;
        if (match.isVoid) throw const ConflictFailure();

        final voided = match.copyWith(
          voidedAt: DateTime.now(),
          voidReason: reason,
        );
        _replace(
          lease.id,
          (l) => l.copyWith(
            charges: [
              for (final c in l.charges)
                if (c.id == charge.id)
                  c.copyWith(
                    payments: [
                      for (final p in c.payments)
                        if (p.id == paymentId) voided else p,
                    ],
                  )
                else
                  c,
            ],
          ),
        );
        return voided;
      }
    }
    throw const NotFoundFailure();
  }

  @override
  Future<Lease> endLease(String leaseId, DateTime endOn) async {
    final lease = _require(leaseId);
    if (!lease.isActive) throw const ConflictFailure();

    final cancelIds = {
      for (final c in LeaseEnding.chargesToCancel(lease, endOn)) c.id,
    };
    return _replace(
      leaseId,
      (l) => l.copyWith(
        status: LeaseStatus.ended,
        endedOn: endOn,
        charges: [
          for (final c in l.charges)
            if (cancelIds.contains(c.id))
              c.copyWith(cancelledAt: DateTime.now())
            else
              c,
        ],
      ),
    );
  }
}
