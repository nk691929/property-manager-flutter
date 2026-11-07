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

    test('property routes follow permissions', () {
      expect(
        redirect(user: user(Role.client), location: AppRoutes.properties),
        isNull,
      );
      expect(
        redirect(user: user(Role.client), location: '/properties/p-1'),
        isNull,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.agentListingNew),
        isNull,
      );
      expect(
        redirect(user: user(Role.client), location: AppRoutes.agentListings),
        AppRoutes.client,
      );
      expect(
        redirect(user: user(Role.admin), location: AppRoutes.agentListings),
        AppRoutes.admin,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.adminSettings),
        AppRoutes.agent,
      );
      expect(
        redirect(user: user(Role.admin), location: AppRoutes.adminSettings),
        isNull,
      );
    });

    test('saved properties are for clients only', () {
      expect(
        redirect(user: user(Role.client), location: AppRoutes.saved),
        isNull,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.saved),
        AppRoutes.agent,
      );
      expect(
        redirect(user: user(Role.admin), location: AppRoutes.saved),
        AppRoutes.admin,
      );
    });

    test('inquiry screens follow the role areas', () {
      expect(
        redirect(user: user(Role.client), location: AppRoutes.clientInquiries),
        isNull,
      );
      expect(
        redirect(
          user: user(Role.client),
          location: AppRoutes.newInquiry('p-1'),
        ),
        isNull,
      );
      expect(
        redirect(
          user: user(Role.agent),
          location: AppRoutes.agentInquiry('i-1'),
        ),
        isNull,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.clientInquiries),
        AppRoutes.agent,
      );
      expect(
        redirect(user: user(Role.client), location: AppRoutes.agentInquiries),
        AppRoutes.client,
      );
    });

    test('viewing screens follow the role areas', () {
      expect(
        redirect(user: user(Role.client), location: AppRoutes.clientViewings),
        isNull,
      );
      expect(
        redirect(
          user: user(Role.client),
          location: AppRoutes.newViewing('p-1'),
        ),
        isNull,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.agentViewings),
        isNull,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.clientViewings),
        AppRoutes.agent,
      );
      expect(
        redirect(user: user(Role.client), location: AppRoutes.agentViewings),
        AppRoutes.client,
      );
      expect(
        redirect(user: user(Role.admin), location: AppRoutes.agentViewings),
        AppRoutes.admin,
      );
    });

    test('lease screens follow the role areas', () {
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.agentLeases),
        isNull,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.agentLeaseNew),
        isNull,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.agentLease('l-1')),
        isNull,
      );
      expect(
        redirect(user: user(Role.client), location: AppRoutes.clientLeases),
        isNull,
      );
      expect(
        redirect(
          user: user(Role.client),
          location: AppRoutes.clientLease('l-1'),
        ),
        isNull,
      );
      expect(
        redirect(user: user(Role.client), location: AppRoutes.agentLeaseNew),
        AppRoutes.client,
      );
      expect(
        redirect(user: user(Role.agent), location: AppRoutes.clientLeases),
        AppRoutes.agent,
      );
      expect(
        redirect(user: user(Role.admin), location: AppRoutes.agentLeases),
        AppRoutes.admin,
      );
    });
  });
}
