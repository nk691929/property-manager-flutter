import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';

/// Pure function: easy to unit test, no widgets or providers involved.
/// Returns the path to redirect to, or null to stay.
String? resolveRedirect({
  required bool isLoading,
  required AppUser? user,
  required String location,
}) {
  if (isLoading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  if (user == null) {
    return AppRoutes.isPublic(location) ? null : AppRoutes.login;
  }
  if (AppRoutes.isEntryPoint(location)) {
    return AppRoutes.homeFor(user.role);
  }
  final required = AppRoutes.requiredPermission(location);
  if (required != null && !user.can(required)) {
    return AppRoutes.homeFor(user.role);
  }
  return null;
}
