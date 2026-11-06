import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/repositories/viewings_repository.dart';

/// Loads a viewing and checks [actor] is a participant: the client who
/// requested it, or the listing's current agent.
Future<Result<Viewing>> loadParticipantViewing(
  ViewingsRepository repository,
  AppUser actor,
  String viewingId,
) async {
  final asClient = actor.can(Permission.requestViewings);
  final asAgent = actor.can(Permission.handleViewings);
  if (!asClient && !asAgent) return const Err(ForbiddenFailure());

  final loaded = await repository.getById(viewingId);
  final viewing = loaded.valueOrNull;
  if (viewing == null) return loaded;

  final isParticipant = asClient
      ? viewing.clientId == actor.id
      : viewing.agentId == actor.id;
  return isParticipant ? Ok(viewing) : const Err(ForbiddenFailure());
}
