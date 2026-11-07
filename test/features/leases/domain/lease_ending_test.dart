import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/leases/domain/rules/lease_ending.dart';

import '../../../helpers/lease_test_helpers.dart';

void main() {
  // The same shape as SQL test 9: monthly charges, November has a payment.
  final lease = sampleLease(
    charges: [
      for (var month = 1; month <= 11; month++)
        sampleCharge(
          id: 'c-$month',
          dueDate: DateTime(2027, month),
          payments: month == 11
              ? [samplePayment(id: 'p-11', chargeId: 'c-11', amount: 10000)]
              : const [],
        ),
    ],
  );

  List<String> cancelledOn(DateTime endOn) => [
    for (final c in LeaseEnding.chargesToCancel(lease, endOn)) c.id,
  ];

  test(
    'cancels unpaid charges after the end date and keeps ones with payments',
    () {
      final ids = cancelledOn(DateTime(2027, 3, 15));
      // Charges after 15 March: April..November (8). November has a payment.
      expect(ids, ['c-4', 'c-5', 'c-6', 'c-7', 'c-8', 'c-9', 'c-10']);
      expect(ids, hasLength(7)); // matches the SQL test
    },
  );

  test('a charge due on the end date itself is not cancelled', () {
    expect(cancelledOn(DateTime(2027, 3)), isNot(contains('c-3')));
    expect(cancelledOn(DateTime(2027, 3)), contains('c-4'));
  });

  test('a voided payment does not protect a charge', () {
    final voided = sampleLease(
      charges: [
        sampleCharge(
          id: 'c-1',
          dueDate: DateTime(2027, 6),
          payments: [
            samplePayment(
              id: 'p-1',
              chargeId: 'c-1',
              amount: 10000,
              voided: true,
            ),
          ],
        ),
      ],
    );
    expect(
      LeaseEnding.chargesToCancel(voided, DateTime(2027, 3)),
      hasLength(1),
    );
  });

  test('already cancelled charges are not counted again', () {
    final withCancelled = sampleLease(
      charges: [
        sampleCharge(id: 'c-1', dueDate: DateTime(2027, 6), cancelled: true),
        sampleCharge(id: 'c-2', dueDate: DateTime(2027, 7)),
      ],
    );
    expect(
      LeaseEnding.chargesToCancel(
        withCancelled,
        DateTime(2027, 3),
      ).map((c) => c.id),
      ['c-2'],
    );
  });

  test('the end date can not be before the lease started', () {
    expect(LeaseEnding.isValidEndDate(lease, DateTime(2026, 12, 31)), isFalse);
    expect(LeaseEnding.isValidEndDate(lease, DateTime(2027)), isTrue);
    expect(LeaseEnding.isValidEndDate(lease, DateTime(2027, 6)), isTrue);
  });
}
