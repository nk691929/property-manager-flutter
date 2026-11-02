import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/properties/data/datasources/properties_data_source.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';

/// In-memory backend for dev (no config) and tests. It does NOT emulate RLS:
/// the database rules are verified against real Supabase, not here.
final class FakePropertiesDataSource implements PropertiesDataSource {
  new({Iterable<Property> properties = const []}) {
    for (final p in properties) {
      _items[p.id] = p;
    }
  }

  /// Seed: p-1..p-6 published, p-7 draft, p-8 pending review, p-9 rejected.
  /// All owned by the fake agent `u-agent`.
  factory seeded() => FakePropertiesDataSource(properties: _seed());

  final Map<String, Property> _items = {};
  int _nextId = 100;

  Property _require(String id) => _items[id] ?? (throw const NotFoundFailure());

  static DateTime _recency(Property p) => p.publishedAt ?? p.createdAt;

  static Comparator<Property> _comparator(PropertySort sort) => switch (sort) {
    PropertySort.newest => (Property a, Property b) => _recency(
      b,
    ).compareTo(_recency(a)),
    PropertySort.priceAsc => (Property a, Property b) => a.price.compareTo(
      b.price,
    ),
    PropertySort.priceDesc => (Property a, Property b) => b.price.compareTo(
      a.price,
    ),
  };

