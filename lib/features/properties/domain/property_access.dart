import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';

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
