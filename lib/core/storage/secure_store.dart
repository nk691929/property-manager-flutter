import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction for secrets (auth tokens in MVP 1). Backed by the iOS Keychain
/// Android Keystore-encrypted storage. Never use SharedPreferences for tokens.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

final class FlutterSecureStore implements SecureStore {
  const new([FlutterSecureStorage storage = const FlutterSecureStorage()])
    : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}
