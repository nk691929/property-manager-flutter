import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/leases/domain/entities/leasable_property.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';

final class ListLeasableProperties {
  const new(this._repository, this._currentUser);

  final LeasesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<List<LeasableProperty>>> call() async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageLeases)) {
      return const Err(ForbiddenFailure());
    }
    return await _repository.leasableProperties(actor.id);
  }
}
