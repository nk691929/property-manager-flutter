import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/providers/supabase_provider.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/leases/data/datasources/fake_leases_data_source.dart';
import 'package:property_manager/features/leases/data/datasources/leases_data_source.dart';
import 'package:property_manager/features/leases/data/datasources/supabase_leases_data_source.dart';
import 'package:property_manager/features/leases/data/repositories/leases_repository_impl.dart';
import 'package:property_manager/features/leases/domain/entities/leasable_property.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';
import 'package:property_manager/features/leases/domain/usecases/create_lease.dart';
import 'package:property_manager/features/leases/domain/usecases/get_lease.dart';
import 'package:property_manager/features/leases/domain/usecases/list_leasable_properties.dart';
import 'package:property_manager/features/leases/domain/usecases/list_my_leases.dart';
import 'package:property_manager/features/leases/domain/usecases/list_tenant_candidates.dart';
import 'package:property_manager/features/properties/presentation/providers/properties_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'leases_providers.g.dart';

// Composition root for leases (allowed to see data/).

@Riverpod(keepAlive: true)
LeasesDataSource leasesDataSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasBackendConfig
      ? SupabaseLeasesDataSource(ref.watch(supabaseClientProvider))
      : FakeLeasesDataSource(
          properties: ref.watch(propertiesDataSourceProvider),
          // Offline demo: the fake client has contacted the agent about the
          // seeded rental listings.
          candidates: const {
            'p-2': {'u-client'},
            'p-3': {'u-client'},
            'p-6': {'u-client'},
          },
        );
}

@Riverpod(keepAlive: true)
LeasesRepository leasesRepository(Ref ref) =>
    LeasesRepositoryImpl(ref.watch(leasesDataSourceProvider));

@riverpod
CreateLease createLease(Ref ref) => CreateLease(
  ref.watch(leasesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ListMyLeases listMyLeases(Ref ref) => ListMyLeases(
  ref.watch(leasesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
GetLease getLease(Ref ref) => GetLease(
  ref.watch(leasesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ListTenantCandidates listTenantCandidates(Ref ref) => ListTenantCandidates(
  ref.watch(leasesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ListLeasableProperties listLeasableProperties(Ref ref) =>
    ListLeasableProperties(
      ref.watch(leasesRepositoryProvider),
      () => ref.read(currentUserProvider),
    );

@riverpod
Future<List<Lease>> leaseList(Ref ref) async {
  final result = await ref.watch(listMyLeasesProvider)();
  return result.fold<List<Lease>>(
    onOk: (items) => items,
    onErr: (failure) => throw failure,
  );
}

@riverpod
Future<Lease> leaseDetail(Ref ref, String id) async {
  final result = await ref.watch(getLeaseProvider)(id);
  return result.fold<Lease>(
    onOk: (lease) => lease,
    onErr: (failure) => throw failure,
  );
}

/// Client ids the agent may create a lease for on this listing.
@riverpod
Future<List<String>> tenantCandidates(Ref ref, String propertyId) async {
  final result = await ref.watch(listTenantCandidatesProvider)(propertyId);
  return result.fold<List<String>>(
    onOk: (ids) => ids,
    onErr: (failure) => throw failure,
  );
}

@riverpod
Future<List<LeasableProperty>> leasableProperties(Ref ref) async {
  final result = await ref.watch(listLeasablePropertiesProvider)();
  return result.fold<List<LeasableProperty>>(
    onOk: (items) => items,
    onErr: (failure) => throw failure,
  );
}

/// Mutations. keepAlive so the notifier outlives the page that called it
/// (a successful create replaces its own page).
@Riverpod(keepAlive: true)
class LeaseActions extends _$LeaseActions {
  @override
  void build() {}

  Future<Result<Lease>> create(NewLease draft) async {
    final result = await ref.read(createLeaseProvider)(draft);
    if (ref.mounted && result.isOk) {
      ref
        ..invalidate(leaseListProvider)
        ..invalidate(leaseDetailProvider)
        ..invalidate(leasablePropertiesProvider);
    }
    return result;
  }
}
