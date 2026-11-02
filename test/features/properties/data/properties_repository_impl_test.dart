import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';
import 'package:property_manager/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';

void main() {
  late PropertiesRepositoryImpl repository;

  setUp(
    () => repository = PropertiesRepositoryImpl(
      FakePropertiesDataSource.seeded(),
    ),
  );

  Future<List<String>> ids(
    PropertyFilter filter, {
    int offset = 0,
    int limit = 20,
  }) async {
    final result = await repository.searchPublished(
      filter,
      offset: offset,
      limit: limit,
    );
    final properties = result.valueOrNull ?? <Property>[];

    return [for (final Property p in properties) p.id];
  }

  test('search only returns published listings', () async {
    final all = await ids(const PropertyFilter());
    expect(all.toSet(), {'p-1', 'p-2', 'p-3', 'p-4', 'p-5', 'p-6'});
  });

  test('text search matches title and city', () async {
    expect(await ids(const PropertyFilter(query: 'canal')), ['p-1']);
    expect((await ids(const PropertyFilter(query: 'lahore'))).toSet(), {
      'p-2',
      'p-5',
    });
  });

  test('filters combine', () async {
    expect(
      await ids(
        const PropertyFilter(
          listingType: ListingType.rent,
          minPrice: 50000,
          maxPrice: 100000,
        ),
      ),
      ['p-2'],
    );
    expect((await ids(const PropertyFilter(city: 'faisalabad'))).toSet(), {
      'p-1',
      'p-3',
      'p-6',
    });
    expect((await ids(const PropertyFilter(minBedrooms: 3))).toSet(), {
      'p-1',
      'p-5',
    });
  });

  test('sorting', () async {
    expect((await ids(const PropertyFilter())).first, 'p-6');
    expect(
      (await ids(const PropertyFilter(sort: PropertySort.priceAsc))).first,
      'p-6',
    );
    expect(
      (await ids(const PropertyFilter(sort: PropertySort.priceDesc))).first,
      'p-5',
    );
  });

  test('pagination does not overlap and ends cleanly', () async {
    final first = await ids(const PropertyFilter(), limit: 4);
    final second = await ids(const PropertyFilter(), offset: 4, limit: 4);
    expect(first, hasLength(4));
    expect(second, hasLength(2));
    expect(first.toSet().intersection(second.toSet()), isEmpty);
  });

  test('missing property is a NotFoundFailure', () async {
    final result = await repository.getById('nope');
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
