import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';

abstract interface class ViewingsRepository {
  Future<Result<List<Viewing>>> listForClient(
    String clientId, {
    required int limit,
  });

  /// Viewings at listings this agent currently owns.
  Future<Result<List<Viewing>>> listForAgent(
    String agentId, {
    required int limit,
  });

  Future<Result<Viewing>> getById(String id);

  /// The client's requested or confirmed viewing for a listing, or `Ok(null)`.
  Future<Result<Viewing?>> findActive(String clientId, String propertyId);

  Future<Result<Viewing>> request({
    required String propertyId,
    required String clientId,
    required DateTime scheduledAt,
  });

  Future<Result<Viewing>> setStatus(
    String id,
    ViewingStatus status, {
    String? declineReason,
  });
}
