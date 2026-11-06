import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/inquiries/data/datasources/fake_inquiries_data_source.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/presentation/pages/inquiry_thread_page.dart';
import 'package:property_manager/features/inquiries/presentation/providers/inquiries_providers.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';

import '../../../helpers/property_test_helpers.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<(FakeInquiriesDataSource, Inquiry)> seeded() async {
    final source = FakeInquiriesDataSource(
      properties: FakePropertiesDataSource.seeded(),
    );
    final inquiry = await source.start(
      propertyId: 'p-1',
      clientId: 'u-client',
      body: 'Is it still available?',
    );
    return (source, inquiry);
  }

  Future<void> pumpThread(
    WidgetTester tester,
    FakeInquiriesDataSource source,
    Inquiry inquiry,
  ) => tester.pumpApp(
    InquiryThreadPage(inquiryId: inquiry.id),
    overrides: [
      inquiriesDataSourceProvider.overrideWithValue(source),
      currentUserProvider.overrideWithValue(clientUser),
    ],
  );

  testWidgets('shows the conversation and sends a message', (tester) async {
    final (source, inquiry) = await seeded();
    await pumpThread(tester, source, inquiry);
    await tester.pumpAndSettle();

    expect(find.text('Is it still available?'), findsOneWidget);
    expect(find.text('Conversation with Alex Agent'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Can I visit on Saturday?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Can I visit on Saturday?'), findsOneWidget);
    expect(await source.messages(inquiry.id), hasLength(2));
  });

  testWidgets('a closed conversation has no composer', (tester) async {
    final (source, inquiry) = await seeded();
    await source.close(inquiry.id);
    await pumpThread(tester, source, inquiry);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('This conversation is closed.'), findsOneWidget);
  });
}
