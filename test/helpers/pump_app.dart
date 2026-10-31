import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/app/theme/app_theme.dart';
import 'package:property_manager/core/config/app_config.dart';
import 'package:property_manager/core/config/flavor.dart';
import 'package:property_manager/core/logging/app_logger.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

const testConfig = AppConfig(
  flavor: Flavor.dev,
  appName: 'Test',
  supabaseUrl: '',
  supabaseAnonKey: '',
);

final class SilentLogger implements AppLogger {
  const new();
  @override
  void debug(String message) {}
  @override
  void info(String message) {}
  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget child, {List<Override> overrides = const []}) {
    return pumpWidget(
      ProviderScope(
        retry: disableAutoRetry,
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
  }
}