  static bool _matches(Property p, PropertyFilter f) {
    final q = f.query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !p.title.toLowerCase().contains(q) &&
        !p.city.toLowerCase().contains(q)) {
      return false;
    }
    final city = f.city.trim().toLowerCase();
    if (city.isNotEmpty && !p.city.toLowerCase().contains(city)) return false;
    if (f.listingType != null && p.listingType != f.listingType) return false;
    if (f.propertyType != null && p.propertyType != f.propertyType) {
      return false;
    }
    if (f.minPrice case final min? when p.price < min) return false;
    if (f.maxPrice case final max? when p.price > max) return false;
    if (f.minBedrooms case final min? when (p.bedrooms ?? 0) < min) {
      return false;
    }
    return true;
  }

  List<Property> _page(
    Iterable<Property> source, {
    required int offset,
    required int limit,
  }) {
    final sorted = source.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Property>> search(
    PropertyFilter filter, {
    required int offset,
    required int limit,
  }) async {
    final matches =
        _items.values
            .where(
              (p) =>
                  p.status == PropertyStatus.published && _matches(p, filter),
            )
            .toList()
          ..sort(_comparator(filter.sort));
    return matches.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Property>> listByAgent(
    String agentId, {
    required int offset,
    required int limit,
    PropertyStatus? status,
  }) async => _page(
    _items.values.where(
      (p) => p.agentId == agentId && (status == null || p.status == status),
    ),
    offset: offset,
    limit: limit,
  );

  @override
  Future<List<Property>> listAll({
    required int offset,
    required int limit,
    PropertyStatus? status,
  }) async => _page(
    _items.values.where((p) => status == null || p.status == status),
    offset: offset,
    limit: limit,
  );

  @override
  Future<Property> getById(String id) async => _require(id);

  @override
  Future<Property> create(PropertyDraft draft, String agentId) async {
    final now = DateTime.now();
    final property = Property(
      id: 'p-${_nextId++}',
      agentId: agentId,
      title: draft.title.trim(),
      description: draft.description.trim(),
      listingType: draft.listingType,
      propertyType: draft.propertyType,
      price: draft.price,
      currency: draft.currency,
      bedrooms: draft.bedrooms,
      bathrooms: draft.bathrooms,
      areaValue: draft.areaValue,
      areaUnit: draft.areaUnit,
      city: draft.city.trim(),
      address: draft.address.trim(),
      status: PropertyStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
    return _items[property.id] = property;
  }

  @override
  Future<Property> update(String id, PropertyDraft draft) async {
    final old = _require(id);
    return _items[id] = old.copyWith(
      title: draft.title.trim(),
      description: draft.description.trim(),
      listingType: draft.listingType,
      propertyType: draft.propertyType,
      price: draft.price,
      currency: draft.currency,
      bedrooms: draft.bedrooms,
      bathrooms: draft.bathrooms,
      areaValue: draft.areaValue,
      areaUnit: draft.areaUnit,
      city: draft.city.trim(),
      address: draft.address.trim(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Property> setStatus(
    String id,
    PropertyStatus status, {
    String? rejectionReason,
  }) async {
    final old = _require(id);
    final now = DateTime.now();
    return _items[id] = old.copyWith(
      status: status,
      rejectionReason: status == PropertyStatus.rejected
          ? rejectionReason
          : null,
      publishedAt: status == PropertyStatus.published ? now : old.publishedAt,
      updatedAt: now,
    );
  }

  @override
  Future<Property> reassign(String id, String agentId) async =>
      _items[id] = _require(id)
          .copyWith(agentId: agentId, updatedAt: DateTime.now());

  @override
  Future<void> delete(String id) async {
    _require(id);
    _items.remove(id);
  }
}

Property _seedProperty({
  required String id,
  required String title,
  required ListingType listingType,
  required PropertyType propertyType,
  required double price,
  required String city,
  required PropertyStatus status,
  required int day,
  int? bedrooms,
  int? bathrooms,
  double? areaValue,
  AreaUnit? areaUnit,
  String? rejectionReason,
}) {
  final date = DateTime.utc(2026, 10, day);
  return Property(
    id: id,
    agentId: 'u-agent',
    title: title,
    description: 'Sample listing for development.',
    listingType: listingType,
    propertyType: propertyType,
    price: price,
    currency: 'PKR',
    city: city,
    address: '',
    status: status,
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    areaValue: areaValue,
    areaUnit: areaUnit,
    rejectionReason: rejectionReason,
    publishedAt: status == PropertyStatus.published ? date : null,
    createdAt: date,
    updatedAt: date,
  );
}

List<Property> _seed() => [
  _seedProperty(
    id: 'p-1',
    title: 'Modern 5 Marla House near Canal Road',
    listingType: ListingType.sale,
    propertyType: PropertyType.house,
    price: 18500000,
    city: 'Faisalabad',
    status: PropertyStatus.published,
    day: 1,
    bedrooms: 3,
    bathrooms: 3,
    areaValue: 5,
    areaUnit: AreaUnit.marla,
  ),
  _seedProperty(
    id: 'p-2',
    title: 'Two-Bedroom Apartment in Gulberg',
    listingType: ListingType.rent,
    propertyType: PropertyType.apartment,
    price: 65000,
    city: 'Lahore',
    status: PropertyStatus.published,
    day: 2,
    bedrooms: 2,
    bathrooms: 2,
    areaValue: 1100,
    areaUnit: AreaUnit.sqft,
  ),
  _seedProperty(
    id: 'p-3',
    title: 'Ground-Floor Shop on Main Boulevard',
    listingType: ListingType.rent,
    propertyType: PropertyType.commercial,
    price: 120000,
    city: 'Faisalabad',
    status: PropertyStatus.published,
    day: 3,
    bathrooms: 1,
    areaValue: 450,
    areaUnit: AreaUnit.sqft,
  ),
  _seedProperty(
    id: 'p-4',
    title: '1 Kanal Residential Plot, Sector E',
    listingType: ListingType.sale,
    propertyType: PropertyType.plot,
    price: 42000000,
    city: 'Islamabad',
    status: PropertyStatus.published,
    day: 4,
    areaValue: 1,
    areaUnit: AreaUnit.kanal,
  ),
  _seedProperty(
    id: 'p-5',
    title: '10 Marla Family House with Garden',
    listingType: ListingType.sale,
    propertyType: PropertyType.house,
    price: 65000000,
    city: 'Lahore',
    status: PropertyStatus.published,
    day: 5,
    bedrooms: 5,
    bathrooms: 4,
    areaValue: 10,
    areaUnit: AreaUnit.marla,
  ),
  _seedProperty(
    id: 'p-6',
    title: 'Furnished Room for Working Professional',
    listingType: ListingType.rent,
    propertyType: PropertyType.room,
    price: 25000,
    city: 'Faisalabad',
    status: PropertyStatus.published,
    day: 6,
    bedrooms: 1,
    bathrooms: 1,
  ),
  _seedProperty(
    id: 'p-7',
    title: 'Draft: 3 Marla House in Samanabad',
    listingType: ListingType.sale,
    propertyType: PropertyType.house,
    price: 9500000,
    city: 'Faisalabad',
    status: PropertyStatus.draft,
    day: 7,
  ),
  _seedProperty(
    id: 'p-8',
    title: 'Pending: Office Space in Model Town',
    listingType: ListingType.rent,
    propertyType: PropertyType.commercial,
    price: 90000,
    city: 'Lahore',
    status: PropertyStatus.pendingReview,
    day: 8,
  ),
  _seedProperty(
    id: 'p-9',
    title: 'Rejected: Duplicate Listing Test',
    listingType: ListingType.rent,
    propertyType: PropertyType.house,
    price: 40000,
    city: 'Lahore',
    status: PropertyStatus.rejected,
    day: 9,
    rejectionReason: 'Duplicate of an existing listing',
  ),
];
