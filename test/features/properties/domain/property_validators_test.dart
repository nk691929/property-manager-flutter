import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/rules/property_validators.dart';

import '../../../helpers/property_test_helpers.dart';

void main() {
  test('title', () {
    expect(PropertyValidators.title(''), PropertyFieldError.empty);
    expect(PropertyValidators.title('abcd'), PropertyFieldError.titleLength);
    expect(PropertyValidators.title('A fine title'), isNull);
  });

  test('price must be positive and finite', () {
    expect(PropertyValidators.price(null), PropertyFieldError.priceInvalid);
    expect(PropertyValidators.price(0), PropertyFieldError.priceInvalid);
    expect(PropertyValidators.price(-5), PropertyFieldError.priceInvalid);
    expect(
      PropertyValidators.price(double.nan),
      PropertyFieldError.priceInvalid,
    );
    expect(PropertyValidators.price(65000), isNull);
  });

  test('area and unit go together', () {
    expect(PropertyValidators.area(null, null), isNull);
    expect(PropertyValidators.area(5, null), PropertyFieldError.areaIncomplete);
    expect(
      PropertyValidators.area(null, AreaUnit.marla),
      PropertyFieldError.areaIncomplete,
    );
    expect(
      PropertyValidators.area(0, AreaUnit.marla),
      PropertyFieldError.areaInvalid,
    );
    expect(PropertyValidators.area(5, AreaUnit.marla), isNull);
  });

  test('count is 0..50', () {
    expect(PropertyValidators.count(-1), PropertyFieldError.countInvalid);
    expect(PropertyValidators.count(51), PropertyFieldError.countInvalid);
    expect(PropertyValidators.count(3), isNull);
  });

  test('validateDraft collects every problem', () {
    final errors = PropertyValidators.validateDraft(
      validDraft.copyWith(title: 'x', price: 0, city: ''),
    );
    expect(errors.keys, containsAll(['title', 'price', 'city']));
    expect(PropertyValidators.validateDraft(validDraft), isEmpty);
  });
}
