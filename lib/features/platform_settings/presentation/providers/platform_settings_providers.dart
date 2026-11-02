import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/providers/supabase_provider.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/platform_settings/data/datasources/fake_platform_settings_data_source.dart';
import 'package:property_manager/features/platform_settings/data/datasources/platform_settings_data_source.dart';
import 'package:property_manager/features/platform_settings/data/datasources/supabase_platform_settings_data_source.dart';
import 'package:property_manager/features/platform_settings/data/repositories/platform_settings_repository_impl.dart';
import 'package:property_manager/features/platform_settings/domain/entities/platform_settings.dart';
import 'package:property_manager/features/platform_settings/domain/repositories/platform_settings_repository.dart';
import 'package:property_manager/features/platform_settings/domain/usecases/get_platform_settings.dart';
import 'package:property_manager/features/platform_settings/domain/usecases/set_listing_approval_required.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'platform_settings_providers.g.dart';

@Riverpod(keepAlive: true)
PlatformSettingsDataSource platformSettingsDataSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasBackendConfig
      ? SupabasePlatformSettingsDataSource(ref.watch(supabaseClientProvider))
      : FakePlatformSettingsDataSource();
}

@Riverpod(keepAlive: true)
PlatformSettingsRepository platformSettingsRepository(Ref ref) =>
    PlatformSettingsRepositoryImpl(
      ref.watch(platformSettingsDataSourceProvider),
    );

@riverpod
GetPlatformSettings getPlatformSettings(Ref ref) => GetPlatformSettings(
  ref.watch(platformSettingsRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
SetListingApprovalRequired setListingApprovalRequired(Ref ref) =>
    SetListingApprovalRequired(
      ref.watch(platformSettingsRepositoryProvider),
      () => ref.read(currentUserProvider),
    );

/// Cached for the session. The use cases always re-read from the backend before
/// enforcing a rule, so a stale value here only affects button labels.
@Riverpod(keepAlive: true)
class PlatformSettingsController extends _$PlatformSettingsController {
  @override
  Future<PlatformSettings> build() async {
    final result = await ref.watch(getPlatformSettingsProvider)();
    return result.fold<PlatformSettings>(
      onOk: (settings) => settings,
      onErr: (failure) => throw failure,
    );
  }

  Future<Failure?> setApprovalRequired({required bool value}) async {
    final result = await ref.read(setListingApprovalRequiredProvider)(
      value: value,
    );
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(value: final settings):
        state = AsyncData(settings);
        return null;
      case Err(:final failure):
        return failure;
    }
  }
}
