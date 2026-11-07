import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/lease_access.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';

final class GetLease {
  const new(this._repository, this._currentUser);

  final LeasesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Lease>> call(String leaseId) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    return await loadParticipantLease(_repository, actor, leaseId);
  }
}
