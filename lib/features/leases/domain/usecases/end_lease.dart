import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/lease_access.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';
import 'package:property_manager/features/leases/domain/rules/lease_ending.dart';

final class EndLease {
  const new(this._repository, this._currentUser);

  final LeasesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Lease>> call({
    required String leaseId,
    required DateTime endOn,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageLeases)) {
      return const Err(ForbiddenFailure());
    }

    final loaded = await loadParticipantLease(_repository, actor, leaseId);
    final lease = loaded.valueOrNull;
    if (lease == null) return loaded;

    // Ending twice means the screen was stale: a conflict, not a refusal.
    if (!lease.isActive) return const Err(ConflictFailure());
    if (!LeaseEnding.isValidEndDate(lease, endOn)) {
      return const Err(ValidationFailure({'endDate': 'beforeStart'}));
    }

    return await _repository.endLease(leaseId, endOn);
  }
}
