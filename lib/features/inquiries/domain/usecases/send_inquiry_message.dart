import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';
import 'package:property_manager/features/inquiries/domain/inquiry_access.dart';
import 'package:property_manager/features/inquiries/domain/repositories/inquiries_repository.dart';
import 'package:property_manager/features/inquiries/domain/rules/inquiry_rules.dart';

final class SendInquiryMessage {
  const new(this._repository, this._currentUser);

  final InquiriesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<InquiryMessage>> call({
    required String inquiryId,
    required String body,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());

    final invalid = InquiryRules.validate(body);
    if (invalid != null) return Err(invalid);

    final loaded = await loadParticipantInquiry(_repository, actor, inquiryId);
    final inquiry = loaded.valueOrNull;
    if (inquiry == null) {
      return Err(loaded.failureOrNull ?? const UnknownFailure());
    }
    // Closed conversations accept nothing (the database refuses it too).
    if (!inquiry.isOpen) return const Err(ConflictFailure());

    return await _repository.send(
      inquiryId,
      senderId: actor.id,
      body: body.trim(),
    );
  }
}
