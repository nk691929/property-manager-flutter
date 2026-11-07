import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/leases/domain/rules/lease_rules.dart';

import '../../../helpers/lease_test_helpers.dart';

void main() {
  test('a normal lease is valid', () {
    expect(LeaseRules.validate(sampleNewLease()), isNull);
  });

  test('rent must be positive, deposit may be zero', () {
    expect(LeaseRules.rent(const Money.zero()), LeaseFieldError.rentInvalid);
    expect(LeaseRules.rent(pkr(1)), isNull);
    expect(LeaseRules.deposit(const Money.zero()), isNull);
    expect(LeaseRules.deposit(const Money(-1)), LeaseFieldError.depositInvalid);
    expect(
      LeaseRules.rent(const Money(LeaseRules.maxMinorUnits + 1)),
      LeaseFieldError.rentInvalid,
    );
  });

  test('the end must be after the start and at most 36 months later', () {
    final start = DateTime(2027);
    expect(LeaseRules.dates(start, start), LeaseFieldError.endBeforeStart);
    expect(
      LeaseRules.dates(start, DateTime(2026, 12, 31)),
      LeaseFieldError.endBeforeStart,
    );
    expect(LeaseRules.dates(start, DateTime(2027, 1, 2)), isNull);
    expect(LeaseRules.dates(start, Calendar.addMonths(start, 36)), isNull);
    expect(
      LeaseRules.dates(
        start,
        Calendar.addDays(Calendar.addMonths(start, 36), 1),
      ),
      LeaseFieldError.tooLong,
    );
  });

  test('due day is 1 to 28', () {
    expect(LeaseRules.dueDay(0), LeaseFieldError.dueDayInvalid);
    expect(LeaseRules.dueDay(1), isNull);
    expect(LeaseRules.dueDay(28), isNull);
    expect(LeaseRules.dueDay(29), LeaseFieldError.dueDayInvalid);
  });

  test('every problem is reported, keyed by field', () {
    final failure = LeaseRules.validate(
      sampleNewLease(
        propertyId: '',
        tenantId: '',
        rent: const Money.zero(),
        end: DateTime(2026, 12),
        dueDay: 31,
      ),
    );
    expect(failure, isA<ValidationFailure>());
    expect(
      failure?.fieldErrors.keys,
      containsAll(['property', 'tenant', 'rent', 'dates', 'dueDay']),
    );
  });
}
