import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/leases/data/datasources/fake_leases_data_source.dart';
import 'package:property_manager/features/leases/data/repositories/leases_repository_impl.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/usecases/create_lease.dart';
import 'package:property_manager/features/leases/domain/usecases/get_lease.dart';
import 'package:property_manager/features/leases/domain/usecases/list_leasable_properties.dart';
import 'package:property_manager/features/leases/domain/usecases/list_my_leases.dart';
import 'package:property_manager/features/leases/domain/usecases/list_tenant_candidates.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';

import '../../../helpers/lease_test_helpers.dart';
import '../../../helpers/property_test_helpers.dart';

void main() {
  const otherClient = AppUser(
    id: 'u-client-2',
    email: 'c2@x.com',
    role: Role.client,
  );

  late LeasesRepositoryImpl repo;

  setUp(() {
    repo = LeasesRepositoryImpl(
      FakeLeasesDataSource(
        properties: FakePropertiesDataSource.seeded(),
        candidates: const {
          'p-2': {'u-client'},
          'p-3': {'u-client'},
        },
      ),
    );
  });

  Future<Lease> createAs(AppUser user, {String property = 'p-2'}) async {
    final result = await CreateLease(repo, () => user)(
      sampleNewLease(propertyId: property),
    );
    return result.valueOrNull!;
  }

  Future<int> leaseCount(AppUser user) async =>
      (await ListMyLeases(repo, () => user)()).valueOrNull?.length ?? -1;

  group('CreateLease', () {
    test('an agent creates a lease with its whole rent schedule', () async {
      final lease = await createAs(agentUser);

      expect(lease.status, LeaseStatus.active);
      expect(lease.tenantId, 'u-client');
      expect(lease.agentId, 'u-agent');
      expect(lease.propertyTitle, 'Two-Bedroom Apartment in Gulberg');
      expect(lease.charges, hasLength(11));
      expect(lease.charges.first.dueDate, DateTime(2027));
      expect(lease.charges.last.dueDate, DateTime(2027, 11));
      expect(
        Money.sum(lease.charges.map((c) => c.amount), currency: 'PKR'),
        pkr(550000),
      );
    });

    test(
      'clients are forbidden and signed-out users are unauthorized',
      () async {
        final asClient = await CreateLease(repo, () => clientUser)(
          sampleNewLease(),
        );
        final signedOut = await CreateLease(repo, () => null)(sampleNewLease());
        expect(asClient.failureOrNull, isA<ForbiddenFailure>());
        expect(signedOut.failureOrNull, isA<UnauthorizedFailure>());
      },
    );

    test('invalid input never reaches the repository', () async {
      final result = await CreateLease(repo, () => agentUser)(
        sampleNewLease(rent: const Money.zero(), dueDay: 31),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await leaseCount(agentUser), 0);
    });

    test('only a client who contacted the agent can be a tenant', () async {
      final result = await CreateLease(repo, () => agentUser)(
        sampleNewLease(tenantId: 'u-client-2'),
      );
      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });

    test('a sale listing cannot be leased', () async {
      final result = await CreateLease(repo, () => agentUser)(
        sampleNewLease(propertyId: 'p-1'),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('a draft listing cannot be leased', () async {
      final result = await CreateLease(repo, () => agentUser)(
        sampleNewLease(propertyId: 'p-7'),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('only one active lease per listing', () async {
      await createAs(agentUser);
      final second = await CreateLease(repo, () => agentUser)(sampleNewLease());
      expect(second.failureOrNull, isA<ConflictFailure>());

      await createAs(agentUser, property: 'p-3'); // another listing is fine
    });
  });

  group('reading leases', () {
    test('each side sees only their own leases', () async {
      await createAs(agentUser);

      expect(await leaseCount(clientUser), 1);
      expect(await leaseCount(agentUser), 1);
      expect(await leaseCount(otherClient), 0);
      expect(await leaseCount(otherAgent), 0);

      final asAdmin = await ListMyLeases(repo, () => adminUser)();
      expect(asAdmin.failureOrNull, isA<ForbiddenFailure>());
    });

    test('only the tenant and the listing agent can open a lease', () async {
      final lease = await createAs(agentUser);

      for (final party in [clientUser, agentUser]) {
        final result = await GetLease(repo, () => party)(lease.id);
        expect(result.isOk, isTrue, reason: party.id);
      }
      for (final outsider in [otherClient, otherAgent, adminUser]) {
        final result = await GetLease(repo, () => outsider)(lease.id);
        expect(
          result.failureOrNull,
          isA<ForbiddenFailure>(),
          reason: outsider.id,
        );
      }
      final signedOut = await GetLease(repo, () => null)(lease.id);
      expect(signedOut.failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('the creation form helpers', () {
    test('tenant candidates are for agents only', () async {
      final asAgent = await ListTenantCandidates(repo, () => agentUser)('p-2');
      final asClient = await ListTenantCandidates(repo, () => clientUser)(
        'p-2',
      );
      final none = await ListTenantCandidates(repo, () => agentUser)('p-6');

      expect(asAgent.valueOrNull, ['u-client']);
      expect(asClient.failureOrNull, isA<ForbiddenFailure>());
      expect(none.valueOrNull, isEmpty);
    });

    test('leasable listings are rentals without an active lease', () async {
      Future<Set<String>> ids(AppUser user) async {
        final result = await ListLeasableProperties(repo, () => user)();

        final properties = result.valueOrNull ?? [];

        return <String>{for (final p in properties) p.id};
      }

      expect(await ids(agentUser), {'p-2', 'p-3', 'p-6'});
      expect(await ids(otherAgent), isEmpty);

      await createAs(agentUser);
      expect(await ids(agentUser), {'p-3', 'p-6'});

      final asClient = await ListLeasableProperties(repo, () => clientUser)();
      expect(asClient.failureOrNull, isA<ForbiddenFailure>());
    });

    test('the listing price becomes the suggested monthly rent', () async {
      final result = await ListLeasableProperties(repo, () => agentUser)();
      final apartment = result.valueOrNull!.firstWhere((p) => p.id == 'p-2');
      expect(apartment.monthlyRent, pkr(65000));
    });
  });
}
