import 'package:flutter/material.dart';
import 'package:property_manager/app/theme/design_tokens.dart';

abstract final class AppTheme {
  // Change one seed color and the full light/dark palettes regenerate.
  // This is the single re-branding point for clients.
  static const Color _seed = Color(0xFF1F6FEB);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}
