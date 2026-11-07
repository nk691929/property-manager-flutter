import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/rent_charge.dart';

/// What ending a lease will cancel. MUST mirror the cancel rule in
/// `end_lease` (supabase/migrations/0005_leases_and_rent.sql): charges due
/// AFTER the end date, not already cancelled, with no payment that still
/// counts. Charges with a payment stay, so the history stays truthful.
abstract final class LeaseEnding {
  static Iterable<RentCharge> chargesToCancel(Lease lease, DateTime endOn) {
    final day = Calendar.dateOnly(endOn);
    return lease.charges.where(
      (c) =>
          c.dueDate.isAfter(day) &&
          !c.isCancelled &&
          c.payments.every((p) => p.isVoid),
    );
  }

  /// The end date must not be before the lease started.
  static bool isValidEndDate(Lease lease, DateTime endOn) =>
      !Calendar.dateOnly(endOn).isBefore(lease.startDate);
}
