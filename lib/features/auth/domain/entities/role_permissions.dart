import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

Set<Permission> permissionsFor(Role role) => switch (role) {
  Role.admin => const {
    Permission.accessAdminArea,
    Permission.manageUsers,
    Permission.browseProperties,
    Permission.manageAllProperties,
    Permission.manageSettings,
  },
  Role.agent => const {
    Permission.accessAgentArea,
    Permission.browseProperties,
    Permission.manageOwnProperties,
  },
  Role.client => const {
    Permission.accessClientArea,
    Permission.browseProperties,
  },
};
