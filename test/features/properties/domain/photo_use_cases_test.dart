import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';
import 'package:property_manager/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';
import 'package:property_manager/features/properties/domain/rules/photo_rules.dart';
import 'package:property_manager/features/properties/domain/usecases/add_property_photo.dart';
import 'package:property_manager/features/properties/domain/usecases/remove_property_photo.dart';
import 'package:property_manager/features/properties/domain/usecases/set_cover_photo.dart';

import '../../../helpers/property_test_helpers.dart';

void main() {
  late FakePhotosRepository photos;

  setUp(() => photos = FakePhotosRepository());

  PropertiesRepository repoWith(Property property) => PropertiesRepositoryImpl(
    FakePropertiesDataSource(properties: [property]),
  );

  final twoPhotos = [samplePhoto('a', 0), samplePhoto('b', 1)];

  String? photoCode(Result<Object?> result) {
    final failure = result.failureOrNull;
    return failure is ValidationFailure ? failure.fieldErrors['photo'] : null;
  }

  group('AddPropertyPhoto', () {
    AddPropertyPhoto useCase(AppUser? actor, Property property) =>
        AddPropertyPhoto(repoWith(property), photos, () => actor);

    test('owner adds to a draft at the next position', () async {
      final result = await useCase(
        agentUser,
        sampleProperty(photos: twoPhotos),
      )('p-x', jpegUpload());
      expect(result.isOk, isTrue);
      expect(photos.calls, ['add:2']);
    });

    test('owner cannot change photos once the listing is published', () async {
      final result = await useCase(
        agentUser,
        sampleProperty(status: PropertyStatus.published),
      )('p-x', jpegUpload());
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(photos.calls, isEmpty);
    });

    test('admin may manage photos at any status', () async {
      final result = await useCase(
        adminUser,
        sampleProperty(status: PropertyStatus.published),
      )('p-x', jpegUpload());
      expect(result.isOk, isTrue);
    });

    test("another agent cannot touch someone else's listing", () async {
      final result = await useCase(otherAgent, sampleProperty())(
        'p-x',
        jpegUpload(),
      );
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(photos.calls, isEmpty);
    });

    test('client is forbidden and signed-out is unauthorized', () async {
      final asClient = await useCase(clientUser, sampleProperty())(
        'p-x',
        jpegUpload(),
      );
      final signedOut = await useCase(null, sampleProperty())(
        'p-x',
        jpegUpload(),
      );
      expect(asClient.failureOrNull, isA<ForbiddenFailure>());
      expect(signedOut.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('enforces the limits before touching storage', () async {
      final full = sampleProperty(
        photos: List.generate(10, (i) => samplePhoto('p$i', i)),
      );
      expect(
        photoCode(await useCase(agentUser, full)('p-x', jpegUpload())),
        'tooMany',
      );
      expect(
        photoCode(
          await useCase(agentUser, sampleProperty())(
            'p-x',
            jpegUpload(PhotoRules.maxBytes + 1),
          ),
        ),
        'tooLarge',
      );
      expect(
        photoCode(
          await useCase(agentUser, sampleProperty())(
            'p-x',
            PhotoUpload(bytes: Uint8List(10), extension: 'gif'),
          ),
        ),
        'unsupportedType',
      );
      expect(photos.calls, isEmpty);
    });
  });

  group('RemovePropertyPhoto', () {
    RemovePropertyPhoto useCase(AppUser? actor, Property property) =>
        RemovePropertyPhoto(repoWith(property), photos, () => actor);

    test('owner removes an existing photo', () async {
      final result = await useCase(
        agentUser,
        sampleProperty(photos: twoPhotos),
      )('p-x', 'a');
      expect(result.isOk, isTrue);
      expect(photos.calls, ['remove:a']);
    });

    test('unknown photo is NotFound', () async {
      final result = await useCase(
        agentUser,
        sampleProperty(photos: twoPhotos),
      )('p-x', 'zzz');
      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(photos.calls, isEmpty);
    });
  });

  group('SetCoverPhoto', () {
    SetCoverPhoto useCase(AppUser? actor, Property property) =>
        SetCoverPhoto(repoWith(property), photos, () => actor);

    test('moves the chosen photo in front of the first one', () async {
      final result = await useCase(
        agentUser,
        sampleProperty(photos: twoPhotos),
      )('p-x', 'b');
      expect(result.isOk, isTrue);
      expect(photos.calls, ['setPosition:-1']);
    });

    test('choosing the current cover changes nothing', () async {
      final result = await useCase(
        agentUser,
        sampleProperty(photos: twoPhotos),
      )('p-x', 'a');
      expect(result.isOk, isTrue);
      expect(photos.calls, isEmpty);
    });
  });
}
