import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';

part 'property.freezed.dart';

@freezed
abstract class Property with _$Property {
  const factory({
    required String id,
    required String agentId,
    required String title,
    required String description,
    required ListingType listingType,
    required PropertyType propertyType,
    required double price,
    required String currency,
    required String city,
    required String address,
    required PropertyStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? bedrooms,
    int? bathrooms,
    double? areaValue,
    AreaUnit? areaUnit,
    String? rejectionReason,
    DateTime? publishedAt,
  }) = _Property;
  const new _();

  bool get isRent => listingType == ListingType.rent;
}
