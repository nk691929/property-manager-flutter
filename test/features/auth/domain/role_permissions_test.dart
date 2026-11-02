import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/auth/domain/entities/role_permissions.dart';

void main() {
  test('wire names match the database enum', () {
    expect(Role.values.map((r) => r.wireName), ['admin', 'agent', 'client']);
  });

  test('unknown wire role degrades to client (least privilege)', () {
    expect(Role.fromWire('superuser'), Role.client);
    expect(Role.fromWire('admin'), Role.admin);
  });

  test('every role has at least one permission', () {
    for (final role in Role.values) {
      expect(permissionsFor(role), isNotEmpty, reason: role.name);
    }
  });

  test('only admin can manage users', () {
    AppUser userWith(Role role) =>
        AppUser(id: 'x', email: 'x@x.com', role: role);

    expect(userWith(Role.admin).can(Permission.manageUsers), isTrue);
    expect(userWith(Role.agent).can(Permission.manageUsers), isFalse);
    expect(userWith(Role.client).can(Permission.manageUsers), isFalse);
  });

  test('displayName falls back to email', () {
    const named = AppUser(
      id: '1',
      email: 'a@x.com',
      role: Role.client,
      fullName: ' Ada ',
    );
    const unnamed = AppUser(id: '2', email: 'b@x.com', role: Role.client);
    expect(named.displayName, 'Ada');
    expect(unnamed.displayName, 'b@x.com');
  });
  test('agents manage their own listings, admins manage all', () {
    const agent = AppUser(id: 'a', email: 'a@x.com', role: Role.agent);
    const admin = AppUser(id: 'b', email: 'b@x.com', role: Role.admin);
    const client = AppUser(id: 'c', email: 'c@x.com', role: Role.client);

    expect(agent.can(Permission.manageOwnProperties), isTrue);
    expect(agent.can(Permission.manageAllProperties), isFalse);
    expect(admin.can(Permission.manageAllProperties), isTrue);
    expect(admin.can(Permission.manageSettings), isTrue);
    expect(agent.can(Permission.manageSettings), isFalse);
    for (final user in [agent, admin, client]) {
      expect(user.can(Permission.browseProperties), isTrue);
    }
    expect(client.can(Permission.manageOwnProperties), isFalse);
  });
}
