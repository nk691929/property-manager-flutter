import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/features/properties/domain/rules/photo_rules.dart';
import 'package:property_manager/l10n/app_localizations.dart';

extension PhotoFieldErrorMessage on PhotoFieldError {
  String localized(AppLocalizations l10n) => switch (this) {
    PhotoFieldError.empty => l10n.photoErrorEmpty,
    PhotoFieldError.tooLarge => l10n.photoErrorTooLarge(
      PhotoRules.maxMegabytes,
    ),
    PhotoFieldError.unsupportedType => l10n.photoErrorUnsupported,
    PhotoFieldError.tooMany => l10n.photoErrorTooMany(
      PhotoRules.maxPerProperty,
    ),
  };
}

/// Prefers a specific photo message for validation failures.
String photoFailureMessage(Failure failure, AppLocalizations l10n) {
  if (failure is ValidationFailure) {
    final code = failure.fieldErrors['photo'];
    final error = code == null
        ? null
        : PhotoFieldError.values.asNameMap()[code];
    if (error != null) return error.localized(l10n);
  }
  return failure.localized(l10n);
}
