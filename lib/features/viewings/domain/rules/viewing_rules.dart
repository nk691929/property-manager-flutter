enum ViewingFieldError {
  missingTime,
  tooSoon,
  tooFar,
  reasonEmpty,
  reasonTooLong,
}

/// Mirrors `guard_viewing_write` and the `decline_reason` CHECK in
/// supabase/migrations/0004_engagement.sql.
abstract final class ViewingRules {
  static const minLead = Duration(hours: 1);
  static const maxAhead = Duration(days: 90);
  static const maxReasonLength = 300;

  static ViewingFieldError? validateTime(
    DateTime scheduledAt, {
    required DateTime now,
  }) {
    if (scheduledAt.isBefore(now.add(minLead))) {
      return ViewingFieldError.tooSoon;
    }
    if (scheduledAt.isAfter(now.add(maxAhead))) return ViewingFieldError.tooFar;
    return null;
  }

  static ViewingFieldError? validateReason(String? reason) {
    final text = reason?.trim() ?? '';
    if (text.isEmpty) return ViewingFieldError.reasonEmpty;
    if (text.length > maxReasonLength) return ViewingFieldError.reasonTooLong;
    return null;
  }
}
