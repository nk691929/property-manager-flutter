import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/properties/data/datasources/properties_data_source.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/viewings/data/datasources/viewings_data_source.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';

/// In-memory backend for dev (no config) and tests. Like the other fakes it
/// does NOT emulate RLS or the guard trigger; those are verified in Supabase.
final class FakeViewingsDataSource implements ViewingsDataSource {
  new({required this._properties});

  final PropertiesDataSource _properties;
  final Map<String, Viewing> _items = {};
  int _nextId = 1;

  Viewing _require(String id) => _items[id] ?? (throw const NotFoundFailure());

  static List<Viewing> _newest(Iterable<Viewing> source, int limit) {
    final sorted = source.toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<Viewing>> listForClient(
    String clientId, {
    required int limit,
  }) async =>
      _newest(_items.values.where((v) => v.clientId == clientId), limit);

  @override
  Future<List<Viewing>> listForAgent(
    String agentId, {
    required int limit,
  }) async => _newest(_items.values.where((v) => v.agentId == agentId), limit);

  @override
  Future<Viewing> getById(String id) async => _require(id);

  @override
  Future<Viewing?> findActive(String clientId, String propertyId) async =>
      _items.values
          .where(
            (v) =>
                v.clientId == clientId &&
                v.propertyId == propertyId &&
                v.isActive,
          )
          .firstOrNull;

  @override
  Future<Viewing> request({
    required String propertyId,
    required String clientId,
    required DateTime scheduledAt,
  }) async {
    final property = await _properties.getById(propertyId);
    if (property.status != PropertyStatus.published) {
      throw const NotFoundFailure();
    }
    final hasActive = _items.values.any(
      (v) => v.clientId == clientId && v.propertyId == propertyId && v.isActive,
    );
    if (hasActive) throw const ConflictFailure();

    final now = DateTime.now();
    final viewing = Viewing(
      id: 'v-${_nextId++}',
      propertyId: propertyId,
      propertyTitle: property.title,
      clientId: clientId,
      scheduledAt: scheduledAt,
      status: ViewingStatus.requested,
      createdAt: now,
      updatedAt: now,
      agentId: property.agentId,
    );
    return _items[viewing.id] = viewing;
  }

  @override
  Future<Viewing> setStatus(
    String id,
    ViewingStatus status, {
    String? declineReason,
  }) async {
    final old = _require(id);
    return _items[id] = old.copyWith(
      status: status,
      declineReason: status == ViewingStatus.declined ? declineReason : null,
      updatedAt: DateTime.now(),
    );
  }
}
