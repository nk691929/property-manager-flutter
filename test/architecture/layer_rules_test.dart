import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Dart file under [root] as (path, source).
Iterable<(String, String)> _sources(String root) sync* {
  for (final entity in Directory(root).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield (entity.path.replaceAll(r'\', '/'), entity.readAsStringSync());
    }
  }
}

Iterable<String> _imports(String source) =>
    source.split('\n').where((line) => line.trimLeft().startsWith('import '));

void main() {
  test('features never import the app layer widgets', () {
    final offenders = [
      for (final (path, source) in _sources('lib/features'))
        if (source.contains('package:property_manager/app/widgets/')) path,
    ];
    expect(offenders, isEmpty, reason: 'compose features in lib/app instead');
  });

  test(
    'domain code never depends on Flutter, Riverpod, Supabase or other layers',
    () {
      const forbidden = [
        'package:flutter/',
        'package:flutter_riverpod',
        'package:riverpod',
        'package:supabase',
        '/data/',
        '/presentation/',
      ];
      final offenders = [
        for (final (path, source) in _sources('lib/features'))
          if (path.contains('/domain/'))
            for (final line in _imports(source))
              if (forbidden.any(line.contains)) '$path: ${line.trim()}',
      ];
      expect(offenders, isEmpty);
    },
  );

  test('data code never imports presentation code', () {
    final offenders = [
      for (final (path, source) in _sources('lib/features'))
        if (path.contains('/data/'))
          for (final line in _imports(source))
            if (line.contains('/presentation/')) '$path: ${line.trim()}',
    ];
    expect(offenders, isEmpty);
  });
}
