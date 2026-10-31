import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/admin_users/domain/repositories/admin_users_repository.dart';
import 'package:property_manager/features/admin_users/domain/usecases/change_user_role.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

class MockAdminUsersRepository extends Mock implements AdminUsersRepository;

void main() {
  setUpAll(() => registerFallbackValue(Role.client));
  const admin = AppUser(id: 'a', email: 'a@x.com', role: Role.admin);
  const agent = AppUser(id: 'g', email: 'g@x.com', role: Role.agent);
  const client = AppUser(id: 'c', email: 'c@x.com', role: Role.client);

  late MockAdminUsersRepository repository;

  setUp(() => repository = MockAdminUsersRepository());

  ChangeUserRole useCaseFor(AppUser? actor) =>
      ChangeUserRole(repository, () => actor);

  test('signed-out actor is unauthorized', () async {
    final result = await useCaseFor(null)(userId: 'c', role: Role.agent);
    expect(result.failureOrNull, isA<UnauthorizedFailure>());
  });

  test('non-admin is forbidden and the repository is untouched', () async {
    final result = await useCaseFor(agent)(userId: 'c', role: Role.admin);
    expect(result.failureOrNull, isA<ForbiddenFailure>());
    verifyNever(
      () => repository.changeRole(
        userId: any(named: 'userId'),
        role: any(named: 'role'),
      ),
    );
  });

  test('admin cannot change their own role', () async {
    final result = await useCaseFor(admin)(userId: 'a', role: Role.client);
    expect(result.failureOrNull, isA<ForbiddenFailure>());
  });

  test('admin can promote another user', () async {
    when(() => repository.changeRole(userId: 'c', role: Role.agent))
        .thenAnswer((_) async => Ok(client.copyWith(role: Role.agent)));

    final result = await useCaseFor(admin)(userId: 'c', role: Role.agent);

    expect(result.valueOrNull?.role, Role.agent);
  });
}
