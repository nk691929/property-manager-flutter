import 'package:package_info_plus/package_info_plus.dart';

abstract interface class PackageInfoDataSource {
  Future<PackageInfo> load();
}

final class PackageInfoDataSourceImpl implements PackageInfoDataSource {
  const new();

  @override
  Future<PackageInfo> load() => PackageInfo.fromPlatform();
}
