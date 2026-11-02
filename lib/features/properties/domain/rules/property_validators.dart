import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';

/// Codes, not messages: presentation localizes them.
enum PropertyFieldError {
  empty,
  titleLength,
  descriptionTooLong,
  cityLength,
  addressTooLong,
  priceInvalid,
  countInvalid,
  areaInvalid,
  areaIncomplete,
}

/// Mirrors the CHECK constraints in 0002_properties.sql.
abstract final class PropertyValidators {
  static PropertyFieldError? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return PropertyFieldError.empty;
    if (v.length < 5 || v.length > 120) return PropertyFieldError.titleLength;
    return null;
  }

  static PropertyFieldError? description(String? value) =>
      (value?.trim().length ?? 0) > 5000
      ? PropertyFieldError.descriptionTooLong
      : null;

  static PropertyFieldError? city(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return PropertyFieldError.empty;
    if (v.length < 2 || v.length > 80) return PropertyFieldError.cityLength;
    return null;
  }

  static PropertyFieldError? address(String? value) =>
      (value?.trim().length ?? 0) > 200
      ? PropertyFieldError.addressTooLong
      : null;

  static PropertyFieldError? price(double? value) {
    if (value == null || value.isNaN || value.isInfinite) {
      return PropertyFieldError.priceInvalid;
    }
    return value > 0 && value < 1e12 ? null : PropertyFieldError.priceInvalid;
  }

  /// For bedrooms/bathrooms. Callers skip this when the field is left empty.
  static PropertyFieldError? count(int? value) =>
      (value == null || value < 0 || value > 50)
      ? PropertyFieldError.countInvalid
      : null;

  /// Area and unit go together: both set or both empty.
  static PropertyFieldError? area(double? value, AreaUnit? unit) {
    if (value == null && unit == null) return null;
    if (value == null || unit == null) return PropertyFieldError.areaIncomplete;
    return value > 0 && value < 1e10 ? null : PropertyFieldError.areaInvalid;
  }

  static Map<String, PropertyFieldError> validateDraft(PropertyDraft d) => {
    'title': ?title(d.title),
    'description': ?description(d.description),
    'price': ?price(d.price),
    if (d.bedrooms != null && count(d.bedrooms) != null)
      'bedrooms': PropertyFieldError.countInvalid,
    if (d.bathrooms != null && count(d.bathrooms) != null)
      'bathrooms': PropertyFieldError.countInvalid,
    'area': ?area(d.areaValue, d.areaUnit),
    'city': ?city(d.city),
    'address': ?address(d.address),
  };

  static ValidationFailure? validate(PropertyDraft d) {
    final errors = validateDraft(d);
    if (errors.isEmpty) return null;
    return ValidationFailure({
      for (final e in errors.entries) e.key: e.value.name,
    });
  }
}
