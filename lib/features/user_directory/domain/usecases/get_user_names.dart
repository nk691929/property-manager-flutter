import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/user_directory/domain/repositories/user_directory_repository.dart';

/// Any signed-in user may ask; the database decides which names come back.
final class GetUserNames {
  const new(this._repository, this._currentUser);

  final UserDirectoryRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Map<String, String>>> call(Set<String> userIds) async {
    if (_currentUser() == null) return const Err(UnauthorizedFailure());
    if (userIds.isEmpty) return const Ok(<String, String>{});
    return await _repository.namesFor(userIds);
  }
}
