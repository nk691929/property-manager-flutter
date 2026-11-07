import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/features/leases/domain/rules/payment_rules.dart';

import '../../../helpers/lease_test_helpers.dart';

void main() {
  final today = DateTime(2027, 1, 10);
  final charge = sampleCharge(id: 'c-1', dueDate: DateTime(2027));

  test('amount must be positive and not more than what is still due', () {
    expect(
      PaymentRules.amount(const Money.zero(), balance: pkr(50000)),
      PaymentFieldError.amountInvalid,
    );
    expect(
      PaymentRules.amount(pkr(50001), balance: pkr(50000)),
      PaymentFieldError.exceedsBalance,
    );
    expect(PaymentRules.amount(pkr(50000), balance: pkr(50000)), isNull);
    expect(PaymentRules.amount(pkr(1), balance: pkr(50000)), isNull);
  });

  test('the date may be today or tomorrow (server in UTC), no later', () {
    expect(PaymentRules.paidOn(DateTime(2027, 1, 10), today: today), isNull);
    expect(PaymentRules.paidOn(DateTime(2027, 1, 11), today: today), isNull);
    expect(
      PaymentRules.paidOn(DateTime(2027, 1, 12), today: today),
      PaymentFieldError.futureDate,
    );
    expect(PaymentRules.paidOn(DateTime(2026, 6), today: today), isNull);
  });

  test('reference and void reason limits', () {
    expect(PaymentRules.reference(null), isNull);
    expect(PaymentRules.reference('a' * 100), isNull);
    expect(
      PaymentRules.reference('a' * 101),
      PaymentFieldError.referenceTooLong,
    );

    expect(PaymentRules.voidReason(null), PaymentFieldError.reasonEmpty);
    expect(PaymentRules.voidReason('  '), PaymentFieldError.reasonEmpty);
    expect(PaymentRules.voidReason('Entered twice'), isNull);
    expect(PaymentRules.voidReason('a' * 301), PaymentFieldError.reasonTooLong);
  });

  test('a valid payment passes; every problem is reported by field', () {
    expect(
      PaymentRules.validate(
        sampleNewPayment(chargeId: 'c-1'),
        charge: charge,
        today: today,
      ),
      isNull,
    );

    final failure = PaymentRules.validate(
      sampleNewPayment(
        chargeId: '',
        amount: 99999,
        paidOn: DateTime(2027, 3),
        reference: 'a' * 101,
      ),
      charge: charge,
      today: today,
    );
    expect(failure, isA<ValidationFailure>());
    expect(
      failure?.fieldErrors.keys,
      containsAll(['charge', 'amount', 'date', 'reference']),
    );
  });

  test('the balance accounts for earlier payments and ignores voided ones', () {
    final partlyPaid = sampleCharge(
      id: 'c-1',
      dueDate: DateTime(2027),
      payments: [
        samplePayment(id: 'p-1', chargeId: 'c-1', amount: 30000),
        samplePayment(id: 'p-2', chargeId: 'c-1', amount: 20000, voided: true),
      ],
    );
    expect(partlyPaid.balance, pkr(20000));
    expect(
      PaymentRules.amount(pkr(20000), balance: partlyPaid.balance),
      isNull,
    );
    expect(
      PaymentRules.amount(pkr(20001), balance: partlyPaid.balance),
      PaymentFieldError.exceedsBalance,
    );
  });
}
