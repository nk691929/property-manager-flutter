import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/inquiry_access.dart';
import 'package:property_manager/features/inquiries/domain/repositories/inquiries_repository.dart';

final class GetInquiry {
  const new(this._repository, this._currentUser);

  final InquiriesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Inquiry>> call(String inquiryId) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    return await loadParticipantInquiry(_repository, actor, inquiryId);
  }
}
