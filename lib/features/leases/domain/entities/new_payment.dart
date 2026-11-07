import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';

part 'new_payment.freezed.dart';

/// What an agent fills in to record rent received.
@freezed
abstract class NewPayment with _$NewPayment {
  const factory({
    required String leaseId,
    required String chargeId,
    required Money amount,
    required DateTime paidOn,
    required PaymentMethod method,

    /// A bank reference or cheque number; optional.
    @Default('') String reference,
  }) = _NewPayment;
}
