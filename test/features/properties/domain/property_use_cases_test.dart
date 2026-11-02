import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';
import 'package:property_manager/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/usecases/change_property_status.dart';
import 'package:property_manager/features/properties/domain/usecases/create_property.dart';
import 'package:property_manager/features/properties/domain/usecases/delete_property.dart';
import 'package:property_manager/features/properties/domain/usecases/update_property.dart';

import '../../../helpers/property_test_helpers.dart';

void main() {
  late RecordingPropertiesRepository repo;
  late FakeSettingsRepository settings;

  setUp(() {
    repo = RecordingPropertiesRepository(
      PropertiesRepositoryImpl(FakePropertiesDataSource.seeded()),
    );
    settings = FakeSettingsRepository();
  });

  ChangePropertyStatus change(AppUser? actor) =>
      ChangePropertyStatus(repo, settings, () => actor);

  group('ChangePropertyStatus', () {
    test('owner submits a draft for review', () async {
      final result = await change(agentUser)(
        propertyId: 'p-7',
        to: PropertyStatus.pendingReview,
      );
      expect(result.valueOrNull?.status, PropertyStatus.pendingReview);
    });

    test('owner cannot publish directly while approval is required', () async {
      final result = await change(agentUser)(
        propertyId: 'p-7',
        to: PropertyStatus.published,
      );
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(repo.calls, isNot(contains('setStatus')));
    });

    test('owner can publish directly when approval is off', () async {
      settings.requireApproval = false;
      final result = await change(agentUser)(
        propertyId: 'p-7',
        to: PropertyStatus.published,
      );
      expect(result.valueOrNull?.status, PropertyStatus.published);
    });

    test("another agent cannot touch someone else's listing", () async {
      final result = await change(otherAgent)(
        propertyId: 'p-7',
        to: PropertyStatus.pendingReview,
      );
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(repo.calls, isNot(contains('setStatus')));
    });

    test('client is forbidden and signed-out is unauthorized', () async {
      final asClient = await change(clientUser)(
        propertyId: 'p-7',
        to: PropertyStatus.pendingReview,
      );
      final signedOut = await change(null)(
        propertyId: 'p-7',
        to: PropertyStatus.pendingReview,
      );
      expect(asClient.failureOrNull, isA<ForbiddenFailure>());
      expect(signedOut.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('admin approves a pending listing', () async {
      final result = await change(adminUser)(
        propertyId: 'p-8',
        to: PropertyStatus.published,
      );
      expect(result.valueOrNull?.status, PropertyStatus.published);
      expect(result.valueOrNull?.publishedAt, isNotNull);
    });

    test('rejecting needs a reason, and stores it', () async {
      final without = await change(adminUser)(
        propertyId: 'p-8',
        to: PropertyStatus.rejected,
        rejectionReason: '  ',
      );
      expect(without.failureOrNull, isA<ValidationFailure>());

      final withReason = await change(adminUser)(
        propertyId: 'p-8',
        to: PropertyStatus.rejected,
        rejectionReason: 'Photos missing',
      );
      expect(withReason.valueOrNull?.rejectionReason, 'Photos missing');
    });
  });

  group('CreateProperty', () {
    test('client cannot create', () async {
      final result = await CreateProperty(repo, () => clientUser)(validDraft);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(repo.calls, isEmpty);
    });

    test('invalid input never reaches the repository', () async {
      final result = await CreateProperty(repo, () => agentUser)(
        validDraft.copyWith(title: 'x', price: -1),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repo.calls, isEmpty);
    });

    test('agent creates a draft they own', () async {
      final result = await CreateProperty(repo, () => agentUser)(validDraft);
      final created = result.valueOrNull;
      expect(created?.status, PropertyStatus.draft);
      expect(created?.agentId, 'u-agent');
    });
  });

  group('UpdateProperty', () {
    test('owner can edit a draft', () async {
      final result = await UpdateProperty(repo, () => agentUser)(
        'p-7',
        validDraft.copyWith(title: 'Renamed draft listing'),
      );
      expect(result.valueOrNull?.title, 'Renamed draft listing');
    });

    test('owner cannot edit a published listing', () async {
      final result = await UpdateProperty(repo, () => agentUser)(
        'p-1',
        validDraft,
      );
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(repo.calls, isNot(contains('update')));
    });
  });

  group('DeleteProperty', () {
    test('drafts can be deleted by their owner', () async {
      final result = await DeleteProperty(repo, () => agentUser)('p-7');
      expect(result.isOk, isTrue);
    });

    test('non-drafts cannot be deleted', () async {
      final result = await DeleteProperty(repo, () => agentUser)('p-1');
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(repo.calls, isNot(contains('delete')));
    });
  });
}
