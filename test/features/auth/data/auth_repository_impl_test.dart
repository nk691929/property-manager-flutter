import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/data/datasources/fake_auth_data_source.dart';
import 'package:property_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/auth/domain/entities/sign_up_outcome.dart';

import '../../../helpers/pump_app.dart';

void main() {
  late FakeAuthDataSource dataSource;
  late AuthRepositoryImpl repository;
  late List<AppUser?> emitted;

  setUp(() {
    dataSource = FakeAuthDataSource.seeded();
    repository = AuthRepositoryImpl(
      dataSource: dataSource,
      logger: const SilentLogger(),
    );
    emitted = [];
    repository.authStateChanges().listen(emitted.add);
  });

  tearDown(() => dataSource.dispose());

  test('starts signed out', () async {
    await pumpEventQueue();
    expect(emitted, [null]);
  });

  test('sign-in emits the profile with its role', () async {
    final result = await repository.signIn(
      email: 'admin@example.com',
      password: 'Password1',
    );
    await pumpEventQueue();

    expect(result.isOk, isTrue);
    expect(emitted.last?.role, Role.admin);
  });

  test('wrong password yields InvalidCredentialsFailure', () async {
    final result = await repository.signIn(
      email: 'admin@example.com',
      password: 'wrong',
    );
    expect(result.failureOrNull, isA<InvalidCredentialsFailure>());
  });

  test('sign-up always creates a client', () async {
    final result = await repository.signUp(
      email: 'new@example.com',
      password: 'Password1',
      fullName: 'New Person',
    );
    await pumpEventQueue();

    expect(result.valueOrNull, SignUpOutcome.signedIn);
    expect(emitted.last?.role, Role.client);
  });

  test('duplicate email is a ValidationFailure', () async {
    final result = await repository.signUp(
      email: 'admin@example.com',
      password: 'Password1',
    );
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('sign-out emits null after a signed-in user', () async {
    await repository.signIn(email: 'client@example.com', password: 'Password1');
    await pumpEventQueue();
    expect(emitted.last, isNotNull);

    await repository.signOut();
    await pumpEventQueue();

    expect(emitted.last, isNull);
  });
}
