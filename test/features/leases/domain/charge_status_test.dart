import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';

import '../../../helpers/lease_test_helpers.dart';

void main() {
  final due = DateTime(2027, 3);

  ChargeStatus statusOn(
    DateTime today, {
    List<int> payments = const [],
    bool cancelled = false,
    bool voidFirst = false,
  }) => sampleCharge(
    id: 'c-1',
    dueDate: due,
    cancelled: cancelled,
    payments: [
      for (final (i, amount) in payments.indexed)
        samplePayment(
          id: 'p-$i',
          chargeId: 'c-1',
          amount: amount,
          voided: voidFirst && i == 0,
        ),
    ],
  ).statusOn(today);

  test('unpaid is due up to and including the due day', () {
    expect(statusOn(DateTime(2027, 2)), ChargeStatus.due);
    expect(statusOn(DateTime(2027, 3)), ChargeStatus.due);
  });

  test('unpaid becomes overdue the day after, whatever the time', () {
    expect(statusOn(DateTime(2027, 3, 2)), ChargeStatus.overdue);
    expect(statusOn(DateTime(2027, 3, 1, 23, 59)), ChargeStatus.due);
  });

  test('a partial payment shows as partly paid until the due day passes', () {
    expect(
      statusOn(DateTime(2027, 2, 15), payments: [20000]),
      ChargeStatus.partlyPaid,
    );
    expect(
      statusOn(DateTime(2027, 3, 5), payments: [20000]),
      ChargeStatus.overdue,
    );
  });

  test('fully paid stays paid, even after the due date', () {
    expect(
      statusOn(DateTime(2027, 2, 15), payments: [50000]),
      ChargeStatus.paid,
    );
    expect(
      statusOn(DateTime(2027, 9), payments: [30000, 20000]),
      ChargeStatus.paid,
    );
  });

  test('a voided payment does not count', () {
    expect(
      statusOn(DateTime(2027, 2, 15), payments: [50000], voidFirst: true),
      ChargeStatus.due,
    );
  });

  test('a cancelled charge is cancelled and owes nothing', () {
    expect(
      statusOn(DateTime(2027, 9), cancelled: true),
      ChargeStatus.cancelled,
    );
    final charge = sampleCharge(id: 'c-1', dueDate: due, cancelled: true);
    expect(charge.balance.isZero, isTrue);
  });

  test('balance is what is still owed', () {
    final charge = sampleCharge(
      id: 'c-1',
      dueDate: due,
      payments: [samplePayment(id: 'p-1', chargeId: 'c-1', amount: 20000)],
    );
    expect(charge.paid, pkr(20000));
    expect(charge.balance, pkr(30000));
  });

  group('lease summaries', () {
    final lease = sampleLease(
      charges: [
        sampleCharge(
          id: 'c-1',
          dueDate: DateTime(2027),
          payments: [samplePayment(id: 'p-1', chargeId: 'c-1', amount: 50000)],
        ),
        sampleCharge(id: 'c-2', dueDate: DateTime(2027, 2)),
        sampleCharge(
          id: 'c-3',
          dueDate: DateTime(2027, 3),
          payments: [samplePayment(id: 'p-3', chargeId: 'c-3', amount: 20000)],
        ),
        sampleCharge(id: 'c-4', dueDate: DateTime(2027, 4), cancelled: true),
      ],
    );
    final today = DateTime(2027, 2, 15);

    test('totals ignore cancelled charges', () {
      expect(lease.totalPaid, pkr(70000));
      expect(lease.outstanding, pkr(80000));
    });

    test('overdue is counted and summed', () {
      expect(lease.overdueCharges(today).map((c) => c.id), ['c-2']);
      expect(lease.overdueAmount(today), pkr(50000));
    });

    test('the next payment skips overdue, paid and cancelled charges', () {
      expect(lease.nextCharge(today)?.id, 'c-3');
      expect(lease.nextCharge(DateTime(2027, 9)), isNull);
    });
  });
}
