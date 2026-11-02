import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';

part 'property_filter.freezed.dart';

/// Pure description of "what the user wants". Only the data layer knows how
/// to turn this into a backend query.
@freezed
abstract class PropertyFilter with _$PropertyFilter {
  const factory({
    @Default('') String query,
    @Default('') String city,
    @Default(PropertySort.newest) PropertySort sort,
    ListingType? listingType,
    PropertyType? propertyType,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
  }) = _PropertyFilter;
  const new _();

  /// Number of active filters, excluding the search text (shown on a badge).
  int get activeCount => [
    listingType != null,
    propertyType != null,
    city.trim().isNotEmpty,
    minPrice != null,
    maxPrice != null,
    minBedrooms != null,
    sort != PropertySort.newest,
  ].where((active) => active).length;
}
