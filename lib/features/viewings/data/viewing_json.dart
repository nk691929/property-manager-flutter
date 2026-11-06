import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';

/// Viewing plus the listing's current agent (resource embedding).
const viewingSelect = '*, properties(agent_id)';

/// Same, as an inner join so filters on the embedded column drop rows.
const viewingSelectInner = '*, properties!inner(agent_id)';

Viewing viewingFromJson(Map<String, dynamic> json) {
  final property = json['properties'];
  final agentId = property is Map<String, dynamic>
      ? property['agent_id'] as String?
      : null;

  return Viewing(
    id: json['id'] as String,
    propertyId: json['property_id'] as String,
    propertyTitle: json['property_title'] as String? ?? '',
    clientId: json['client_id'] as String,
    scheduledAt: DateTime.parse(json['scheduled_at'] as String),
    status: ViewingStatus.fromWire(json['status'] as String),
    declineReason: json['decline_reason'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    agentId: agentId,
  );
}
