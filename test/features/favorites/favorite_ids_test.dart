import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/favorites/data/datasources/favorites_data_source.dart';
import 'package:property_manager/features/favorites/presentation/providers/favorites_providers.dart';

import '../../helpers/property_test_helpers.dart';

/// A data source whose requests the test can hold back and make fail.
final class _ControlledFavorites implements FavoritesDataSource {
  final calls = <String>[];
  final gates = <String, Completer<void>>{};
  final failFor = <String>{};

  @override
  Future<List<String>> listIds(String userId) async {
    calls.add('list');
    return [];
  }

  @override
  Future<void> add(String userId, String propertyId) async {
    calls.add('add:$propertyId');
    await gates[propertyId]?.future;
    if (failFor.contains(propertyId)) throw const NetworkFailure();
  }

  @override
  Future<void> remove(String userId, String propertyId) async {
    calls.add('remove:$propertyId');
  }
}

void main() {
  late _ControlledFavorites dataSource;

  setUp(() => dataSource = _ControlledFavorites());

  ProviderContainer containerFor(AppUser? user) {
    final container = ProviderContainer(
      overrides: [
        favoritesDataSourceProvider.overrideWithValue(dataSource),
        currentUserProvider.overrideWithValue(user),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  List<String>? ids(ProviderContainer c) => c.read(favoriteIdsProvider).value;

  test(
    'the heart changes before the server answers, and stays on success',
    () async {
      final container = containerFor(clientUser);
      await container.read(favoriteIdsProvider.future);

      final pending = container
          .read(favoriteIdsProvider.notifier)
          .toggle('p-1');
      expect(ids(container), ['p-1']); // optimistic, request not finished

      expect(await pending, isNull);
      expect(ids(container), ['p-1']);
      expect(dataSource.calls, ['list', 'add:p-1']);
    },
  );

  test('a refused request rolls the heart back and reports why', () async {
    final container = containerFor(clientUser);
    await container.read(favoriteIdsProvider.future);
    dataSource
      ..gates['p-1'] = Completer<void>()
      ..failFor.add('p-1');

    final pending = container.read(favoriteIdsProvider.notifier).toggle('p-1');
    expect(ids(container), ['p-1']);

    dataSource.gates['p-1']!.complete();
    expect(await pending, isA<NetworkFailure>());
    expect(ids(container), isEmpty);
  });

  test('a rollback undoes only its own change', () async {
    final container = containerFor(clientUser);
    await container.read(favoriteIdsProvider.future);
    dataSource
      ..gates['p-1'] = Completer<void>()
      ..failFor.add('p-1');
    final notifier = container.read(favoriteIdsProvider.notifier);

    final first = notifier.toggle('p-1'); // held back, will fail
    expect(await notifier.toggle('p-2'), isNull); // succeeds meanwhile
    expect(ids(container), ['p-2', 'p-1']);

    dataSource.gates['p-1']!.complete();
    expect(await first, isA<NetworkFailure>());
    expect(ids(container), ['p-2']); // p-2 survived the rollback
  });

  test(
    'a second tap on the same property while one is running is ignored',
    () async {
      final container = containerFor(clientUser);
      await container.read(favoriteIdsProvider.future);
      dataSource.gates['p-1'] = Completer<void>();
      final notifier = container.read(favoriteIdsProvider.notifier);

      final first = notifier.toggle('p-1');
      expect(await notifier.toggle('p-1'), isNull);
      dataSource.gates['p-1']!.complete();
      await first;

      expect(dataSource.calls.where((c) => c.startsWith('add')), hasLength(1));
      expect(ids(container), ['p-1']);
    },
  );

  test('non-clients get an empty list without any request', () async {
    final container = containerFor(agentUser);

    expect(await container.read(favoriteIdsProvider.future), isEmpty);
    expect(dataSource.calls, isEmpty);
  });
}
