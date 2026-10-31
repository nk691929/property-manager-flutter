import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:property_manager/features/auth/domain/validators/auth_validators.dart';

final class SignInWithEmail {
  const new(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String password,
  }) async {
    final errors = <String, String>{
      if (AuthValidators.email(email) case final e?) 'email': e.name,
      if (AuthValidators.signInPassword(password) case final e?)
        'password': e.name,
    };
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));
    return await _repository.signIn(email: email.trim(), password: password);
  }
}
