import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/leases/domain/entities/new_payment.dart';
import 'package:property_manager/features/leases/domain/entities/rent_charge.dart';

enum PaymentFieldError {
  amountInvalid,
  exceedsBalance,
  futureDate,
  referenceTooLong,
  reasonEmpty,
  reasonTooLong,
  missing,
}

/// Mirrors the CHECKs and `guard_payment_*` triggers in
/// supabase/migrations/0005_leases_and_rent.sql. The database is the
/// authority; this copy gives instant feedback and early failure.
abstract final class PaymentRules {
  static const maxReferenceLength = 100;
  static const maxReasonLength = 300;

  /// The server runs in UTC while users may be ahead of it, so a payment
  /// dated "today" locally can be "tomorrow" there: one day of tolerance.
  static const futureToleranceDays = 1;

  static PaymentFieldError? amount(Money value, {required Money balance}) {
    if (!value.isPositive || value.minorUnits > 100000000000) {
      return PaymentFieldError.amountInvalid;
    }
    if (value > balance) return PaymentFieldError.exceedsBalance;
    return null;
  }

  static PaymentFieldError? paidOn(DateTime value, {required DateTime today}) {
    final latest = Calendar.addDays(
      Calendar.dateOnly(today),
      futureToleranceDays,
    );
    return Calendar.dateOnly(value).isAfter(latest)
        ? PaymentFieldError.futureDate
        : null;
  }

  static PaymentFieldError? reference(String? value) =>
      (value?.trim().length ?? 0) > maxReferenceLength
      ? PaymentFieldError.referenceTooLong
      : null;

  static PaymentFieldError? voidReason(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return PaymentFieldError.reasonEmpty;
    if (text.length > maxReasonLength) return PaymentFieldError.reasonTooLong;
    return null;
  }

  static ValidationFailure? validate(
    NewPayment payment, {
    required RentCharge charge,
    required DateTime today,
  }) {
    final errors = <String, PaymentFieldError>{
      if (payment.chargeId.isEmpty) 'charge': PaymentFieldError.missing,
      'amount': ?amount(payment.amount, balance: charge.balance),
      'date': ?paidOn(payment.paidOn, today: today),
      'reference': ?reference(payment.reference),
    };
    if (errors.isEmpty) return null;
    return ValidationFailure({
      for (final entry in errors.entries) entry.key: entry.value.name,
    });
  }
}
