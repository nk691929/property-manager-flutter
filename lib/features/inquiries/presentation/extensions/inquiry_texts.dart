import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/features/inquiries/domain/rules/inquiry_rules.dart';
import 'package:property_manager/l10n/app_localizations.dart';

extension InquiryFieldErrorMessage on InquiryFieldError {
  String localized(AppLocalizations l10n) => switch (this) {
    InquiryFieldError.empty => l10n.inquiryErrorEmpty,
    InquiryFieldError.tooLong => l10n.inquiryErrorTooLong(
      InquiryRules.maxLength,
    ),
  };
}

/// Prefers a specific message for validation failures.
String inquiryFailureMessage(Failure failure, AppLocalizations l10n) {
  if (failure is ValidationFailure) {
    final code = failure.fieldErrors['message'];
    final error = code == null
        ? null
        : InquiryFieldError.values.asNameMap()[code];
    if (error != null) return error.localized(l10n);
  }
  return failure.localized(l10n);
}
