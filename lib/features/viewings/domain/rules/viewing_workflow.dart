import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';

/// The viewing state machine. MUST mirror `guard_viewing_write` in
/// supabase/migrations/0004_engagement.sql. The database is the authority;
/// this copy gives instant UX and early failure.
abstract final class ViewingWorkflow {
  static bool canTransition({
    required ViewingStatus from,
    required ViewingStatus to,
    required bool isClient,
    required bool isAgent,
    required DateTime scheduledAt,
    required DateTime now,
  }) => switch ((from, to)) {
    (ViewingStatus.requested, ViewingStatus.confirmed) =>
      isAgent && scheduledAt.isAfter(now),
    (ViewingStatus.requested, ViewingStatus.declined) => isAgent,
    (ViewingStatus.requested, ViewingStatus.cancelled) => isClient,
    (ViewingStatus.confirmed, ViewingStatus.cancelled) => isClient || isAgent,
    (ViewingStatus.confirmed, ViewingStatus.completed) =>
      isAgent && !scheduledAt.isAfter(now),
    _ => false,
  };

  /// Moves to offer as buttons, in a stable order.
  static List<ViewingStatus> nextStatuses({
    required ViewingStatus from,
    required bool isClient,
    required bool isAgent,
    required DateTime scheduledAt,
    required DateTime now,
  }) => [
    for (final to in ViewingStatus.values)
      if (canTransition(
        from: from,
        to: to,
        isClient: isClient,
        isAgent: isAgent,
        scheduledAt: scheduledAt,
        now: now,
      ))
        to,
  ];
}
