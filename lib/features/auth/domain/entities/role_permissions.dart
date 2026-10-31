import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

/// The single source of truth for what each role may do.
/// A switch *expression* is exhaustive: adding a [Role] will not compile
/// until it is mapped here.
Set<Permission> permissionsFor(Role role) => switch (role) {
  Role.admin => const {Permission.accessAdminArea, Permission.manageUsers},
  Role.agent => const {Permission.accessAgentArea},
  Role.client => const {Permission.accessClientArea},
};
