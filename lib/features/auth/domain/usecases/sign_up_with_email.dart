import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/sign_up_outcome.dart';
import 'package:property_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:property_manager/features/auth/domain/validators/auth_validators.dart';

final class SignUpWithEmail {
  const new(this._repository);

  final AuthRepository _repository;

  Future<Result<SignUpOutcome>> call({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final errors = <String, String>{
      if (AuthValidators.email(email) case final e?) 'email': e.name,
      if (AuthValidators.password(password) case final e?) 'password': e.name,
    };
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));

    final name = fullName?.trim();
    return await _repository.signUp(
      email: email.trim(),
      password: password,
      fullName: (name == null || name.isEmpty) ? null : name,
    );
  }
}
