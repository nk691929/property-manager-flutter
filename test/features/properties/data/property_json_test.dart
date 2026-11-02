import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/properties/data/property_json.dart';

void main() {
  Map<String, dynamic> row({Object? photos}) => {
    'id': 'p-1',
    'agent_id': 'u-agent',
    'title': 'A listing title',
    'description': '',
    'listing_type': 'rent',
    'property_type': 'house',
    'price': '65000.00', // numeric can arrive as text
    'currency': 'PKR',
    'bedrooms': null,
    'bathrooms': null,
    'area_value': null,
    'area_unit': null,
    'city': 'Lahore',
    'address': '',
    'status': 'published',
    'rejection_reason': null,
    'published_at': '2026-11-01T10:00:00Z',
    'created_at': '2026-11-01T09:00:00Z',
    'updated_at': '2026-11-01T09:30:00Z',
    'property_photos': ?photos,
  };

  test('embedded photos are sorted by position and get public URLs', () {
    final property = propertyFromJson(
      row(
        photos: [
          {'id': 'b', 'storage_path': 'p-1/b.jpg', 'position': 5},
          {'id': 'a', 'storage_path': 'p-1/a.jpg', 'position': -1},
        ],
      ),
      photoUrl: (path) => 'https://cdn.example/$path',
    );

    expect(property.price, 65000);
    expect(property.photos.map((p) => p.id), ['a', 'b']);
    expect(property.coverPhoto?.url, 'https://cdn.example/p-1/a.jpg');
  });

  test('a row without photos has an empty list and no cover', () {
    final property = propertyFromJson(row());
    expect(property.photos, isEmpty);
    expect(property.coverPhoto, isNull);
  });
}
