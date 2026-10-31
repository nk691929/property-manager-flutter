import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/app.dart';
import 'package:property_manager/core/config/app_config.dart';
import 'package:property_manager/core/logging/app_logger.dart';
import 'package:property_manager/core/providers/core_providers.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = DeveloperLogger(verbose: config.verboseLogging);

  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    logger.error(
      'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Catches async errors that never reach the Flutter framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught error', error: error, stackTrace: stack);
    return true;
  };

  runApp(
    ProviderScope(
      retry: disableAutoRetry,
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appLoggerProvider.overrideWithValue(logger),
      ],
      child: const App(),
    ),
  );
}
