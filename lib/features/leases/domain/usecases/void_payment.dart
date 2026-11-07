import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/leases/domain/entities/rent_payment.dart';
import 'package:property_manager/features/leases/domain/lease_access.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';
import 'package:property_manager/features/leases/domain/rules/payment_rules.dart';

/// A payment is never deleted: voiding keeps it, with a reason.
final class VoidPayment {
  const new(this._repository, this._currentUser);

  final LeasesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<RentPayment>> call({
    required String leaseId,
    required String paymentId,
    required String reason,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageLeases)) {
      return const Err(ForbiddenFailure());
    }

    final invalid = PaymentRules.voidReason(reason);
    if (invalid != null) {
      return Err(ValidationFailure({'reason': invalid.name}));
    }

    final loaded = await loadParticipantLease(_repository, actor, leaseId);
    final lease = loaded.valueOrNull;
    if (lease == null) {
      return Err(loaded.failureOrNull ?? const UnknownFailure());
    }

    final payment = [for (final charge in lease.charges) ...charge.payments]
        .where((p) => p.id == paymentId)
        .firstOrNull;
    if (payment == null) return const Err(NotFoundFailure());
    // Voiding twice means the screen was stale: a conflict, not a refusal.
    if (payment.isVoid) return const Err(ConflictFailure());

    return await _repository.voidPayment(paymentId, reason.trim());
  }
}
