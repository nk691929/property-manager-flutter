import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:property_manager/core/config/flavor.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/app_info/domain/entities/app_info.dart';
import 'package:property_manager/features/app_info/domain/repositories/app_info_repository.dart';
import 'package:property_manager/features/app_info/domain/usecases/get_app_info.dart';

class MockAppInfoRepository extends Mock implements AppInfoRepository;

void main() {
  test('delegates to the repository', () async {
    final repo = MockAppInfoRepository();
    const info = AppInfo(
      appName: 'A',
      version: '1.0.0',
      buildNumber: '1',
      flavor: Flavor.dev,
    );
    when(repo.getAppInfo).thenAnswer((_) async => const Ok(info));

    final result = await GetAppInfo(repo)();

    expect(result.valueOrNull, info);
    verify(repo.getAppInfo).called(1);
  });
}
