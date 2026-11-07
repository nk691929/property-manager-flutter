import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/leases/data/lease_json.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';

import '../../../helpers/lease_test_helpers.dart';

void main() {
  Map<String, dynamic> payment(
    String id, {
    String createdAt = '2027-01-02T08:00:00Z',
    Object? amount = '30000.00',
    String? voidedAt,
  }) => {
    'id': id,
    'charge_id': 'c-1',
    'amount': amount,
    'paid_on': '2027-01-02',
    'method': 'bank_transfer',
    'reference': 'TX-1',
    'recorded_by': 'u-agent',
    'voided_at': voidedAt,
    'void_reason': voidedAt == null ? null : 'Entered twice',
    'created_at': createdAt,
  };

  Map<String, dynamic> charge(
    String id,
    String due, {
    List<Map<String, dynamic>> payments = const [],
  }) => {
    'id': id,
    'lease_id': 'l-1',
    'due_date': due,
    'amount': '50000.00',
    'cancelled_at': null,
    'rent_payments': payments,
  };

  Map<String, dynamic> row({Object? properties, List<Object?>? charges}) => {
    'id': 'l-1',
    'property_id': 'p-2',
    'tenant_id': 'u-client',
    'property_title': 'Gulberg apartment',
    'start_date': '2027-01-01',
    'end_date': '2027-04-30',
    'monthly_rent': '50000.00',
    'currency': 'PKR',
    'security_deposit': 100000,
    'due_day': 1,
    'status': 'active',
    'ended_on': null,
    'created_at': '2026-11-06T09:00:00Z',
    'properties': ?properties,
    'rent_charges': ?charges,
  };

  test('reads money, dates and the embedded agent', () {
    final lease = leaseFromJson(row(properties: {'agent_id': 'u-agent'}));

    expect(lease.agentId, 'u-agent');
    expect(lease.monthlyRent, pkr(50000)); // from text
    expect(lease.securityDeposit, pkr(100000)); // from a number
    expect(lease.startDate, DateTime(2027));
    expect(lease.dueDay, 1);
    expect(lease.isActive, isTrue);
  });

  test('charges are sorted by due date and payments by time', () {
    final lease = leaseFromJson(
      row(
        charges: [
          charge('c-2', '2027-02-01'),
          charge(
            'c-1',
            '2027-01-01',
            payments: [
              payment('pay-b', createdAt: '2027-01-05T08:00:00Z'),
              payment('pay-a'),
            ],
          ),
        ],
      ),
    );

    expect(lease.charges.map((c) => c.id), ['c-1', 'c-2']);
    expect(lease.charges.first.payments.map((p) => p.id), ['pay-a', 'pay-b']);
    expect(
      lease.charges.first.payments.first.method,
      PaymentMethod.bankTransfer,
    );
    expect(lease.charges.first.payments.first.reference, 'TX-1');
  });

  test('voided payments are kept but do not count', () {
    final lease = leaseFromJson(
      row(
        charges: [
          charge(
            'c-1',
            '2027-01-01',
            payments: [
              payment('pay-a', amount: '20000.00'),
              payment(
                'pay-b',
                createdAt: '2027-01-03T08:00:00Z',
                voidedAt: '2027-01-04T08:00:00Z',
              ),
            ],
          ),
        ],
      ),
    );

    final first = lease.charges.first;
    expect(first.payments, hasLength(2));
    expect(first.payments.last.isVoid, isTrue);
    expect(first.paid, pkr(20000));
  });

  test('a hidden property leaves the agent unknown; no charges is fine', () {
    final lease = leaseFromJson(row());
    expect(lease.agentId, isNull);
    expect(lease.charges, isEmpty);
  });

  test('unknown statuses degrade safely', () {
    expect(
      leaseFromJson({...row(), 'status': 'weird'}).status,
      LeaseStatus.ended,
    );
    expect(PaymentMethod.fromWire('mystery'), PaymentMethod.other);
  });
}
