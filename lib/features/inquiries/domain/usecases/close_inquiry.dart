import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/inquiry_access.dart';
import 'package:property_manager/features/inquiries/domain/repositories/inquiries_repository.dart';

final class CloseInquiry {
  const new(this._repository, this._currentUser);

  final InquiriesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Inquiry>> call(String inquiryId) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());

    final loaded = await loadParticipantInquiry(_repository, actor, inquiryId);
    final inquiry = loaded.valueOrNull;
    if (inquiry == null) return loaded;

    // Closing twice is harmless: same end state.
    if (!inquiry.isOpen) return Ok(inquiry);
    return await _repository.close(inquiryId);
  }
}
