import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';
import 'package:property_manager/features/leases/domain/rules/lease_rules.dart';

/// Permission and input rules are checked here; "your own listing" and "this
/// client contacted you" are enforced by the database function `create_lease`.
final class CreateLease {
  const new(this._repository, this._currentUser);

  final LeasesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Lease>> call(NewLease draft) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageLeases)) {
      return const Err(ForbiddenFailure());
    }
    final invalid = LeaseRules.validate(draft);
    if (invalid != null) return Err(invalid);
    return await _repository.create(draft);
  }
}
