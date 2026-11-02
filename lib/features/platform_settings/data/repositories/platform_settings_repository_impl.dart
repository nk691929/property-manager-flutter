import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/platform_settings/data/datasources/platform_settings_data_source.dart';
import 'package:property_manager/features/platform_settings/domain/entities/platform_settings.dart';
import 'package:property_manager/features/platform_settings/domain/repositories/platform_settings_repository.dart';

final class PlatformSettingsRepositoryImpl
    implements PlatformSettingsRepository {
  const new(this._dataSource);

  final PlatformSettingsDataSource _dataSource;

  @override
  Future<Result<PlatformSettings>> get() => runCatching(_dataSource.fetch);

  @override
  Future<Result<PlatformSettings>> setRequireListingApproval({
    required bool value,
  }) => runCatching(() => _dataSource.setRequireListingApproval(value: value));
}
