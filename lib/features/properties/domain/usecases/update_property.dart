import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/property_access.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';
import 'package:property_manager/features/properties/domain/rules/property_validators.dart';
import 'package:property_manager/features/properties/domain/rules/property_workflow.dart';

final class UpdateProperty {
  const new(this._repository, this._currentUser);

  final PropertiesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Property>> call(String propertyId, PropertyDraft draft) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());

    final loaded = await loadManageable(_repository, actor, propertyId);
    final property = loaded.valueOrNull;
    if (property == null) {
      return Err(loaded.failureOrNull ?? const UnknownFailure());
    }

    // Owners may only edit drafts and rejected listings (unpublish first).
    final isAdmin = actor.can(Permission.manageAllProperties);
    if (!isAdmin && !PropertyWorkflow.isEditableByOwner(property.status)) {
      return const Err(ForbiddenFailure());
    }

    final invalid = PropertyValidators.validate(draft);
    if (invalid != null) return Err(invalid);
    return await _repository.update(propertyId, draft);
  }
}
