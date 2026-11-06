import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';
import 'package:property_manager/features/viewings/data/datasources/fake_viewings_data_source.dart';
import 'package:property_manager/features/viewings/presentation/pages/viewings_page.dart';
import 'package:property_manager/features/viewings/presentation/providers/viewings_providers.dart';

import '../../../helpers/property_test_helpers.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpViewings(WidgetTester tester, AppUser user) async {
    final source = FakeViewingsDataSource(
      properties: FakePropertiesDataSource.seeded(),
    );
    await source.request(
      propertyId: 'p-1',
      clientId: 'u-client',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
    );
    await tester.pumpApp(
      const ViewingsPage(),
      overrides: [
        viewingsDataSourceProvider.overrideWithValue(source),
        currentUserProvider.overrideWithValue(user),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the agent sees the request and confirms it', (tester) async {
    await pumpViewings(tester, agentUser);

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Requested'), findsOneWidget);
    expect(find.text('With Casey Client'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    expect(find.text('Cancel viewing'), findsOneWidget);
  });

  testWidgets('the client can cancel a request but not confirm it', (
    tester,
  ) async {
    await pumpViewings(tester, clientUser);

    expect(find.text('With Alex Agent'), findsOneWidget);
    expect(find.text('Cancel viewing'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    expect(find.text('Decline'), findsNothing);
  });
}
