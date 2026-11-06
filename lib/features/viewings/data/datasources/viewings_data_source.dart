import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';

/// Backend seam. Implementations throw typed `Failure`s, never SDK exceptions.
abstract interface class ViewingsDataSource {
  Future<List<Viewing>> listForClient(String clientId, {required int limit});

  Future<List<Viewing>> listForAgent(String agentId, {required int limit});

  Future<Viewing> getById(String id);

  Future<Viewing?> findActive(String clientId, String propertyId);

  Future<Viewing> request({
    required String propertyId,
    required String clientId,
    required DateTime scheduledAt,
  });

  Future<Viewing> setStatus(
    String id,
    ViewingStatus status, {
    String? declineReason,
  });
}
