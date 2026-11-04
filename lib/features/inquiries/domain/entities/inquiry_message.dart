import 'package:freezed_annotation/freezed_annotation.dart';

part 'inquiry_message.freezed.dart';

@freezed
abstract class InquiryMessage with _$InquiryMessage {
  const factory({
    required String id,
    required String inquiryId,
    required String senderId,
    required String body,
    required DateTime createdAt,
  }) = _InquiryMessage;
}
