import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/auth/domain/validators/auth_validators.dart';
import 'package:property_manager/l10n/app_localizations.dart';

extension RoleLabel on Role {
  String label(AppLocalizations l10n) => switch (this) {
    Role.admin => l10n.roleAdmin,
    Role.agent => l10n.roleAgent,
    Role.client => l10n.roleClient,
  };
}

extension FieldErrorMessage on FieldError {
  String localized(AppLocalizations l10n) => switch (this) {
    FieldError.empty => l10n.fieldEmpty,
    FieldError.invalidEmail => l10n.fieldInvalidEmail,
    FieldError.passwordTooShort => l10n.fieldPasswordTooShort(
      AuthValidators.minPasswordLength,
    ),
    FieldError.passwordsMismatch => l10n.fieldPasswordsMismatch,
    FieldError.emailTaken => l10n.fieldEmailTaken,
    FieldError.weakPassword => l10n.fieldWeakPassword,
  };
}

/// Prefers a specific field message for validation failures.
String authFailureMessage(Failure failure, AppLocalizations l10n) {
  if (failure is ValidationFailure) {
    final code = failure.fieldErrors.values.firstOrNull;
    final fieldError = code == null
        ? null
        : FieldError.values.asNameMap()[code];
    if (fieldError != null) return fieldError.localized(l10n);
  }
  return failure.localized(l10n);
}
