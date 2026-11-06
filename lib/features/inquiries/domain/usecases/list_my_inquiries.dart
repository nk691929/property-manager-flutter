import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/paging.dart';
import 'package:property_manager/features/inquiries/domain/repositories/inquiries_repository.dart';

/// Clients see conversations they started; agents those about their listings.
final class ListMyInquiries {
  const new(this._repository, this._currentUser);

  final InquiriesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<List<Inquiry>>> call({
    required int offset,
    int limit = inquiryPageSize,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (actor.can(Permission.sendInquiries)) {
      return await _repository.listForClient(
        actor.id,
        offset: offset,
        limit: limit,
      );
    }
    if (actor.can(Permission.handleInquiries)) {
      return await _repository.listForAgent(
        actor.id,
        offset: offset,
        limit: limit,
      );
    }
    return const Err(ForbiddenFailure());
  }
}
