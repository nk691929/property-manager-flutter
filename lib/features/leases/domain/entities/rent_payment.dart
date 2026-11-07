import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';

part 'rent_payment.freezed.dart';

@freezed
abstract class RentPayment with _$RentPayment {
  const factory({
    required String id,
    required String chargeId,
    required Money amount,
    required DateTime paidOn,
    required PaymentMethod method,
    required String recordedBy,
    required DateTime createdAt,
    String? reference,
    DateTime? voidedAt,
    String? voidReason,
  }) = _RentPayment;
  const new _();

  /// Payments are never deleted; a mistake is voided with a reason.
  bool get isVoid => voidedAt != null;
}
