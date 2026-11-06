import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/time/clock.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/repositories/viewings_repository.dart';
import 'package:property_manager/features/viewings/domain/rules/viewing_rules.dart';

final class RequestViewing {
  new(this._repository, this._currentUser, {Now? now})
    : _now = now ?? DateTime.now;

  final ViewingsRepository _repository;
  final CurrentUserReader _currentUser;
  final Now _now;

  Future<Result<Viewing>> call({
    required String propertyId,
    required DateTime scheduledAt,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.requestViewings)) {
      return const Err(ForbiddenFailure());
    }
    final invalid = ViewingRules.validateTime(scheduledAt, now: _now());
    if (invalid != null) {
      return Err(ValidationFailure({'time': invalid.name}));
    }
    return await _repository.request(
      propertyId: propertyId,
      clientId: actor.id,
      scheduledAt: scheduledAt,
    );
  }
}
