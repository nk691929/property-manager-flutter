import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/platform_settings/domain/repositories/platform_settings_repository.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/property_access.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';
import 'package:property_manager/features/properties/domain/rules/property_validators.dart';
import 'package:property_manager/features/properties/domain/rules/property_workflow.dart';

final class ChangePropertyStatus {
  const new(this._repository, this._settings, this._currentUser);

  final PropertiesRepository _repository;
  final PlatformSettingsRepository _settings;
  final CurrentUserReader _currentUser;

  Future<Result<Property>> call({
    required String propertyId,
    required PropertyStatus to,
    String? rejectionReason,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());

    final loaded = await loadManageable(_repository, actor, propertyId);
    final property = loaded.valueOrNull;
    if (property == null) {
      return Err(loaded.failureOrNull ?? const UnknownFailure());
    }

    // Never guess the rule: if settings can't be read, fail.
    final platform = await _settings.get();
    final approvalRequired = platform.valueOrNull?.requireListingApproval;
    if (approvalRequired == null) {
      return Err(platform.failureOrNull ?? const UnknownFailure());
    }

    final allowed = PropertyWorkflow.canTransition(
      from: property.status,
      to: to,
      asAdmin: actor.can(Permission.manageAllProperties),
      approvalRequired: approvalRequired,
    );
    if (!allowed) return const Err(ForbiddenFailure());

    final reason = rejectionReason?.trim();
    if (to == PropertyStatus.rejected && (reason == null || reason.isEmpty)) {
      return Err(ValidationFailure({'reason': PropertyFieldError.empty.name}));
    }

    return await _repository.setStatus(
      propertyId,
      to,
      rejectionReason: to == PropertyStatus.rejected ? reason : null,
    );
  }
}
