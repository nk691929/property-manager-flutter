import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';

/// Backend seam. Implementations throw typed `Failure`s, never SDK exceptions.
abstract interface class InquiriesDataSource {
  Future<List<Inquiry>> listForClient(
    String clientId, {
    required int offset,
    required int limit,
  });

  Future<List<Inquiry>> listForAgent(
    String agentId, {
    required int offset,
    required int limit,
  });

  Future<Inquiry> getById(String id);

  Future<Inquiry?> findOpen(String clientId, String propertyId);

  Future<List<InquiryMessage>> messages(String inquiryId);

  Future<Inquiry> start({
    required String propertyId,
    required String clientId,
    required String body,
  });

  Future<InquiryMessage> send(
    String inquiryId, {
    required String senderId,
    required String body,
  });

  Future<Inquiry> close(String inquiryId);
}
