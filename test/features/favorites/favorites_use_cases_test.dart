import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/favorites/data/datasources/fake_favorites_data_source.dart';
import 'package:property_manager/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:property_manager/features/favorites/domain/usecases/add_favorite.dart';
import 'package:property_manager/features/favorites/domain/usecases/list_favorite_ids.dart';
import 'package:property_manager/features/favorites/domain/usecases/list_favorite_properties.dart';
import 'package:property_manager/features/favorites/domain/usecases/remove_favorite.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';
import 'package:property_manager/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';

import '../../helpers/property_test_helpers.dart';

void main() {
  late FavoritesRepositoryImpl favorites;
  late RecordingPropertiesRepository properties;

  setUp(() {
    favorites = FavoritesRepositoryImpl(FakeFavoritesDataSource());
    properties = RecordingPropertiesRepository(
      PropertiesRepositoryImpl(FakePropertiesDataSource.seeded()),
    );
  });

  Future<List<String>> savedIds(AppUser user) async =>
      (await ListFavoriteIds(favorites, () => user)()).valueOrNull ?? [];

  group('AddFavorite / RemoveFavorite', () {
    test('a client saves and removes a property', () async {
      expect(
        (await AddFavorite(favorites, () => clientUser)('p-1')).isOk,
        isTrue,
      );
      expect(await savedIds(clientUser), ['p-1']);

      expect(
        (await RemoveFavorite(favorites, () => clientUser)('p-1')).isOk,
        isTrue,
      );
      expect(await savedIds(clientUser), isEmpty);
    });

    test(
      'saving twice, or removing what is not saved, is not an error',
      () async {
        final add = AddFavorite(favorites, () => clientUser);
        await add('p-1');
        expect((await add('p-1')).isOk, isTrue);
        expect(await savedIds(clientUser), ['p-1']);

        expect(
          (await RemoveFavorite(favorites, () => clientUser)('p-9')).isOk,
          isTrue,
        );
      },
    );

    test('newest first', () async {
      final add = AddFavorite(favorites, () => clientUser);
      await add('p-1');
      await add('p-2');
      expect(await savedIds(clientUser), ['p-2', 'p-1']);
    });

    test(
      'agents are forbidden and signed-out users are unauthorized',
      () async {
        final asAgent = await AddFavorite(favorites, () => agentUser)('p-1');
        final signedOut = await AddFavorite(favorites, () => null)('p-1');
        expect(asAgent.failureOrNull, isA<ForbiddenFailure>());
        expect(signedOut.failureOrNull, isA<UnauthorizedFailure>());
      },
    );
  });

  group('ListFavoriteProperties', () {
    ListFavoriteProperties useCase(AppUser? user) =>
        ListFavoriteProperties(favorites, properties, () => user);

    test(
      'returns properties in saved order and skips ones that are gone',
      () async {
        final add = AddFavorite(favorites, () => clientUser);
        await add('p-1');
        await add('gone');
        await add('p-2');

        final result = await useCase(clientUser)();
        expect(
          [for (final p in result.valueOrNull ?? <Property>[]) p.id],
          ['p-2', 'p-1'],
        );
      },
    );

    test('nothing saved means no property request', () async {
      final result = await useCase(clientUser)();
      expect(result.valueOrNull, isEmpty);
      expect(properties.calls, isEmpty);
    });

    test('agents are forbidden', () async {
      final result = await useCase(agentUser)();
      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });
  });
}
