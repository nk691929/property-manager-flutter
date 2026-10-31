import 'package:property_manager/core/storage/secure_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores the Supabase session in the Keychain/Keystore instead of the
/// default SharedPreferences (plain text on disk).
final class SecureLocalStorage extends LocalStorage {
  new(this._store);

  static const _key = 'supabase.session';

  final SecureStore _store;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => (await _store.read(_key)) != null;

  @override
  Future<String?> accessToken() => _store.read(_key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(_key, persistSessionString);

  @override
  Future<void> removePersistedSession() => _store.delete(_key);
}
