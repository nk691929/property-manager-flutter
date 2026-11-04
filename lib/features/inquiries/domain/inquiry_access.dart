import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/repositories/inquiries_repository.dart';

/// Loads an inquiry and checks [actor] is a participant: the client who sent
/// it, or the listing's current agent. Shared by every thread use case.
Future<Result<Inquiry>> loadParticipantInquiry(
  InquiriesRepository repository,
  AppUser actor,
  String inquiryId,
) async {
  final asClient = actor.can(Permission.sendInquiries);
  final asAgent = actor.can(Permission.handleInquiries);
  if (!asClient && !asAgent) return const Err(ForbiddenFailure());

  final loaded = await repository.getById(inquiryId);
  final inquiry = loaded.valueOrNull;
  if (inquiry == null) return loaded;

  final isParticipant = asClient
      ? inquiry.clientId == actor.id
      : inquiry.agentId == actor.id;
  return isParticipant ? Ok(inquiry) : const Err(ForbiddenFailure());
}
