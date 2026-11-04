import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_enums.dart';

part 'inquiry.freezed.dart';

@freezed
abstract class Inquiry with _$Inquiry {
  const factory({
    required String id,
    required String propertyId,
    required String propertyTitle,
    required String clientId,
    required InquiryStatus status,
    required DateTime lastMessageAt,
    required String lastMessagePreview,
    required DateTime createdAt,

    /// The listing's CURRENT agent, read from the property when the inquiry is
    /// loaded (not stored on the inquiry). Null if the property is hidden.
    String? agentId,
    String? lastSenderId,
  }) = _Inquiry;
  const new _();

  bool get isOpen => status == InquiryStatus.open;
}
