import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/user_directory/data/datasources/fake_user_directory_data_source.dart';
import 'package:property_manager/features/user_directory/data/repositories/user_directory_repository_impl.dart';
import 'package:property_manager/features/user_directory/domain/usecases/get_user_names.dart';

import '../../helpers/property_test_helpers.dart';

void main() {
  const repository = UserDirectoryRepositoryImpl(FakeUserDirectoryDataSource());

  test('signed-out callers are unauthorized', () async {
    final result = await GetUserNames(repository, () => null)({'u-agent'});
    expect(result.failureOrNull, isA<UnauthorizedFailure>());
  });

  test('returns known names only; unknown ids are omitted', () async {
    final result = await GetUserNames(repository, () => clientUser)({
      'u-agent',
      'someone-else',
    });
    expect(result.valueOrNull, {'u-agent': 'Alex Agent'});
  });

  test('an empty request is a success with nothing', () async {
    final result = await GetUserNames(repository, () => clientUser)({});
    expect(result.valueOrNull, isEmpty);
  });
}
