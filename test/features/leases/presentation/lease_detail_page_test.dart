import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/leases/data/datasources/fake_leases_data_source.dart';
import 'package:property_manager/features/leases/presentation/pages/lease_detail_page.dart';
import 'package:property_manager/features/leases/presentation/providers/leases_providers.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';

import '../../../helpers/lease_test_helpers.dart';
import '../../../helpers/property_test_helpers.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('the tenant sees the schedule with a status for every charge', (
    tester,
  ) async {
    // Tall surface so every charge is built (lists build lazily).
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final lease = sampleLease(
      charges: [
        sampleCharge(
          id: 'c-1',
          dueDate: DateTime(2027),
          payments: [samplePayment(id: 'p-1', chargeId: 'c-1', amount: 50000)],
        ),
        sampleCharge(id: 'c-2', dueDate: DateTime(2027, 2)),
        sampleCharge(
          id: 'c-3',
          dueDate: DateTime(2027, 3),
          payments: [samplePayment(id: 'p-3', chargeId: 'c-3', amount: 20000)],
        ),
        sampleCharge(id: 'c-4', dueDate: DateTime(2027, 4), cancelled: true),
      ],
    );
    final source = FakeLeasesDataSource(
      properties: FakePropertiesDataSource.seeded(),
      leases: [lease],
    );

    await tester.pumpApp(
      const LeaseDetailPage(leaseId: 'l-1'),
      overrides: [
        leasesDataSourceProvider.overrideWithValue(source),
        currentUserProvider.overrideWithValue(clientUser),
        clockProvider.overrideWithValue(() => DateTime(2027, 2, 15)),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Two-Bedroom Apartment in Gulberg'), findsOneWidget);
    expect(find.text('Agent: Alex Agent'), findsOneWidget);
    expect(find.text('Rent schedule'), findsOneWidget);
    expect(find.text('Partly paid'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Overdue'), findsWidgets); // summary label and a chip
    expect(find.text('Overdue'), findsNWidgets(2));
  });

  testWidgets('a lease you are not a party to is refused', (tester) async {
    final source = FakeLeasesDataSource(
      properties: FakePropertiesDataSource.seeded(),
      leases: [sampleLease(tenantId: 'someone-else')],
    );

    await tester.pumpApp(
      const LeaseDetailPage(leaseId: 'l-1'),
      overrides: [
        leasesDataSourceProvider.overrideWithValue(source),
        currentUserProvider.overrideWithValue(clientUser),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Rent schedule'), findsNothing);
    expect(find.text("You don't have permission to do that."), findsOneWidget);
  });
}
