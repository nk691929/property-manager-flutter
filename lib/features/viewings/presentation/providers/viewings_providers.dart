import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/providers/supabase_provider.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/properties/presentation/providers/properties_providers.dart';
import 'package:property_manager/features/viewings/data/datasources/fake_viewings_data_source.dart';
import 'package:property_manager/features/viewings/data/datasources/supabase_viewings_data_source.dart';
import 'package:property_manager/features/viewings/data/datasources/viewings_data_source.dart';
import 'package:property_manager/features/viewings/data/repositories/viewings_repository_impl.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:property_manager/features/viewings/domain/repositories/viewings_repository.dart';
import 'package:property_manager/features/viewings/domain/usecases/change_viewing_status.dart';
import 'package:property_manager/features/viewings/domain/usecases/find_active_viewing.dart';
import 'package:property_manager/features/viewings/domain/usecases/list_my_viewings.dart';
import 'package:property_manager/features/viewings/domain/usecases/request_viewing.dart';
import 'package:property_manager/features/viewings/domain/viewing_board.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'viewings_providers.g.dart';

// Composition root for viewings (allowed to see data/).

@Riverpod(keepAlive: true)
ViewingsDataSource viewingsDataSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasBackendConfig
      ? SupabaseViewingsDataSource(ref.watch(supabaseClientProvider))
      : FakeViewingsDataSource(
          properties: ref.watch(propertiesDataSourceProvider),
        );
}

@Riverpod(keepAlive: true)
ViewingsRepository viewingsRepository(Ref ref) =>
    ViewingsRepositoryImpl(ref.watch(viewingsDataSourceProvider));

@riverpod
RequestViewing requestViewing(Ref ref) => RequestViewing(
  ref.watch(viewingsRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ChangeViewingStatus changeViewingStatus(Ref ref) => ChangeViewingStatus(
  ref.watch(viewingsRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ListMyViewings listMyViewings(Ref ref) => ListMyViewings(
  ref.watch(viewingsRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
FindActiveViewing findActiveViewing(Ref ref) => FindActiveViewing(
  ref.watch(viewingsRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
Future<ViewingBoard> viewingBoard(Ref ref) async {
  final result = await ref.watch(listMyViewingsProvider)();
  return result.fold<ViewingBoard>(
    onOk: ViewingBoard.from,
    onErr: (failure) => throw failure,
  );
}

/// The client's requested or confirmed viewing for a listing, or null.
@riverpod
Future<Viewing?> activeViewingFor(Ref ref, String propertyId) async {
  final result = await ref.watch(findActiveViewingProvider)(propertyId);
  return result.fold<Viewing?>(
    onOk: (viewing) => viewing,
    onErr: (failure) => throw failure,
  );
}

/// Mutations. keepAlive so the notifier outlives the page that called it
/// (a successful request replaces its own page).
@Riverpod(keepAlive: true)
class ViewingActions extends _$ViewingActions {
  @override
  void build() {}

  Future<Result<Viewing>> request(
    String propertyId,
    DateTime scheduledAt,
  ) async {
    final result = await ref.read(requestViewingProvider)(
      propertyId: propertyId,
      scheduledAt: scheduledAt,
    );
    if (ref.mounted && result.isOk) _refreshData();
    return result;
  }

  /// Returns null on success, or the failure to show.
  Future<Failure?> changeStatus(
    String viewingId,
    ViewingStatus to, {
    String? declineReason,
  }) async {
    final result = await ref.read(changeViewingStatusProvider)(
      viewingId: viewingId,
      to: to,
      declineReason: declineReason,
    );
    if (!ref.mounted) return null;
    return result.fold<Failure?>(
      onOk: (_) {
        _refreshData();
        return null;
      },
      onErr: (failure) {
        // A stale screen (the other side acted first): show what is true now.
        if (failure is ConflictFailure ||
            failure is ForbiddenFailure ||
            failure is NotFoundFailure) {
          _refreshData();
        }
        return failure;
      },
    );
  }

  void _refreshData() {
    ref
      ..invalidate(viewingBoardProvider)
      ..invalidate(activeViewingForProvider);
  }
}
