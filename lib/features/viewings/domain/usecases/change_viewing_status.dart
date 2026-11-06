import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/time/clock.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:property_manager/features/viewings/domain/repositories/viewings_repository.dart';
import 'package:property_manager/features/viewings/domain/rules/viewing_rules.dart';
import 'package:property_manager/features/viewings/domain/rules/viewing_workflow.dart';
import 'package:property_manager/features/viewings/domain/viewing_access.dart';

/// Confirm, decline, cancel or complete: one entry point, one rule table.
final class ChangeViewingStatus {
  new(this._repository, this._currentUser, {Now? now})
    : _now = now ?? DateTime.now;

  final ViewingsRepository _repository;
  final CurrentUserReader _currentUser;
  final Now _now;

  Future<Result<Viewing>> call({
    required String viewingId,
    required ViewingStatus to,
    String? declineReason,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());

    final loaded = await loadParticipantViewing(_repository, actor, viewingId);
    final viewing = loaded.valueOrNull;
    if (viewing == null) return loaded;

    final allowed = ViewingWorkflow.canTransition(
      from: viewing.status,
      to: to,
      isClient: viewing.clientId == actor.id,
      isAgent: viewing.agentId == actor.id,
      scheduledAt: viewing.scheduledAt,
      now: _now(),
    );
    if (!allowed) {
      // A finished viewing means the screen was stale (the other side acted
      // first): a conflict, not a permissions problem.
      return Err(
        viewing.isActive ? const ForbiddenFailure() : const ConflictFailure(),
      );
    }

    final reason = declineReason?.trim();
    if (to == ViewingStatus.declined) {
      final invalid = ViewingRules.validateReason(reason);
      if (invalid != null) {
        return Err(ValidationFailure({'reason': invalid.name}));
      }
    }

    return await _repository.setStatus(
      viewingId,
      to,
      declineReason: to == ViewingStatus.declined ? reason : null,
    );
  }
}
