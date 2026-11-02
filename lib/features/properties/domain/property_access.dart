import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';
import 'package:property_manager/features/properties/domain/rules/property_workflow.dart';

/// Loads a property and checks [actor] may manage it: admins manage any,
/// agents only their own. Shared by every mutating use case.
Future<Result<Property>> loadManageable(
  PropertiesRepository repository,
  AppUser actor,
  String propertyId,
) async {
  final isAdmin = actor.can(Permission.manageAllProperties);
  if (!isAdmin && !actor.can(Permission.manageOwnProperties)) {
    return const Err(ForbiddenFailure());
  }
  final loaded = await repository.getById(propertyId);
  return loaded.fold<Result<Property>>(
    onOk: (property) => (isAdmin || property.agentId == actor.id)
        ? Ok(property)
        : const Err(ForbiddenFailure()),
    onErr: Err.new,
  );
}

/// Like [loadManageable], and also checks the listing may still change.
/// Owners can touch photos only while a listing is a draft or rejected;
/// admins any time (mirrors `can_manage_property_photos` in the database).
Future<Result<Property>> loadPhotoEditable(
  PropertiesRepository repository,
  AppUser actor,
  String propertyId,
) async {
  final loaded = await loadManageable(repository, actor, propertyId);
  final property = loaded.valueOrNull;
  if (property == null) return loaded;
  final isAdmin = actor.can(Permission.manageAllProperties);
  if (!isAdmin && !PropertyWorkflow.isEditableByOwner(property.status)) {
    return const Err(ForbiddenFailure());
  }
  return loaded;
}
