import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:property_manager/core/config/flavor.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/app_info/data/datasources/package_info_data_source.dart';
import 'package:property_manager/features/app_info/data/repositories/app_info_repository_impl.dart';

import '../../../helpers/pump_app.dart';

class MockPackageInfoDataSource extends Mock implements PackageInfoDataSource;

void main() {
  late MockPackageInfoDataSource dataSource;
  late AppInfoRepositoryImpl repository;

  setUp(() {
    dataSource = MockPackageInfoDataSource();
    repository = AppInfoRepositoryImpl(
      dataSource: dataSource,
      flavor: Flavor.staging,
      logger: const SilentLogger(),
    );
  });

  test('maps PackageInfo to AppInfo', () async {
    when(dataSource.load).thenAnswer(
      (_) async => PackageInfo(
        appName: 'PM',
        packageName: 'com.x',
        version: '1.2.3',
        buildNumber: '7',
      ),
    );

    final info = (await repository.getAppInfo()).valueOrNull;

    expect(info?.appName, 'PM');
    expect(info?.version, '1.2.3');
    expect(info?.buildNumber, '7');
    expect(info?.flavor, Flavor.staging);
  });

  test('translates exceptions into UnknownFailure', () async {
    when(dataSource.load).thenThrow(Exception('boom'));

    final result = await repository.getAppInfo();

    expect(result.failureOrNull, isA<UnknownFailure>());
  });
}
