import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_enums.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';

/// Inquiry plus the listing's current agent (resource embedding).
const inquirySelect = '*, properties(agent_id)';

/// Same, but as an inner join so filters on the embedded column drop rows.
const inquirySelectInner = '*, properties!inner(agent_id)';

Inquiry inquiryFromJson(Map<String, dynamic> json) {
  final property = json['properties'];
  final agentId = property is Map<String, dynamic>
      ? property['agent_id'] as String?
      : null;

  return Inquiry(
    id: json['id'] as String,
    propertyId: json['property_id'] as String,
    propertyTitle: json['property_title'] as String,
    clientId: json['client_id'] as String,
    status: InquiryStatus.fromWire(json['status'] as String),
    lastMessageAt: DateTime.parse(json['last_message_at'] as String),
    lastMessagePreview: json['last_message_preview'] as String? ?? '',
    lastSenderId: json['last_sender_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    agentId: agentId,
  );
}

InquiryMessage messageFromJson(Map<String, dynamic> json) => InquiryMessage(
  id: json['id'] as String,
  inquiryId: json['inquiry_id'] as String,
  senderId: json['sender_id'] as String,
  body: json['body'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);
