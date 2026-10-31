import 'package:property_manager/core/config/app_config.dart';
import 'package:property_manager/core/logging/app_logger.dart';
import 'package:property_manager/core/storage/secure_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'core_providers.g.dart';

/// Must be overridden in bootstrap(). Throwing here makes a missing override
/// fail loudly at startup rather than silently using wrong defaults.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) =>
    throw UnimplementedError('Override appConfigProvider in bootstrap().');

@Riverpod(keepAlive: true)
AppLogger appLogger(Ref ref) => const DeveloperLogger();

@Riverpod(keepAlive: true)
SecureStore secureStore(Ref ref) => const FlutterSecureStore();

/// Riverpod 3 retries failed providers automatically. We disable that globally:
/// retries are explicit, user-visible decision (Retry button), not hidden one.
Duration? disableAutoRetry(int retryCount, Object error) => null;
