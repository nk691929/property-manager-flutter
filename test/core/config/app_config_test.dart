import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/config/app_config.dart';
import 'package:property_manager/core/config/flavor.dart';

void main() {
  AppConfig make(Flavor f, {String url = '', String key = ''}) => AppConfig(
    flavor: f,
    appName: 'x',
    supabaseUrl: url,
    supabaseAnonKey: key,
  );

  test('prod is quiet, non-prod is verbose', () {
    expect(make(Flavor.prod).verboseLogging, isFalse);
    expect(make(Flavor.dev).verboseLogging, isTrue);
  });

  test('hasBackendConfig requires both url and key', () {
    expect(make(Flavor.dev, url: 'u').hasBackendConfig, isFalse);
    expect(make(Flavor.dev, url: 'u', key: 'k').hasBackendConfig, isTrue);
  });
}
