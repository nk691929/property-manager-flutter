import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/time/clock.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';
import 'package:property_manager/features/viewings/data/datasources/fake_viewings_data_source.dart';
import 'package:property_manager/features/viewings/data/repositories/viewings_repository_impl.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:property_manager/features/viewings/domain/usecases/change_viewing_status.dart';
import 'package:property_manager/features/viewings/domain/usecases/find_active_viewing.dart';
import 'package:property_manager/features/viewings/domain/usecases/list_my_viewings.dart';
import 'package:property_manager/features/viewings/domain/usecases/request_viewing.dart';
import 'package:property_manager/features/viewings/domain/viewing_board.dart';

import '../../../helpers/property_test_helpers.dart';

void main() {
  const otherClient = AppUser(
    id: 'u-client-2',
    email: 'c2@x.com',
    role: Role.client,
  );

  late ViewingsRepositoryImpl repo;
  late DateTime now;

  setUp(() {
    repo = ViewingsRepositoryImpl(
      FakeViewingsDataSource(properties: FakePropertiesDataSource.seeded()),
    );
    now = DateTime.utc(2026, 11, 3, 9);
  });

  RequestViewing requestAs(AppUser? user) =>
      RequestViewing(repo, () => user, now: () => now);

  ChangeViewingStatus changeAs(AppUser? user, {Now? at}) =>
      ChangeViewingStatus(repo, () => user, now: at ?? () => now);

  Future<Viewing> request({
    AppUser user = clientUser,
    String property = 'p-1',
    Duration ahead = const Duration(days: 2),
  }) async {
    final result = await requestAs(user)(
      propertyId: property,
      scheduledAt: now.add(ahead),
    );
    return result.valueOrNull!;
  }

  String? field(Object? failure, String key) =>
      failure is ValidationFailure ? failure.fieldErrors[key] : null;

  group('RequestViewing', () {
    test('a client requests a viewing of a published listing', () async {
      final viewing = await request();

      expect(viewing.status, ViewingStatus.requested);
      expect(viewing.agentId, 'u-agent');
      expect(viewing.propertyTitle, 'Modern 5 Marla House near Canal Road');
      expect(viewing.scheduledAt, now.add(const Duration(days: 2)));
    });

    test(
      'agents are forbidden and signed-out users are unauthorized',
      () async {
        final at = now.add(const Duration(days: 2));
        final asAgent = await requestAs(agentUser)(
          propertyId: 'p-1',
          scheduledAt: at,
        );
        final signedOut = await requestAs(null)(
          propertyId: 'p-1',
          scheduledAt: at,
        );
        expect(asAgent.failureOrNull, isA<ForbiddenFailure>());
        expect(signedOut.failureOrNull, isA<UnauthorizedFailure>());
      },
    );

    test('the time window is checked before anything is saved', () async {
      final tooSoon = await requestAs(clientUser)(
        propertyId: 'p-1',
        scheduledAt: now.add(const Duration(minutes: 30)),
      );
      final tooFar = await requestAs(clientUser)(
        propertyId: 'p-1',
        scheduledAt: now.add(const Duration(days: 91)),
      );
      expect(field(tooSoon.failureOrNull, 'time'), 'tooSoon');
      expect(field(tooFar.failureOrNull, 'time'), 'tooFar');

      final mine = await ListMyViewings(repo, () => clientUser)();
      expect(mine.valueOrNull, isEmpty);
    });

    test('the boundaries themselves are allowed', () async {
      for (final ahead in [
        const Duration(hours: 1),
        const Duration(days: 90),
      ]) {
        final result = await requestAs(clientUser)(
          propertyId: ahead.inDays == 90 ? 'p-2' : 'p-1',
          scheduledAt: now.add(ahead),
        );
        expect(result.isOk, isTrue, reason: '$ahead');
      }
    });

    test(
      'one active request per listing; allowed again after it ends',
      () async {
        final first = await request();

        final duplicate = await requestAs(clientUser)(
          propertyId: 'p-1',
          scheduledAt: now.add(const Duration(days: 3)),
        );
        expect(duplicate.failureOrNull, isA<ConflictFailure>());

        await request(property: 'p-2'); // another listing is fine

        await changeAs(clientUser)(
          viewingId: first.id,
          to: ViewingStatus.cancelled,
        );
        final again = await requestAs(clientUser)(
          propertyId: 'p-1',
          scheduledAt: now.add(const Duration(days: 3)),
        );
        expect(again.isOk, isTrue);
      },
    );

    test('a draft listing cannot be visited', () async {
      final result = await requestAs(clientUser)(
        propertyId: 'p-7',
        scheduledAt: now.add(const Duration(days: 2)),
      );
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('ChangeViewingStatus', () {
    test('the agent confirms; the client cannot', () async {
      final viewing = await request();

      final byClient = await changeAs(clientUser)(
        viewingId: viewing.id,
        to: ViewingStatus.confirmed,
      );
      expect(byClient.failureOrNull, isA<ForbiddenFailure>());

      final byAgent = await changeAs(agentUser)(
        viewingId: viewing.id,
        to: ViewingStatus.confirmed,
      );
      expect(byAgent.valueOrNull?.status, ViewingStatus.confirmed);
    });

    test('confirming after the requested time has passed is refused', () async {
      final viewing = await request();
      final result = await changeAs(
        agentUser,
        at: () => now.add(const Duration(days: 3)),
      )(viewingId: viewing.id, to: ViewingStatus.confirmed);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });

    test('declining needs a reason, and stores it', () async {
      final viewing = await request();
      final decline = changeAs(agentUser);

      final blank = await decline(
        viewingId: viewing.id,
        to: ViewingStatus.declined,
        declineReason: '   ',
      );
      final long = await decline(
        viewingId: viewing.id,
        to: ViewingStatus.declined,
        declineReason: 'a' * 301,
      );
      expect(field(blank.failureOrNull, 'reason'), 'reasonEmpty');
      expect(field(long.failureOrNull, 'reason'), 'reasonTooLong');

      final ok = await decline(
        viewingId: viewing.id,
        to: ViewingStatus.declined,
        declineReason: ' Already rented out ',
      );
      expect(ok.valueOrNull?.status, ViewingStatus.declined);
      expect(ok.valueOrNull?.declineReason, 'Already rented out');
    });

    test(
      'a pending request is cancelled by the client, not the agent',
      () async {
        final viewing = await request();

        final byAgent = await changeAs(agentUser)(
          viewingId: viewing.id,
          to: ViewingStatus.cancelled,
        );
        expect(byAgent.failureOrNull, isA<ForbiddenFailure>());

        final byClient = await changeAs(clientUser)(
          viewingId: viewing.id,
          to: ViewingStatus.cancelled,
        );
        expect(byClient.valueOrNull?.status, ViewingStatus.cancelled);
      },
    );

    test('completing works only after the viewing time', () async {
      final viewing = await request();
      await changeAs(agentUser)(
        viewingId: viewing.id,
        to: ViewingStatus.confirmed,
      );

      final early = await changeAs(agentUser)(
        viewingId: viewing.id,
        to: ViewingStatus.completed,
      );
      expect(early.failureOrNull, isA<ForbiddenFailure>());

      final late = await changeAs(
        agentUser,
        at: () => now.add(const Duration(days: 3)),
      )(viewingId: viewing.id, to: ViewingStatus.completed);
      expect(late.valueOrNull?.status, ViewingStatus.completed);
    });

    test('a finished viewing reports a conflict (stale screen)', () async {
      final viewing = await request();
      await changeAs(clientUser)(
        viewingId: viewing.id,
        to: ViewingStatus.cancelled,
      );

      final again = await changeAs(clientUser)(
        viewingId: viewing.id,
        to: ViewingStatus.cancelled,
      );
      expect(again.failureOrNull, isA<ConflictFailure>());
    });

    test('outsiders, admins and signed-out users cannot act', () async {
      final viewing = await request();

      for (final outsider in [otherAgent, otherClient, adminUser]) {
        final result = await changeAs(outsider)(
          viewingId: viewing.id,
          to: ViewingStatus.cancelled,
        );
        expect(
          result.failureOrNull,
          isA<ForbiddenFailure>(),
          reason: outsider.id,
        );
      }
      final signedOut = await changeAs(null)(
        viewingId: viewing.id,
        to: ViewingStatus.cancelled,
      );
      expect(signedOut.failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('lists', () {
    test('each side sees only their own viewings', () async {
      await request();

      Future<int> countFor(AppUser user) async =>
          (await ListMyViewings(repo, () => user)()).valueOrNull?.length ?? -1;

      expect(await countFor(clientUser), 1);
      expect(await countFor(agentUser), 1);
      expect(await countFor(otherClient), 0);
      expect(await countFor(otherAgent), 0);

      final asAdmin = await ListMyViewings(repo, () => adminUser)();
      expect(asAdmin.failureOrNull, isA<ForbiddenFailure>());
    });

    test('FindActiveViewing tracks the active request', () async {
      final find = FindActiveViewing(repo, () => clientUser);
      expect((await find('p-1')).valueOrNull, isNull);

      final viewing = await request();
      expect((await find('p-1')).valueOrNull?.id, viewing.id);

      await changeAs(clientUser)(
        viewingId: viewing.id,
        to: ViewingStatus.cancelled,
      );
      expect((await find('p-1')).valueOrNull, isNull);

      final asAgent = await FindActiveViewing(repo, () => agentUser)('p-1');
      expect(asAgent.failureOrNull, isA<ForbiddenFailure>());
    });

    test(
      'the board splits active from finished and sorts each group',
      () async {
        final later = await request(ahead: const Duration(days: 5));
        final sooner = await request(
          property: 'p-2',
          ahead: const Duration(days: 1),
        );
        final done = await request(
          property: 'p-3',
          ahead: const Duration(days: 3),
        );
        await changeAs(clientUser)(
          viewingId: done.id,
          to: ViewingStatus.cancelled,
        );

        final all = (await ListMyViewings(
          repo,
          () => clientUser,
        )()).valueOrNull!;
        final board = ViewingBoard.from(all);

        expect(board.upcoming.map((v) => v.id), [sooner.id, later.id]);
        expect(board.history.map((v) => v.id), [done.id]);
        expect(board.isEmpty, isFalse);
        expect(ViewingBoard.from(const []).isEmpty, isTrue);
      },
    );
  });
}
