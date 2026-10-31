import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/repositories/auth_repository.dart';

final class SignOut {
  const new(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() async => await _repository.signOut();
}
