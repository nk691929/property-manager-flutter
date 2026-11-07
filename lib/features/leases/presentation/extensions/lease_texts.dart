import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/rules/lease_rules.dart';
import 'package:property_manager/features/leases/domain/rules/payment_rules.dart';
import 'package:property_manager/l10n/app_localizations.dart';

extension PaymentFieldErrorMessage on PaymentFieldError {
  String localized(AppLocalizations l10n) => switch (this) {
    PaymentFieldError.amountInvalid => l10n.paymentErrorAmount,
    PaymentFieldError.exceedsBalance => l10n.paymentErrorExceeds,
    PaymentFieldError.futureDate => l10n.paymentErrorFuture,
    PaymentFieldError.referenceTooLong => l10n.paymentErrorReferenceLong(
      PaymentRules.maxReferenceLength,
    ),
    PaymentFieldError.reasonEmpty => l10n.paymentErrorReasonEmpty,
    PaymentFieldError.reasonTooLong => l10n.paymentErrorReasonLong(
      PaymentRules.maxReasonLength,
    ),
    PaymentFieldError.missing => l10n.leaseErrorMissing,
  };
}

/// Prefers a specific message for validation failures. A conflict means the
/// screen was stale (someone changed the lease first).
String paymentFailureMessage(Failure failure, AppLocalizations l10n) {
  if (failure is ValidationFailure) {
    for (final code in failure.fieldErrors.values) {
      final error = PaymentFieldError.values.asNameMap()[code];
      if (error != null) return error.localized(l10n);
      if (code == 'beforeStart') return l10n.leaseEndErrorBeforeStart;
    }
  }
  if (failure is ConflictFailure) return l10n.leaseErrorStale;
  return failure.localized(l10n);
}

extension ChargeStatusLabel on ChargeStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ChargeStatus.due => l10n.chargeStatusDue,
    ChargeStatus.partlyPaid => l10n.chargeStatusPartlyPaid,
    ChargeStatus.paid => l10n.chargeStatusPaid,
    ChargeStatus.overdue => l10n.chargeStatusOverdue,
    ChargeStatus.cancelled => l10n.chargeStatusCancelled,
  };
}

extension LeaseStatusLabel on LeaseStatus {
  String label(AppLocalizations l10n) => switch (this) {
    LeaseStatus.active => l10n.leaseStatusActive,
    LeaseStatus.ended => l10n.leaseStatusEnded,
  };
}

extension PaymentMethodLabel on PaymentMethod {
  String label(AppLocalizations l10n) => switch (this) {
    PaymentMethod.cash => l10n.paymentMethodCash,
    PaymentMethod.bankTransfer => l10n.paymentMethodBankTransfer,
    PaymentMethod.cheque => l10n.paymentMethodCheque,
    PaymentMethod.other => l10n.paymentMethodOther,
  };
}

extension LeaseFieldErrorMessage on LeaseFieldError {
  String localized(AppLocalizations l10n) => switch (this) {
    LeaseFieldError.rentInvalid => l10n.leaseErrorRent,
    LeaseFieldError.depositInvalid => l10n.leaseErrorDeposit,
    LeaseFieldError.endBeforeStart => l10n.leaseErrorDates,
    LeaseFieldError.tooLong => l10n.leaseErrorTooLong(LeaseRules.maxMonths),
    LeaseFieldError.dueDayInvalid => l10n.leaseErrorDueDay,
    LeaseFieldError.missing => l10n.leaseErrorMissing,
    LeaseFieldError.datesMissing => l10n.leaseErrorNoDates,
  };
}

/// Prefers a specific message. With [forCreate], a conflict means "this
/// listing already has an active lease" and a refusal means "not your listing,
/// or that client never contacted you".
String leaseFailureMessage(
  Failure failure,
  AppLocalizations l10n, {
  bool forCreate = false,
}) {
  if (failure is ValidationFailure) {
    for (final code in failure.fieldErrors.values) {
      final error = LeaseFieldError.values.asNameMap()[code];
      if (error != null) return error.localized(l10n);
    }
  }
  if (forCreate && failure is ConflictFailure) return l10n.leaseErrorConflict;
  if (forCreate && failure is ForbiddenFailure) return l10n.leaseErrorForbidden;
  return failure.localized(l10n);
}
