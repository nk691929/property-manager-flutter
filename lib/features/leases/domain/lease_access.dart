import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';

/// Loads a lease and checks [actor] is a party: the tenant, or the listing's
/// current agent.
Future<Result<Lease>> loadParticipantLease(
  LeasesRepository repository,
  AppUser actor,
  String leaseId,
) async {
  final asTenant = actor.can(Permission.viewOwnLeases);
  final asAgent = actor.can(Permission.manageLeases);
  if (!asTenant && !asAgent) return const Err(ForbiddenFailure());

  final loaded = await repository.getById(leaseId);
  final lease = loaded.valueOrNull;
  if (lease == null) return loaded;

  final isParty = asTenant
      ? lease.tenantId == actor.id
      : lease.agentId == actor.id;
  return isParty ? Ok(lease) : const Err(ForbiddenFailure());
}
