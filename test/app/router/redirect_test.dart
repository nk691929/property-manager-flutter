import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/app/router/redirect.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

void main() {
  AppUser user(Role role) => AppUser(id: 'x', email: 'x@x.com', role: role);

  String? redirect({
    required String location,
    bool isLoading = false,
    AppUser? user,
  }) => resolveRedirect(isLoading: isLoading, user: user, location: location);

  group('loading', () {
    test('goes to splash', () {
      expect(
        redirect(isLoading: true, location: AppRoutes.admin),
        AppRoutes.splash,
      );
    });
    test('stays on splash', () {
      expect(redirect(isLoading: true, location: AppRoutes.splash), isNull);
    });
  });

  group('signed out', () {
    test('protected routes go to login', () {
      for (final path in [
        AppRoutes.root,
        AppRoutes.admin,
        AppRoutes.adminUsers,
        AppRoutes.agent,
        AppRoutes.client,
      ]) {
        expect(redirect(location: path), AppRoutes.login, reason: path);
      }
    });
    test('public routes are reachable', () {
      for (final path in [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.about,
      ]) {
        expect(redirect(location: path), isNull, reason: path);
      }
    });
  });

  group('signed in', () {
    test('entry points go to the role home', () {
      expect(
        redirect(user: user(Role.admin), location: AppRoutes.login),
        AppRoutes.admin,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.root),
        AppRoutes.agent,
      );
      expect(
        redirect(user: user(Role.client), location: AppRoutes.splash),
        AppRoutes.client,
      );
    });

    test('own area is allowed', () {
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.agent),
        isNull,
      );
      expect(
        redirect(user: user(Role.admin), location: AppRoutes.adminUsers),
        isNull,
      );
    });

    test('other roles areas bounce to the own home', () {
      expect(
        redirect(user: user(Role.client), location: AppRoutes.admin),
        AppRoutes.client,
      );
      expect(
        redirect(user: user(Role.client), location: AppRoutes.adminUsers),
        AppRoutes.client,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.client),
        AppRoutes.agent,
      );
    });

    test('public info page stays reachable', () {
      expect(
        redirect(user: user(Role.client), location: AppRoutes.about),
        isNull,
      );
    });
  });
}
