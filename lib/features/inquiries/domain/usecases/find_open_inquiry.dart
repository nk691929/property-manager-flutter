import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/repositories/inquiries_repository.dart';

/// Lets the detail screen say "View conversation" instead of "Contact agent".
final class FindOpenInquiry {
  const new(this._repository, this._currentUser);

  final InquiriesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Inquiry?>> call(String propertyId) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.sendInquiries)) {
      return const Err(ForbiddenFailure());
    }
    return await _repository.findOpen(actor.id, propertyId);
  }
}
