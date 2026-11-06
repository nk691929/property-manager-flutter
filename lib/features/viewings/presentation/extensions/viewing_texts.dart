import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:property_manager/features/viewings/domain/rules/viewing_rules.dart';
import 'package:property_manager/l10n/app_localizations.dart';

extension ViewingStatusLabel on ViewingStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ViewingStatus.requested => l10n.viewingStatusRequested,
    ViewingStatus.confirmed => l10n.viewingStatusConfirmed,
    ViewingStatus.declined => l10n.viewingStatusDeclined,
    ViewingStatus.cancelled => l10n.viewingStatusCancelled,
    ViewingStatus.completed => l10n.viewingStatusCompleted,
  };
}

/// Button text for moving a viewing into [to]. `requested` is never a target.
String viewingActionLabel(ViewingStatus to, AppLocalizations l10n) =>
    switch (to) {
      ViewingStatus.confirmed => l10n.viewingActionConfirm,
      ViewingStatus.declined => l10n.viewingActionDecline,
      ViewingStatus.cancelled => l10n.viewingActionCancel,
      ViewingStatus.completed => l10n.viewingActionComplete,
      ViewingStatus.requested => l10n.viewingStatusRequested,
    };

extension ViewingFieldErrorMessage on ViewingFieldError {
  String localized(AppLocalizations l10n) => switch (this) {
    ViewingFieldError.missingTime => l10n.viewingErrorNoTime,
    ViewingFieldError.tooSoon => l10n.viewingErrorTooSoon(
      ViewingRules.minLead.inHours,
    ),
    ViewingFieldError.tooFar => l10n.viewingErrorTooFar(
      ViewingRules.maxAhead.inDays,
    ),
    ViewingFieldError.reasonEmpty => l10n.viewingErrorReasonEmpty,
    ViewingFieldError.reasonTooLong => l10n.viewingErrorReasonTooLong(
      ViewingRules.maxReasonLength,
    ),
  };
}

/// Prefers a specific message for validation failures. When
/// [duplicateIsConflict] is set, a conflict means "you already have an active
/// request for this property" (only true when requesting).
String viewingFailureMessage(
  Failure failure,
  AppLocalizations l10n, {
  bool duplicateIsConflict = false,
}) {
  if (failure is ValidationFailure) {
    final code = failure.fieldErrors['time'] ?? failure.fieldErrors['reason'];
    final error = code == null
        ? null
        : ViewingFieldError.values.asNameMap()[code];
    if (error != null) return error.localized(l10n);
  }
  if (failure is ConflictFailure && duplicateIsConflict) {
    return l10n.viewingErrorConflict;
  }
  return failure.localized(l10n);
}
