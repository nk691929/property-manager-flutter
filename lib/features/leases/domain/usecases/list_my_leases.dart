import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/paging.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';

/// Tenants see their own leases; agents those of their listings.
final class ListMyLeases {
  const new(this._repository, this._currentUser);

  final LeasesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<List<Lease>>> call({int limit = leaseListLimit}) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (actor.can(Permission.viewOwnLeases)) {
      return await _repository.listForTenant(actor.id, limit: limit);
    }
    if (actor.can(Permission.manageLeases)) {
      return await _repository.listForAgent(actor.id, limit: limit);
    }
    return const Err(ForbiddenFailure());
  }
}
