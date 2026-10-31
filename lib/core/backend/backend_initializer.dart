import 'package:property_manager/core/backend/secure_local_storage.dart';
import 'package:property_manager/core/config/app_config.dart';
import 'package:property_manager/core/storage/secure_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dev/staging may run without a backend (a seeded in-memory fake is used).
/// Production must never silently fall back to fake data.
Future<void> initializeBackend(AppConfig config, SecureStore store) async {
  if (!config.hasBackendConfig) {
    if (config.isProd) {
      throw StateError('SUPABASE_URL / SUPABASE_ANON_KEY are missing.');
    }
    return;
  }
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(store),
    ),
  );
}
