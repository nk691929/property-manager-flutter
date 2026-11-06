import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/inquiries/data/datasources/fake_inquiries_data_source.dart';
import 'package:property_manager/features/inquiries/data/repositories/inquiries_repository_impl.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_enums.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';
import 'package:property_manager/features/inquiries/domain/usecases/close_inquiry.dart';
import 'package:property_manager/features/inquiries/domain/usecases/find_open_inquiry.dart';
import 'package:property_manager/features/inquiries/domain/usecases/get_inquiry.dart';
import 'package:property_manager/features/inquiries/domain/usecases/list_inquiry_messages.dart';
import 'package:property_manager/features/inquiries/domain/usecases/list_my_inquiries.dart';
import 'package:property_manager/features/inquiries/domain/usecases/send_inquiry_message.dart';
import 'package:property_manager/features/inquiries/domain/usecases/start_inquiry.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';

import '../../../helpers/property_test_helpers.dart';

void main() {
  const otherClient = AppUser(
    id: 'u-client-2',
    email: 'c2@x.com',
    role: Role.client,
  );

  late InquiriesRepositoryImpl repo;

  setUp(() {
    repo = InquiriesRepositoryImpl(
      FakeInquiriesDataSource(properties: FakePropertiesDataSource.seeded()),
    );
  });

  Future<Inquiry> startAs(
    AppUser user, {
    String property = 'p-1',
    String body = 'Is it still available?',
  }) async {
    final result = await StartInquiry(repo, () => user)(
      propertyId: property,
      body: body,
    );
    return result.valueOrNull!;
  }

  Future<List<String>> bodies(AppUser user, String inquiryId) async {
    final result = await ListInquiryMessages(repo, () => user)(inquiryId);
    return [for (final m in result.valueOrNull ?? <InquiryMessage>[]) m.body];
  }

  group('StartInquiry', () {
    test('a client starts a conversation about a published listing', () async {
      final inquiry = await startAs(
        clientUser,
        body: '  Is it still available?  ',
      );

      expect(inquiry.status, InquiryStatus.open);
      expect(inquiry.agentId, 'u-agent');
      expect(inquiry.propertyTitle, 'Modern 5 Marla House near Canal Road');
      expect(inquiry.lastMessagePreview, 'Is it still available?');
      expect(await bodies(clientUser, inquiry.id), ['Is it still available?']);
    });

    test(
      'agents are forbidden and signed-out users are unauthorized',
      () async {
        final asAgent = await StartInquiry(repo, () => agentUser)(
          propertyId: 'p-1',
          body: 'Hello',
        );
        final signedOut = await StartInquiry(repo, () => null)(
          propertyId: 'p-1',
          body: 'Hello',
        );
        expect(asAgent.failureOrNull, isA<ForbiddenFailure>());
        expect(signedOut.failureOrNull, isA<UnauthorizedFailure>());
      },
    );

    test('invalid messages never reach the repository', () async {
      for (final body in ['', '   ', 'a' * 2001]) {
        final result = await StartInquiry(repo, () => clientUser)(
          propertyId: 'p-1',
          body: body,
        );
        expect(result.failureOrNull, isA<ValidationFailure>());
      }
      final mine = await ListMyInquiries(repo, () => clientUser)(offset: 0);
      expect(mine.valueOrNull, isEmpty);
    });

    test('only one open conversation per listing', () async {
      final first = await startAs(clientUser);

      final duplicate = await StartInquiry(repo, () => clientUser)(
        propertyId: 'p-1',
        body: 'Again',
      );
      expect(duplicate.failureOrNull, isA<ConflictFailure>());

      await CloseInquiry(repo, () => clientUser)(first.id);
      final afterClose = await StartInquiry(repo, () => clientUser)(
        propertyId: 'p-1',
        body: 'A new question',
      );
      expect(afterClose.isOk, isTrue);
    });

    test('a draft listing cannot be contacted', () async {
      final result = await StartInquiry(repo, () => clientUser)(
        propertyId: 'p-7',
        body: 'Hello',
      );
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('messages', () {
    test('client and agent exchange messages in order', () async {
      final inquiry = await startAs(clientUser);

      final reply = await SendInquiryMessage(repo, () => agentUser)(
        inquiryId: inquiry.id,
        body: ' Yes, it is. ',
      );
      expect(reply.isOk, isTrue);
      expect(await bodies(clientUser, inquiry.id), [
        'Is it still available?',
        'Yes, it is.',
      ]);

      final updated = (await GetInquiry(repo, () => agentUser)(inquiry.id))
          .valueOrNull;
      expect(updated?.lastMessagePreview, 'Yes, it is.');
      expect(updated?.lastSenderId, 'u-agent');
    });

    test('outsiders can neither read nor write', () async {
      final inquiry = await startAs(clientUser);

      for (final outsider in [otherAgent, otherClient, adminUser]) {
        final read = await ListInquiryMessages(repo, () => outsider)(
          inquiry.id,
        );
        final write = await SendInquiryMessage(repo, () => outsider)(
          inquiryId: inquiry.id,
          body: 'Hi',
        );
        expect(
          read.failureOrNull,
          isA<ForbiddenFailure>(),
          reason: outsider.id,
        );
        expect(
          write.failureOrNull,
          isA<ForbiddenFailure>(),
          reason: outsider.id,
        );
      }
    });

    test('a closed conversation rejects new messages', () async {
      final inquiry = await startAs(clientUser);
      await CloseInquiry(repo, () => agentUser)(inquiry.id);

      final result = await SendInquiryMessage(repo, () => clientUser)(
        inquiryId: inquiry.id,
        body: 'One more thing',
      );
      expect(result.failureOrNull, isA<ConflictFailure>());
    });

    test('invalid text is rejected before anything is loaded', () async {
      final result = await SendInquiryMessage(repo, () => clientUser)(
        inquiryId: 'does-not-exist',
        body: '  ',
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('CloseInquiry', () {
    test('either participant can close, twice is harmless', () async {
      final inquiry = await startAs(clientUser);

      final first = await CloseInquiry(repo, () => agentUser)(inquiry.id);
      final second = await CloseInquiry(repo, () => clientUser)(inquiry.id);

      expect(first.valueOrNull?.status, InquiryStatus.closed);
      expect(second.valueOrNull?.status, InquiryStatus.closed);
    });

    test('outsiders cannot close', () async {
      final inquiry = await startAs(clientUser);
      final result = await CloseInquiry(repo, () => otherAgent)(inquiry.id);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });
  });

  group('lists', () {
    test('each side sees only their own conversations', () async {
      await startAs(clientUser);

      Future<int> countFor(AppUser user) async =>
          (await ListMyInquiries(repo, () => user)(offset: 0))
              .valueOrNull
              ?.length ??
          -1;

      expect(await countFor(clientUser), 1);
      expect(await countFor(agentUser), 1);
      expect(await countFor(otherClient), 0);
      expect(await countFor(otherAgent), 0);

      final asAdmin = await ListMyInquiries(repo, () => adminUser)(offset: 0);
      expect(asAdmin.failureOrNull, isA<ForbiddenFailure>());
    });

    test('FindOpenInquiry tracks the open conversation', () async {
      final find = FindOpenInquiry(repo, () => clientUser);

      final before = await find('p-1');
      expect(before.isOk, isTrue);
      expect(before.valueOrNull, isNull);

      final inquiry = await startAs(clientUser);
      expect((await find('p-1')).valueOrNull?.id, inquiry.id);

      await CloseInquiry(repo, () => clientUser)(inquiry.id);
      expect((await find('p-1')).valueOrNull, isNull);

      final asAgent = await FindOpenInquiry(repo, () => agentUser)('p-1');
      expect(asAgent.failureOrNull, isA<ForbiddenFailure>());
    });
  });
}
