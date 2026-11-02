import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/providers/supabase_provider.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/platform_settings/presentation/providers/platform_settings_providers.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';
import 'package:property_manager/features/properties/data/datasources/properties_data_source.dart';
import 'package:property_manager/features/properties/data/datasources/supabase_properties_data_source.dart';
import 'package:property_manager/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';
import 'package:property_manager/features/properties/domain/usecases/change_property_status.dart';
import 'package:property_manager/features/properties/domain/usecases/create_property.dart';
import 'package:property_manager/features/properties/domain/usecases/delete_property.dart';
import 'package:property_manager/features/properties/domain/usecases/get_property.dart';
import 'package:property_manager/features/properties/domain/usecases/list_all_properties.dart';
import 'package:property_manager/features/properties/domain/usecases/list_my_properties.dart';
import 'package:property_manager/features/properties/domain/usecases/reassign_property.dart';
import 'package:property_manager/features/properties/domain/usecases/search_properties.dart';
import 'package:property_manager/features/properties/domain/usecases/update_property.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'properties_providers.g.dart';

// Composition root for properties (the one place allowed to see data/).

@Riverpod(keepAlive: true)
PropertiesDataSource propertiesDataSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasBackendConfig
      ? SupabasePropertiesDataSource(ref.watch(supabaseClientProvider))
      : FakePropertiesDataSource.seeded();
}

@Riverpod(keepAlive: true)
PropertiesRepository propertiesRepository(Ref ref) =>
    PropertiesRepositoryImpl(ref.watch(propertiesDataSourceProvider));

@riverpod
SearchProperties searchProperties(Ref ref) => SearchProperties(
  ref.watch(propertiesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
GetProperty getProperty(Ref ref) => GetProperty(
  ref.watch(propertiesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ListMyProperties listMyProperties(Ref ref) => ListMyProperties(
  ref.watch(propertiesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ListAllProperties listAllProperties(Ref ref) => ListAllProperties(
  ref.watch(propertiesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
CreateProperty createProperty(Ref ref) => CreateProperty(
  ref.watch(propertiesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
UpdateProperty updateProperty(Ref ref) => UpdateProperty(
  ref.watch(propertiesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ChangePropertyStatus changePropertyStatus(Ref ref) => ChangePropertyStatus(
  ref.watch(propertiesRepositoryProvider),
  ref.watch(platformSettingsRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
DeleteProperty deleteProperty(Ref ref) => DeleteProperty(
  ref.watch(propertiesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ReassignProperty reassignProperty(Ref ref) => ReassignProperty(
  ref.watch(propertiesRepositoryProvider),
  () => ref.read(currentUserProvider),
);
