import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/leases/data/datasources/fake_leases_data_source.dart';
import 'package:property_manager/features/leases/data/repositories/leases_repository_impl.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/entities/rent_charge.dart';
import 'package:property_manager/features/leases/domain/usecases/create_lease.dart';
import 'package:property_manager/features/leases/domain/usecases/end_lease.dart';
import 'package:property_manager/features/leases/domain/usecases/get_lease.dart';
import 'package:property_manager/features/leases/domain/usecases/record_payment.dart';
import 'package:property_manager/features/leases/domain/usecases/void_payment.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';

import '../../../helpers/lease_test_helpers.dart';
import '../../../helpers/property_test_helpers.dart';

void main() {
  late LeasesRepositoryImpl repo;
  late Lease lease;
  final today = DateTime(2027, 1, 10);

  RecordPayment recordAs(AppUser? user) =>
      RecordPayment(repo, () => user, now: () => today);

  setUp(() async {
    repo = LeasesRepositoryImpl(
      FakeLeasesDataSource(
        properties: FakePropertiesDataSource.seeded(),
        candidates: const {
          'p-2': {'u-client'},
        },
      ),
    );
    lease = (await CreateLease(repo, () => agentUser)(sampleNewLease()))
        .valueOrNull!;
  });

  RentCharge charge(int index) => lease.charges[index];

  Future<Lease> reload(AppUser user) async =>
      (await GetLease(repo, () => user)(lease.id)).valueOrNull!;

  String? field(Object? failure, String key) =>
      failure is ValidationFailure ? failure.fieldErrors[key] : null;

  group('RecordPayment', () {
    test(
      'the agent records a partial payment; the charge shows partly paid',
      () async {
        final result = await recordAs(agentUser)(
          sampleNewPayment(
            leaseId: lease.id,
            chargeId: charge(0).id,
            amount: 30000,
          ),
        );
        expect(result.isOk, isTrue);

        final updated = await reload(agentUser);
        expect(updated.charges.first.paid, pkr(30000));
        expect(updated.charges.first.balance, pkr(20000));
        expect(
          updated.charges.first.statusOn(DateTime(2027)),
          ChargeStatus.partlyPaid,
        );
      },
    );

    test('paying the full amount makes the charge paid', () async {
      await recordAs(agentUser)(
        sampleNewPayment(leaseId: lease.id, chargeId: charge(0).id),
      );
      final updated = await reload(agentUser);
      expect(
        updated.charges.first.statusOn(DateTime(2027, 6)),
        ChargeStatus.paid,
      );
    });

    test('overpaying is refused, using the CURRENT balance', () async {
      await recordAs(agentUser)(
        sampleNewPayment(
          leaseId: lease.id,
          chargeId: charge(0).id,
          amount: 30000,
        ),
      );
      final second = await recordAs(agentUser)(
        sampleNewPayment(
          leaseId: lease.id,
          chargeId: charge(0).id,
          amount: 30000,
        ),
      );
      expect(field(second.failureOrNull, 'amount'), 'exceedsBalance');
    });

    test('the tenant can read the lease but not record payments', () async {
      final result = await recordAs(clientUser)(
        sampleNewPayment(leaseId: lease.id, chargeId: charge(0).id),
      );
      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });

    test('an outsider and a signed-out user are refused', () async {
      final outsider = await recordAs(otherAgent)(
        sampleNewPayment(leaseId: lease.id, chargeId: charge(0).id),
      );
      final signedOut = await recordAs(null)(
        sampleNewPayment(leaseId: lease.id, chargeId: charge(0).id),
      );
      expect(outsider.failureOrNull, isA<ForbiddenFailure>());
      expect(signedOut.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('a future date and invalid input are refused before saving', () async {
      final future = await recordAs(agentUser)(
        sampleNewPayment(
          leaseId: lease.id,
          chargeId: charge(0).id,
          paidOn: DateTime(2027, 3),
        ),
      );
      expect(field(future.failureOrNull, 'date'), 'futureDate');

      final zero = await recordAs(agentUser)(
        sampleNewPayment(leaseId: lease.id, chargeId: charge(0).id, amount: 0),
      );
      expect(field(zero.failureOrNull, 'amount'), 'amountInvalid');

      expect((await reload(agentUser)).totalPaid.isZero, isTrue);
    });

    test('an unknown charge is not found', () async {
      final result = await recordAs(agentUser)(
        sampleNewPayment(leaseId: lease.id, chargeId: 'nope'),
      );
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('VoidPayment', () {
    Future<String> pay() async {
      final result = await recordAs(agentUser)(
        sampleNewPayment(
          leaseId: lease.id,
          chargeId: charge(0).id,
          amount: 30000,
        ),
      );
      return result.valueOrNull!.id;
    }

    test('a voided payment stays in the history but stops counting', () async {
      final paymentId = await pay();
      final result = await VoidPayment(repo, () => agentUser)(
        leaseId: lease.id,
        paymentId: paymentId,
        reason: ' Entered twice ',
      );
      expect(result.valueOrNull?.isVoid, isTrue);
      expect(result.valueOrNull?.voidReason, 'Entered twice');

      final updated = await reload(agentUser);
      expect(updated.charges.first.payments, hasLength(1));
      expect(updated.charges.first.paid.isZero, isTrue);
      expect(updated.charges.first.balance, pkr(50000));
    });

    test('a reason is required', () async {
      final paymentId = await pay();
      final result = await VoidPayment(repo, () => agentUser)(
        leaseId: lease.id,
        paymentId: paymentId,
        reason: '   ',
      );
      expect(field(result.failureOrNull, 'reason'), 'reasonEmpty');
      expect((await reload(agentUser)).totalPaid, pkr(30000));
    });

    test('voiding twice is a conflict (stale screen)', () async {
      final paymentId = await pay();
      final void_ = VoidPayment(repo, () => agentUser);
      await void_(leaseId: lease.id, paymentId: paymentId, reason: 'Mistake');
      final again = await void_(
        leaseId: lease.id,
        paymentId: paymentId,
        reason: 'Mistake',
      );
      expect(again.failureOrNull, isA<ConflictFailure>());
    });

    test('the tenant cannot void', () async {
      final paymentId = await pay();
      final result = await VoidPayment(repo, () => clientUser)(
        leaseId: lease.id,
        paymentId: paymentId,
        reason: 'Mistake',
      );
      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });

    test('voiding frees up room to record the money again', () async {
      final paymentId = await pay();
      await VoidPayment(repo, () => agentUser)(
        leaseId: lease.id,
        paymentId: paymentId,
        reason: 'Wrong charge',
      );
      final again = await recordAs(agentUser)(
        sampleNewPayment(leaseId: lease.id, chargeId: charge(0).id),
      );
      expect(again.isOk, isTrue);
    });

    test('an unknown payment is not found', () async {
      final result = await VoidPayment(repo, () => agentUser)(
        leaseId: lease.id,
        paymentId: 'nope',
        reason: 'Mistake',
      );
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('EndLease', () {
    test('ends the lease and cancels unpaid future charges only', () async {
      await recordAs(agentUser)(
        sampleNewPayment(
          leaseId: lease.id,
          chargeId: charge(10).id,
          amount: 10000,
        ),
      ); // November has a payment

      final result = await EndLease(repo, () => agentUser)(
        leaseId: lease.id,
        endOn: DateTime(2027, 3, 15),
      );
      final ended = result.valueOrNull!;

      expect(ended.status, LeaseStatus.ended);
      expect(ended.endedOn, DateTime(2027, 3, 15));
      expect(ended.charges.where((c) => c.isCancelled), hasLength(7));
      expect(ended.charges[10].isCancelled, isFalse); // kept: has a payment
      expect(ended.charges[2].isCancelled, isFalse); // due before the end
    });

    test('ending twice is a conflict (stale screen)', () async {
      final end = EndLease(repo, () => agentUser);
      await end(leaseId: lease.id, endOn: DateTime(2027, 3, 15));
      final again = await end(leaseId: lease.id, endOn: DateTime(2027, 3, 15));
      expect(again.failureOrNull, isA<ConflictFailure>());
    });

    test('a cancelled charge can no longer take payments', () async {
      await EndLease(repo, () => agentUser)(
        leaseId: lease.id,
        endOn: DateTime(2027, 3, 15),
      );
      final result = await recordAs(agentUser)(
        sampleNewPayment(leaseId: lease.id, chargeId: charge(5).id),
      );
      expect(result.failureOrNull, isA<ConflictFailure>());
    });

    test('an end date before the start is refused', () async {
      final result = await EndLease(repo, () => agentUser)(
        leaseId: lease.id,
        endOn: DateTime(2026, 12),
      );
      expect(field(result.failureOrNull, 'endDate'), 'beforeStart');
    });

    test('only the listing agent may end it', () async {
      for (final other in [clientUser, otherAgent, adminUser]) {
        final result = await EndLease(repo, () => other)(
          leaseId: lease.id,
          endOn: DateTime(2027, 3, 15),
        );
        expect(result.failureOrNull, isA<ForbiddenFailure>(), reason: other.id);
      }
    });

    test('ending frees the listing for a new lease', () async {
      final again = await CreateLease(repo, () => agentUser)(sampleNewLease());
      expect(again.failureOrNull, isA<ConflictFailure>());

      await EndLease(repo, () => agentUser)(
        leaseId: lease.id,
        endOn: DateTime(2027, 3, 15),
      );
      final afterEnd = await CreateLease(repo, () => agentUser)(
        sampleNewLease(start: DateTime(2028), end: DateTime(2028, 12, 31)),
      );
      expect(afterEnd.isOk, isTrue);
    });
  });
}
