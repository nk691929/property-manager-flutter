import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';

final class ReassignProperty {
  const new(this._repository, this._currentUser);

  final PropertiesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Property>> call({
    required String propertyId,
    required String agentId,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageAllProperties)) {
      return const Err(ForbiddenFailure());
    }
    return await _repository.reassign(propertyId, agentId);
  }
}
