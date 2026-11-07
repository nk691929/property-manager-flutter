import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/entities/rent_payment.dart';

part 'rent_charge.freezed.dart';

@freezed
abstract class RentCharge with _$RentCharge {
  const factory({
    required String id,
    required String leaseId,
    required DateTime dueDate,
    required Money amount,
    @Default(<RentPayment>[]) List<RentPayment> payments,
    DateTime? cancelledAt,
  }) = _RentCharge;
  const new _();

  bool get isCancelled => cancelledAt != null;

  /// Voided payments don't count.
  Money get paid => Money.sum(
    payments.where((p) => !p.isVoid).map((p) => p.amount),
    currency: amount.currency,
  );

  /// What is still owed (zero for a cancelled charge).
  Money get balance =>
      isCancelled ? Money.zero(amount.currency) : amount - paid;

  /// The charge is `overdue` from the day AFTER its due date.
  ChargeStatus statusOn(DateTime today) {
    if (isCancelled) return ChargeStatus.cancelled;
    if (paid >= amount) return ChargeStatus.paid;
    if (Calendar.dateOnly(today).isAfter(dueDate)) return ChargeStatus.overdue;
    if (paid.isPositive) return ChargeStatus.partlyPaid;
    return ChargeStatus.due;
  }
}
