import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/providers/supabase_provider.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/favorites/data/datasources/fake_favorites_data_source.dart';
import 'package:property_manager/features/favorites/data/datasources/favorites_data_source.dart';
import 'package:property_manager/features/favorites/data/datasources/supabase_favorites_data_source.dart';
import 'package:property_manager/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:property_manager/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:property_manager/features/favorites/domain/usecases/add_favorite.dart';
import 'package:property_manager/features/favorites/domain/usecases/list_favorite_ids.dart';
import 'package:property_manager/features/favorites/domain/usecases/list_favorite_properties.dart';
import 'package:property_manager/features/favorites/domain/usecases/remove_favorite.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/presentation/providers/properties_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorites_providers.g.dart';

// Composition root for favorites (allowed to see data/).

@Riverpod(keepAlive: true)
FavoritesDataSource favoritesDataSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasBackendConfig
      ? SupabaseFavoritesDataSource(ref.watch(supabaseClientProvider))
      : FakeFavoritesDataSource();
}

@Riverpod(keepAlive: true)
FavoritesRepository favoritesRepository(Ref ref) =>
    FavoritesRepositoryImpl(ref.watch(favoritesDataSourceProvider));

@riverpod
ListFavoriteIds listFavoriteIds(Ref ref) => ListFavoriteIds(
  ref.watch(favoritesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
AddFavorite addFavorite(Ref ref) => AddFavorite(
  ref.watch(favoritesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
RemoveFavorite removeFavorite(Ref ref) => RemoveFavorite(
  ref.watch(favoritesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ListFavoriteProperties listFavoriteProperties(Ref ref) =>
    ListFavoriteProperties(
      ref.watch(favoritesRepositoryProvider),
      ref.watch(propertiesRepositoryProvider),
      () => ref.read(currentUserProvider),
    );

/// The signed-in client's saved ids, newest first, with optimistic toggling.
@Riverpod(keepAlive: true)
class FavoriteIds extends _$FavoriteIds {
  final _inFlight = <String>{};

  @override
  Future<List<String>> build() async {
    // Watching the user rebuilds this when someone else signs in, so one
    // person's hearts never leak to the next (this provider lives all session).
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.can(Permission.favoriteProperties)) {
      return const <String>[];
    }
    final result = await ref.watch(listFavoriteIdsProvider)();
    return result.fold<List<String>>(
      onOk: (ids) => ids,
      onErr: (failure) => throw failure,
    );
  }

  /// Returns null on success, or the failure to show.
  Future<Failure?> toggle(String propertyId) async {
    final current = state.value;
    // Not loaded yet, or a request for this property is already running
    // (a double tap would otherwise race two opposite requests).
    if (current == null || !_inFlight.add(propertyId)) return null;

    final wasFavorite = current.contains(propertyId);
    // Optimistic: the heart changes before the server answers.
    state = AsyncData(_with(current, propertyId, favorite: !wasFavorite));
    try {
      final result = wasFavorite
          ? await ref.read(removeFavoriteProvider)(propertyId)
          : await ref.read(addFavoriteProvider)(propertyId);
      if (!ref.mounted || result.isOk) return null;

      // Undo only this change. Other taps made meanwhile must survive, so we
      // don't restore the old list.
      state = AsyncData(
        _with(state.value ?? current, propertyId, favorite: wasFavorite),
      );
      return result.failureOrNull;
    } finally {
      _inFlight.remove(propertyId);
    }
  }

  static List<String> _with(
    List<String> ids,
    String propertyId, {
    required bool favorite,
  }) {
    final others = [
      for (final id in ids)
        if (id != propertyId) id,
    ];
    return favorite ? [propertyId, ...others] : others;
  }
}

/// Loaded each time the Saved screen opens; the screen hides entries the user
/// un-hearts meanwhile, so no refetch is needed on every tap.
@riverpod
Future<List<Property>> savedProperties(Ref ref) async {
  final result = await ref.watch(listFavoritePropertiesProvider)();
  return result.fold<List<Property>>(
    onOk: (items) => items,
    onErr: (failure) => throw failure,
  );
}
