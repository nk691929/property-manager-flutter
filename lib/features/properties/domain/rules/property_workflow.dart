import 'package:property_manager/features/properties/domain/entities/property_enums.dart';

/// The listing state machine. MUST mirror `agent_can_transition` and
/// `guard_property_write` in supabase/migrations/0002_properties.sql.
/// The database is the authority; this copy gives instant UX and early failure.
abstract final class PropertyWorkflow {
  static bool isEditableByOwner(PropertyStatus status) =>
      status == PropertyStatus.draft || status == PropertyStatus.rejected;

  static bool canTransition({
    required PropertyStatus from,
    required PropertyStatus to,
    required bool asAdmin,
    required bool approvalRequired,
  }) {
    if (from == to) return false;
    if (asAdmin) return true;
    return switch ((from, to)) {
      (
        PropertyStatus.draft || PropertyStatus.rejected,
        PropertyStatus.pendingReview,
      ) =>
        approvalRequired,
      (
        PropertyStatus.draft || PropertyStatus.rejected,
        PropertyStatus.published,
      ) =>
        !approvalRequired,
      (PropertyStatus.pendingReview, PropertyStatus.draft) => true,
      (
        PropertyStatus.published,
        PropertyStatus.draft || PropertyStatus.archived,
      ) =>
        true,
      (
        PropertyStatus.draft || PropertyStatus.rejected,
        PropertyStatus.archived,
      ) =>
        true,
      (PropertyStatus.archived, PropertyStatus.draft) => true,
      _ => false,
    };
  }

  /// Admins can technically do anything; the UI only offers sensible moves.
  static const _adminTargets = <PropertyStatus, List<PropertyStatus>>{
    PropertyStatus.draft: [PropertyStatus.published, PropertyStatus.archived],
    PropertyStatus.pendingReview: [
      PropertyStatus.published,
      PropertyStatus.rejected,
    ],
    PropertyStatus.published: [PropertyStatus.archived],
    PropertyStatus.rejected: [
      PropertyStatus.published,
      PropertyStatus.archived,
    ],
    PropertyStatus.archived: [PropertyStatus.draft],
  };

  /// Moves to offer as buttons for a listing in [from].
  static List<PropertyStatus> nextStatuses({
    required PropertyStatus from,
    required bool asAdmin,
    required bool approvalRequired,
  }) {
    final candidates = asAdmin
        ? (_adminTargets[from] ?? const [])
        : PropertyStatus.values;
    return [
      for (final to in candidates)
        if (canTransition(
          from: from,
          to: to,
          asAdmin: asAdmin,
          approvalRequired: approvalRequired,
        ))
          to,
    ];
  }
}
