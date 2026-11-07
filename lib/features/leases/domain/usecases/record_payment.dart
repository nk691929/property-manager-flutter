import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/time/clock.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/leases/domain/entities/new_payment.dart';
import 'package:property_manager/features/leases/domain/entities/rent_payment.dart';
import 'package:property_manager/features/leases/domain/lease_access.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';
import 'package:property_manager/features/leases/domain/rules/payment_rules.dart';

/// The use case reloads the lease, so the overpay check uses the current
/// balance, not what was on screen. The database trigger still has the last
/// word (it locks the charge while it checks).
final class RecordPayment {
  new(this._repository, this._currentUser, {Now? now})
    : _now = now ?? DateTime.now;

  final LeasesRepository _repository;
  final CurrentUserReader _currentUser;
  final Now _now;

  Future<Result<RentPayment>> call(NewPayment payment) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageLeases)) {
      return const Err(ForbiddenFailure());
    }

    final loaded = await loadParticipantLease(
      _repository,
      actor,
      payment.leaseId,
    );
    final lease = loaded.valueOrNull;
    if (lease == null) {
      return Err(loaded.failureOrNull ?? const UnknownFailure());
    }

    final charge = lease.charges
        .where((c) => c.id == payment.chargeId)
        .firstOrNull;
    if (charge == null) return const Err(NotFoundFailure());
    // A cancelled charge (the lease ended) can't take money any more.
    if (charge.isCancelled) return const Err(ConflictFailure());

    final invalid = PaymentRules.validate(
      payment,
      charge: charge,
      today: _now(),
    );
    if (invalid != null) return Err(invalid);

    return await _repository.recordPayment(payment);
  }
}
