import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/l10n/app_localizations.dart';

extension FailureMessage on Failure {
  /// Exhaustive on purpose: adding a new Failure subtype will not compile
  /// until its message is added here.
  String localized(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.errorNetwork,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    ForbiddenFailure() => l10n.errorForbidden,
    NotFoundFailure() => l10n.errorNotFound,
    ValidationFailure() => l10n.errorValidation,
    CacheFailure() => l10n.errorCache,
    UnknownFailure() => l10n.errorUnknown,
  };
}
