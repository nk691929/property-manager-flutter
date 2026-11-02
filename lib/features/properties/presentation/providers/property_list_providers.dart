import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';
import 'package:property_manager/features/properties/domain/paging.dart';
import 'package:property_manager/features/properties/presentation/providers/properties_providers.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_query.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'property_list_providers.g.dart';

/// One paged list per [PropertyListQuery] (browse, my listings, admin).
@riverpod
class PropertyList extends _$PropertyList {
  late PropertyListQuery _query;

  @override
  Future<PagedProperties> build(PropertyListQuery query) async {
    _query = query;
    final page = await _fetch(offset: 0);
    return PagedProperties(
      items: page,
      hasMore: page.length == propertyPageSize,
    );
  }

  Future<List<Property>> _fetch({required int offset}) async {
    final result = switch (_query.scope) {
      PropertyScope.browse => await ref.read(searchPropertiesProvider)(
        _query.filter,
        offset: offset,
      ),
      PropertyScope.mine => await ref.read(listMyPropertiesProvider)(
        offset: offset,
        status: _query.status,
      ),
      PropertyScope.all => await ref.read(listAllPropertiesProvider)(
        offset: offset,
        status: _query.status,
      ),
    };
    return result.fold<List<Property>>(
      onOk: (items) => items,
      onErr: (failure) => throw failure,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailure: null),
    );
    try {
      final next = await _fetch(offset: current.items.length);
      if (!ref.mounted) return;
      // Offset paging can repeat a row if data shifts between pages.
      final seen = current.items.map((p) => p.id).toSet();
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...next.where((p) => !seen.contains(p.id))],
          hasMore: next.length == propertyPageSize,
          isLoadingMore: false,
        ),
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          loadMoreFailure: toFailure(error),
        ),
      );
    }
  }
}

@riverpod
Future<Property> propertyDetail(Ref ref, String id) async {
  final result = await ref.watch(getPropertyProvider)(id);
  return result.fold<Property>(
    onOk: (property) => property,
    onErr: (failure) => throw failure,
  );
}

/// Survives navigation so the filter is still there when you come back.
@Riverpod(keepAlive: true)
class BrowseFilter extends _$BrowseFilter {
  @override
  PropertyFilter build() => const PropertyFilter();

  void setQuery(String query) => state = state.copyWith(query: query);
  // A write-only setter is intentional: callers only replace the filter, and
  // the current value is read through the provider itself.
  // ignore: avoid_setters_without_getters
  set filter(PropertyFilter value) => state = value;
}

/// Mutations. keepAlive so the notifier outlives the page that called it
/// (a page often pops right after a successful save).
@Riverpod(keepAlive: true)
class PropertyActions extends _$PropertyActions {
  @override
  void build() {}

  Future<Failure?> create(PropertyDraft draft) =>
      _run(() => ref.read(createPropertyProvider)(draft));

  Future<Failure?> update(String id, PropertyDraft draft) =>
      _run(() => ref.read(updatePropertyProvider)(id, draft));

  Future<Failure?> changeStatus(
    String id,
    PropertyStatus to, {
    String? rejectionReason,
  }) => _run(
    () => ref.read(changePropertyStatusProvider)(
      propertyId: id,
      to: to,
      rejectionReason: rejectionReason,
    ),
  );

  Future<Failure?> delete(String id) =>
      _run(() => ref.read(deletePropertyProvider)(id));

  Future<Failure?> reassign(String id, String agentId) => _run(
    () => ref.read(reassignPropertyProvider)(propertyId: id, agentId: agentId),
  );

  /// Returns null on success, or the failure to show.
  Future<Failure?> _run<T>(Future<Result<T>> Function() action) async {
    final result = await action();
    if (!ref.mounted) return null;
    return result.fold<Failure?>(
      onOk: (_) {
        ref
          ..invalidate(propertyListProvider)
          ..invalidate(propertyDetailProvider);
        return null;
      },
      onErr: (failure) => failure,
    );
  }
}
