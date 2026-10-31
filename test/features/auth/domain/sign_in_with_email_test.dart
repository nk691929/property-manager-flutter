import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:property_manager/features/auth/domain/usecases/sign_in_with_email.dart';

class MockAuthRepository extends Mock implements AuthRepository;

void main() {
  late MockAuthRepository repository;
  late SignInWithEmail useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = SignInWithEmail(repository);
  });

  test('invalid input never reaches the repository', () async {
    final result = await useCase(email: 'bad', password: '');

    final failure = result.failureOrNull;
    expect(failure, isA<ValidationFailure>());
    expect(
      (failure! as ValidationFailure).fieldErrors.keys,
      containsAll(['email', 'password']),
    );
    verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('valid input is trimmed and delegated', () async {
    when(() => repository.signIn(email: 'a@b.co', password: 'pw'))
        .thenAnswer((_) async => const Ok(null));

    final result = await useCase(email: '  a@b.co ', password: 'pw');

    expect(result.isOk, isTrue);
    verify(() => repository.signIn(email: 'a@b.co', password: 'pw')).called(1);
  });
}
