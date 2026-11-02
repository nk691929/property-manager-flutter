import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const about = '/about';
  static const admin = '/admin';
  static const adminUsers = '/admin/users';
  static const agent = '/agent';
  static const client = '/client';
  static const properties = '/properties';
  static const agentListings = '/agent/listings';
  static const agentListingNew = '/agent/listings/new';
  static const adminListings = '/admin/listings';
  static const adminReview = '/admin/review';
  static const adminSettings = '/admin/settings';

  static const Set<String> _publicWhenSignedOut = {login, register, about};
  static const Set<String> _entryPoints = {root, splash, login, register};
  static String propertyDetail(String id) => '/properties/$id';
  static String agentListingEdit(String id) => '/agent/listings/$id/edit';

  static bool isPublic(String location) =>
      _publicWhenSignedOut.contains(location);

  /// Places a signed-in user should never "stay" on.
  static bool isEntryPoint(String location) => _entryPoints.contains(location);

  /// Exhaustive: a new Role will not compile until it has a home.
  static String homeFor(Role role) => switch (role) {
    Role.admin => admin,
    Role.agent => agent,
    Role.client => client,
  };

  /// Most specific rule first.
  static Permission? requiredPermission(String location) {
    if (location == adminUsers) return Permission.manageUsers;
    if (location == adminSettings) return Permission.manageSettings;
    if (_isUnder(location, admin)) return Permission.accessAdminArea;
    if (_isUnder(location, agent)) return Permission.accessAgentArea;
    if (_isUnder(location, client)) return Permission.accessClientArea;
    if (_isUnder(location, properties)) return Permission.browseProperties;
    return null;
  }

  static bool _isUnder(String location, String base) =>
      location == base || location.startsWith('$base/');
}
