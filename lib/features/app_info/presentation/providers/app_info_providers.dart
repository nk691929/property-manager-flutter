import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/features/app_info/data/datasources/package_info_data_source.dart';
import 'package:property_manager/features/app_info/data/repositories/app_info_repository_impl.dart';
import 'package:property_manager/features/app_info/domain/entities/app_info.dart';
import 'package:property_manager/features/app_info/domain/repositories/app_info_repository.dart';
import 'package:property_manager/features/app_info/domain/usecases/get_app_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info_providers.g.dart';

// Composition root for this feature. This is the ONLY presentation-layer file
// allowed to import from data/ (see ADR-001).

@riverpod
PackageInfoDataSource packageInfoDataSource(Ref ref) =>
    const PackageInfoDataSourceImpl();

@riverpod
AppInfoRepository appInfoRepository(Ref ref) => AppInfoRepositoryImpl(
  dataSource: ref.watch(packageInfoDataSourceProvider),
  flavor: ref.watch(appConfigProvider).flavor,
  logger: ref.watch(appLoggerProvider),
);

@riverpod
GetAppInfo getAppInfo(Ref ref) =>
    GetAppInfo(ref.watch(appInfoRepositoryProvider));

/// Bridges Result -> AsyncValue: Err becomes AsyncError(failure).
@riverpod
Future<AppInfo> appInfo(Ref ref) async {
  final result = await ref.watch(getAppInfoProvider)();
  return result.fold<AppInfo>(
    onOk: (value) => value,
    onErr: (failure) => throw failure,
  );
}
