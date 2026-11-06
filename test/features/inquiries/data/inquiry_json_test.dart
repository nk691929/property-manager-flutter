import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/inquiries/data/inquiry_json.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_enums.dart';

void main() {
  Map<String, dynamic> row({Object? properties}) => {
    'id': 'i-1',
    'property_id': 'p-1',
    'client_id': 'u-client',
    'property_title': 'A listing',
    'status': 'open',
    'last_message_at': '2026-11-02T10:00:00Z',
    'last_message_preview': 'Hello',
    'last_sender_id': 'u-client',
    'created_at': '2026-11-02T09:00:00Z',
    'properties': ?properties,
  };

  test('reads the embedded current agent', () {
    final inquiry = inquiryFromJson(row(properties: {'agent_id': 'u-agent'}));
    expect(inquiry.agentId, 'u-agent');
    expect(inquiry.status, InquiryStatus.open);
    expect(inquiry.isOpen, isTrue);
  });

  test('a hidden property leaves the agent unknown', () {
    expect(inquiryFromJson(row()).agentId, isNull);
    expect(inquiryFromJson(row()).agentId, isNull);
  });

  test('unknown status degrades to closed', () {
    final inquiry = inquiryFromJson({...row(), 'status': 'weird'});
    expect(inquiry.status, InquiryStatus.closed);
  });

  test('messages parse', () {
    final message = messageFromJson({
      'id': 'm-1',
      'inquiry_id': 'i-1',
      'sender_id': 'u-client',
      'body': 'Hello',
      'created_at': '2026-11-02T10:00:00Z',
    });
    expect(message.body, 'Hello');
    expect(message.createdAt.isUtc, isTrue);
  });
}
