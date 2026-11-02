import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';

double _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.parse(s),
  _ => throw FormatException('Not a number: $value'),
};

double? _toDoubleOrNull(Object? value) =>
    value == null ? null : _toDouble(value);

DateTime? _toDateOrNull(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// Row of `public.properties` -> entity.
Property propertyFromJson(Map<String, dynamic> json) => Property(
  id: json['id'] as String,
  agentId: json['agent_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  listingType: ListingType.fromWire(json['listing_type'] as String),
  propertyType: PropertyType.fromWire(json['property_type'] as String),
  price: _toDouble(json['price']),
  currency: json['currency'] as String? ?? 'PKR',
  bedrooms: json['bedrooms'] as int?,
  bathrooms: json['bathrooms'] as int?,
  areaValue: _toDoubleOrNull(json['area_value']),
  areaUnit: json['area_unit'] == null
      ? null
      : AreaUnit.fromWire(json['area_unit'] as String),
  city: json['city'] as String,
  address: json['address'] as String? ?? '',
  status: PropertyStatus.fromWire(json['status'] as String),
  rejectionReason: json['rejection_reason'] as String?,
  publishedAt: _toDateOrNull(json['published_at']),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

/// Writable columns only. Nulls are sent on purpose so a field can be cleared.
Map<String, dynamic> draftToJson(PropertyDraft d) => {
  'title': d.title.trim(),
  'description': d.description.trim(),
  'listing_type': d.listingType.wireName,
  'property_type': d.propertyType.wireName,
  'price': d.price,
  'currency': d.currency,
  'bedrooms': d.bedrooms,
  'bathrooms': d.bathrooms,
  'area_value': d.areaValue,
  'area_unit': d.areaUnit?.wireName,
  'city': d.city.trim(),
  'address': d.address.trim(),
};
