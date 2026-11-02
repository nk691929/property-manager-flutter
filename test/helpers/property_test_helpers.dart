import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/platform_settings/domain/entities/platform_settings.dart';
import 'package:property_manager/features/platform_settings/domain/repositories/platform_settings_repository.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';

// Matches the fake seed: p-7 (draft), p-8 (pending) belong to 'u-agent'.
const agentUser = AppUser(id: 'u-agent', email: 'a@x.com', role: Role.agent);
const otherAgent = AppUser(id: 'u-agent-2', email: 'b@x.com', role: Role.agent);
const adminUser = AppUser(id: 'u-admin', email: 'ad@x.com', role: Role.admin);
const clientUser = AppUser(id: 'u-client', email: 'c@x.com', role: Role.client);

const validDraft = PropertyDraft(
  title: 'Valid listing title',
  listingType: ListingType.rent,
  propertyType: PropertyType.house,
  price: 50000,
  city: 'Faisalabad',
);

/// Delegates to a real repository and records which methods were called, so
/// tests can assert "the repository was never touched".
final class RecordingPropertiesRepository implements PropertiesRepository {
  new(this._inner);

  final PropertiesRepository _inner;
  final List<String> calls = [];

  @override
  Future<Result<List<Property>>> searchPublished(
    PropertyFilter filter, {
    required int offset,
    required int limit,
  }) {
    calls.add('searchPublished');
    return _inner.searchPublished(filter, offset: offset, limit: limit);
  }

  @override
  Future<Result<List<Property>>> listByAgent(
    String agentId, {
    required int offset,
    required int limit,
    PropertyStatus? status,
  }) {
    calls.add('listByAgent');
    return _inner.listByAgent(
      agentId,
      offset: offset,
      limit: limit,
      status: status,
    );
  }

  @override
  Future<Result<List<Property>>> listAll({
    required int offset,
    required int limit,
    PropertyStatus? status,
  }) {
    calls.add('listAll');
    return _inner.listAll(offset: offset, limit: limit, status: status);
  }

  @override
  Future<Result<Property>> getById(String id) {
    calls.add('getById');
    return _inner.getById(id);
  }

  @override
  Future<Result<Property>> create(
    PropertyDraft draft, {
    required String agentId,
  }) {
    calls.add('create');
    return _inner.create(draft, agentId: agentId);
  }

  @override
  Future<Result<Property>> update(String id, PropertyDraft draft) {
    calls.add('update');
    return _inner.update(id, draft);
  }

  @override
  Future<Result<Property>> setStatus(
    String id,
    PropertyStatus status, {
    String? rejectionReason,
  }) {
    calls.add('setStatus');
    return _inner.setStatus(id, status, rejectionReason: rejectionReason);
  }

  @override
  Future<Result<Property>> reassign(String id, String agentId) {
    calls.add('reassign');
    return _inner.reassign(id, agentId);
  }

  @override
  Future<Result<void>> delete(String id) {
    calls.add('delete');
    return _inner.delete(id);
  }
}

final class FakeSettingsRepository implements PlatformSettingsRepository {
  new({this.requireApproval = true});

  bool requireApproval;

  @override
  Future<Result<PlatformSettings>> get() async =>
      Ok(PlatformSettings(requireListingApproval: requireApproval));

  @override
  Future<Result<PlatformSettings>> setRequireListingApproval({
    required bool value,
  }) async {
    requireApproval = value;
    return await get();
  }
}
