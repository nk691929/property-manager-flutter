import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';
import 'package:property_manager/features/properties/domain/rules/property_validators.dart';

final class CreateProperty {
  const new(this._repository, this._currentUser);

  final PropertiesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Property>> call(PropertyDraft draft) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageOwnProperties)) {
      return const Err(ForbiddenFailure());
    }
    final invalid = PropertyValidators.validate(draft);
    if (invalid != null) return Err(invalid);
    return await _repository.create(draft, agentId: actor.id);
  }
}
