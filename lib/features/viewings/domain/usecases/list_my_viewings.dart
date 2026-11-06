import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/paging.dart';
import 'package:property_manager/features/viewings/domain/repositories/viewings_repository.dart';

/// Clients see viewings they requested; agents those at their listings.
final class ListMyViewings {
  const new(this._repository, this._currentUser);

  final ViewingsRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<List<Viewing>>> call({int limit = viewingListLimit}) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (actor.can(Permission.requestViewings)) {
      return await _repository.listForClient(actor.id, limit: limit);
    }
    if (actor.can(Permission.handleViewings)) {
      return await _repository.listForAgent(actor.id, limit: limit);
    }
    return const Err(ForbiddenFailure());
  }
}
