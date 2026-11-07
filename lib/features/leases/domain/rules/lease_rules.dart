import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';

enum LeaseFieldError {
  rentInvalid,
  depositInvalid,
  endBeforeStart,
  tooLong,
  dueDayInvalid,
  missing,
  datesMissing,
}

/// Mirrors the CHECKs on `leases` in supabase/migrations/0005_leases_and_rent.sql.
abstract final class LeaseRules {
  static const maxMonths = 36;

  /// Far below the column limit; also keeps arithmetic inside an `int`.
  static const maxMinorUnits = 100000000000; // 1,000,000,000.00

  static LeaseFieldError? rent(Money value) =>
      (!value.isPositive || value.minorUnits > maxMinorUnits)
      ? LeaseFieldError.rentInvalid
      : null;

  static LeaseFieldError? deposit(Money value) =>
      (value.minorUnits < 0 || value.minorUnits > maxMinorUnits)
      ? LeaseFieldError.depositInvalid
      : null;

  static LeaseFieldError? dates(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return LeaseFieldError.endBeforeStart;
    if (end.isAfter(Calendar.addMonths(start, maxMonths))) {
      return LeaseFieldError.tooLong;
    }
    return null;
  }

  static LeaseFieldError? dueDay(int day) =>
      (day < 1 || day > 28) ? LeaseFieldError.dueDayInvalid : null;

  static Map<String, LeaseFieldError> validateDraft(NewLease lease) => {
    if (lease.propertyId.isEmpty) 'property': LeaseFieldError.missing,
    if (lease.tenantId.isEmpty) 'tenant': LeaseFieldError.missing,
    'rent': ?rent(lease.monthlyRent),
    'deposit': ?deposit(lease.securityDeposit),
    'dates': ?dates(lease.startDate, lease.endDate),
    'dueDay': ?dueDay(lease.dueDay),
  };

  static ValidationFailure? validate(NewLease lease) {
    final errors = validateDraft(lease);
    if (errors.isEmpty) return null;
    return ValidationFailure({
      for (final entry in errors.entries) entry.key: entry.value.name,
    });
  }
}
