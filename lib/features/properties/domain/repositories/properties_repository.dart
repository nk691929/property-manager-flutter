import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';

abstract interface class PropertiesRepository {
  Future<Result<List<Property>>> searchPublished(
    PropertyFilter filter, {
    required int offset,
    required int limit,
  });

  Future<Result<List<Property>>> listByAgent(
    String agentId, {
    required int offset,
    required int limit,
    PropertyStatus? status,
  });

  Future<Result<List<Property>>> listAll({
    required int offset,
    required int limit,
    PropertyStatus? status,
  });

  Future<Result<Property>> getById(String id);

  Future<Result<Property>> create(
    PropertyDraft draft, {
    required String agentId,
  });

  Future<Result<Property>> update(String id, PropertyDraft draft);

  Future<Result<Property>> setStatus(
    String id,
    PropertyStatus status, {
    String? rejectionReason,
  });

  Future<Result<Property>> reassign(String id, String agentId);

  Future<Result<void>> delete(String id);
}
