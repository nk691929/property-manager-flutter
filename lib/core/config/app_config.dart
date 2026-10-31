import 'package:property_manager/core/config/flavor.dart';

final class AppConfig {
  const new({
    required this.flavor,
    required this.appName,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  /// Reads compile-time values passed via --dart-define-from-file.
  factory fromEnvironment({required Flavor flavor, required String appName}) {
    return AppConfig(
      flavor: flavor,
      appName: appName,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  final Flavor flavor;
  final String appName;
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isProd => flavor == Flavor.prod;
  bool get verboseLogging => !isProd;
  bool get hasBackendConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
