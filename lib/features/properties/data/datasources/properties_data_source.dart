import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';

/// Backend seam. Implementations throw typed `Failure`s, never SDK exceptions.
abstract interface class PropertiesDataSource {
  Future<List<Property>> search(
    PropertyFilter filter, {
    required int offset,
    required int limit,
  });

  Future<List<Property>> listByAgent(
    String agentId, {
    required int offset,
    required int limit,
    PropertyStatus? status,
  });

  Future<List<Property>> listAll({
    required int offset,
    required int limit,
    PropertyStatus? status,
  });

  Future<Property> getById(String id);

  Future<Property> create(PropertyDraft draft, String agentId);

  Future<Property> update(String id, PropertyDraft draft);

  Future<Property> setStatus(
    String id,
    PropertyStatus status, {
    String? rejectionReason,
  });

  Future<Property> reassign(String id, String agentId);

  Future<void> delete(String id);
}
