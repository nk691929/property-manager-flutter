import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/entities/rent_charge.dart';

part 'lease.freezed.dart';

@freezed
abstract class Lease with _$Lease {
  const factory({
    required String id,
    required String propertyId,
    required String propertyTitle,
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required Money monthlyRent,
    required Money securityDeposit,
    required int dueDay,
    required LeaseStatus status,
    required DateTime createdAt,
    @Default(<RentCharge>[]) List<RentCharge> charges,

    /// The listing's CURRENT agent, read from the property when the lease is
    /// loaded (not stored on the lease). Null if the property is hidden.
    String? agentId,
    DateTime? endedOn,
  }) = _Lease;
  const new _();

  bool get isActive => status == LeaseStatus.active;

  String get currency => monthlyRent.currency;

  Money get totalPaid =>
      Money.sum(charges.map((c) => c.paid), currency: currency);

  /// Still owed across the schedule (cancelled charges owe nothing).
  Money get outstanding =>
      Money.sum(charges.map((c) => c.balance), currency: currency);

  Iterable<RentCharge> overdueCharges(DateTime today) =>
      charges.where((c) => c.statusOn(today) == ChargeStatus.overdue);

  Money overdueAmount(DateTime today) => Money.sum(
    overdueCharges(today).map((c) => c.balance),
    currency: currency,
  );

  /// The soonest charge that is not yet overdue and still owes money.
  RentCharge? nextCharge(DateTime today) {
    final upcoming = charges.where((c) {
      final status = c.statusOn(today);
      return status == ChargeStatus.due || status == ChargeStatus.partlyPaid;
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return upcoming.firstOrNull;
  }
}
