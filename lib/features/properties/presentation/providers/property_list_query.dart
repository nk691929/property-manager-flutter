import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';

part 'property_list_query.freezed.dart';

enum PropertyScope { browse, mine, all }

/// Identity of one paged list. Value equality makes it a valid family key.
@freezed
abstract class PropertyListQuery with _$PropertyListQuery {
  const factory({
    required PropertyScope scope,
    @Default(PropertyFilter()) PropertyFilter filter,
    PropertyStatus? status,
  }) = _PropertyListQuery;
}

@freezed
abstract class PagedProperties with _$PagedProperties {
  const factory({
    @Default(<Property>[]) List<Property> items,
    @Default(true) bool hasMore,
    @Default(false) bool isLoadingMore,
    Failure? loadMoreFailure,
  }) = _PagedProperties;
}
