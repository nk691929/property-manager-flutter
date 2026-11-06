import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/viewings/data/viewing_json.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';

void main() {
  Map<String, dynamic> row({Object? properties}) => {
    'id': 'v-1',
    'property_id': 'p-1',
    'client_id': 'u-client',
    'property_title': 'A listing',
    'scheduled_at': '2026-11-05T10:00:00+00:00',
    'status': 'requested',
    'decline_reason': null,
    'created_at': '2026-11-03T09:00:00Z',
    'updated_at': '2026-11-03T09:00:00Z',
    'properties': ?properties,
  };

  test('reads the embedded current agent and UTC times', () {
    final viewing = viewingFromJson(row(properties: {'agent_id': 'u-agent'}));

    expect(viewing.agentId, 'u-agent');
    expect(viewing.status, ViewingStatus.requested);
    expect(viewing.isActive, isTrue);
    expect(viewing.scheduledAt.isUtc, isTrue);
    expect(viewing.scheduledAt, DateTime.utc(2026, 11, 5, 10));
  });

  test('a hidden property leaves the agent unknown', () {
    expect(viewingFromJson(row()).agentId, isNull);
  });

  test('unknown status degrades to cancelled', () {
    final viewing = viewingFromJson({...row(), 'status': 'weird'});
    expect(viewing.status, ViewingStatus.cancelled);
    expect(viewing.isActive, isFalse);
  });

  test('a decline reason is kept', () {
    final viewing = viewingFromJson({
      ...row(),
      'status': 'declined',
      'decline_reason': 'Already rented',
    });
    expect(viewing.declineReason, 'Already rented');
  });
}
