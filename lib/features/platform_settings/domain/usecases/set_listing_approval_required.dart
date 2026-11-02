import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/platform_settings/domain/entities/platform_settings.dart';
import 'package:property_manager/features/platform_settings/domain/repositories/platform_settings_repository.dart';

final class SetListingApprovalRequired {
  const new(this._repository, this._currentUser);

  final PlatformSettingsRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<PlatformSettings>> call({required bool value}) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageSettings)) {
      return const Err(ForbiddenFailure());
    }
    return await _repository.setRequireListingApproval(value: value);
  }
}
