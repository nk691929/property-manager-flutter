import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/repositories/inquiries_repository.dart';
import 'package:property_manager/features/inquiries/domain/rules/inquiry_rules.dart';

final class StartInquiry {
  const new(this._repository, this._currentUser);

  final InquiriesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Inquiry>> call({
    required String propertyId,
    required String body,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.sendInquiries)) {
      return const Err(ForbiddenFailure());
    }
    final invalid = InquiryRules.validate(body);
    if (invalid != null) return Err(invalid);
    return await _repository.start(
      propertyId: propertyId,
      clientId: actor.id,
      body: body.trim(),
    );
  }
}
