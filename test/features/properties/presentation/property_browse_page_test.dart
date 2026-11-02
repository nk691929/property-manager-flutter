import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/properties/data/datasources/fake_properties_data_source.dart';
import 'package:property_manager/features/properties/presentation/pages/property_browse_page.dart';
import 'package:property_manager/features/properties/presentation/providers/properties_providers.dart';

import '../../../helpers/property_test_helpers.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpBrowse(WidgetTester tester) => tester.pumpApp(
    const PropertyBrowsePage(),
    overrides: [
      propertiesDataSourceProvider.overrideWithValue(
        FakePropertiesDataSource.seeded(),
      ),
      currentUserProvider.overrideWithValue(clientUser),
    ],
  );

  testWidgets('shows published listings, never drafts', (tester) async {
    await pumpBrowse(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Furnished Room for Working Professional'),
      findsOneWidget,
    );
    expect(find.text('Draft: 3 Marla House in Samanabad'), findsNothing);
  });

  testWidgets('typing in search narrows the list after the debounce', (
    tester,
  ) async {
    await pumpBrowse(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'canal');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Modern 5 Marla House near Canal Road'), findsOneWidget);
    expect(find.text('Furnished Room for Working Professional'), findsNothing);
  });

  testWidgets('empty result shows the empty message', (tester) async {
    await pumpBrowse(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('No properties match your search.'), findsOneWidget);
  });
}
