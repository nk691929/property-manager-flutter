import 'package:property_manager/core/config/flavor.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/logging/app_logger.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/app_info/data/datasources/package_info_data_source.dart';
import 'package:property_manager/features/app_info/domain/entities/app_info.dart';
import 'package:property_manager/features/app_info/domain/repositories/app_info_repository.dart';

final class AppInfoRepositoryImpl implements AppInfoRepository {
  const new({
    required this._dataSource,
    required this._flavor,
    required this._logger,
  });

  final PackageInfoDataSource _dataSource;
  final Flavor _flavor;
  final AppLogger _logger;

  @override
  Future<Result<AppInfo>> getAppInfo() async {
    try {
      final info = await _dataSource.load();
      return Ok(
        AppInfo(
          appName: info.appName,
          version: info.version,
          buildNumber: info.buildNumber,
          flavor: _flavor,
        ),
      );
    } on Object catch (e, st) {
      // The boundary: exceptions stop here and become typed Failures.
      _logger.error('Failed to load package info', error: e, stackTrace: st);
      return Err(UnknownFailure(cause: e, stackTrace: st));
    }
  }
}
