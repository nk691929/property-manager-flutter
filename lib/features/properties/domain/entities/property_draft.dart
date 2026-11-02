import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';

part 'property_draft.freezed.dart';

/// What an agent types into the form (no id, status or owner).
@freezed
abstract class PropertyDraft with _$PropertyDraft {
  const factory({
    required String title,
    required ListingType listingType,
    required PropertyType propertyType,
    required double price,
    required String city,
    @Default('') String description,
    @Default('PKR') String currency,
    @Default('') String address,
    int? bedrooms,
    int? bathrooms,
    double? areaValue,
    AreaUnit? areaUnit,
  }) = _PropertyDraft;
  const new _();

  factory fromProperty(Property p) => PropertyDraft(
    title: p.title,
    description: p.description,
    listingType: p.listingType,
    propertyType: p.propertyType,
    price: p.price,
    currency: p.currency,
    bedrooms: p.bedrooms,
    bathrooms: p.bathrooms,
    areaValue: p.areaValue,
    areaUnit: p.areaUnit,
    city: p.city,
    address: p.address,
  );
}
