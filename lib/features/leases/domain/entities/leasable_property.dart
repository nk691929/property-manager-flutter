import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/core/money/money.dart';

part 'leasable_property.freezed.dart';

/// A rental listing that can take a new lease (small projection for the form).
@freezed
abstract class LeasableProperty with _$LeasableProperty {
  const factory({
    required String id,
    required String title,
    required String city,

    /// The listing price: monthly rent for a rental.
    required Money monthlyRent,
  }) = _LeasableProperty;
}
