import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';

abstract interface class InquiriesRepository {
  Future<Result<List<Inquiry>>> listForClient(
    String clientId, {
    required int offset,
    required int limit,
  });

  /// Conversations about listings this agent currently owns.
  Future<Result<List<Inquiry>>> listForAgent(
    String agentId, {
    required int offset,
    required int limit,
  });

  Future<Result<Inquiry>> getById(String id);

  /// The client's open conversation about a listing, or `Ok(null)`.
  Future<Result<Inquiry?>> findOpen(String clientId, String propertyId);

  Future<Result<List<InquiryMessage>>> messages(String inquiryId);

  /// Creates the inquiry and its first message together. The backend decides
  /// who the client is (from the session); [clientId] is for offline demo mode.
  Future<Result<Inquiry>> start({
    required String propertyId,
    required String clientId,
    required String body,
  });

  Future<Result<InquiryMessage>> send(
    String inquiryId, {
    required String senderId,
    required String body,
  });

  Future<Result<Inquiry>> close(String inquiryId);
}
