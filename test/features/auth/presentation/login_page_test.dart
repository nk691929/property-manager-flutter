import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/auth/data/datasources/fake_auth_data_source.dart';
import 'package:property_manager/features/auth/presentation/pages/login_page.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester) => tester.pumpApp(
    const LoginPage(),
    overrides: [
      authRemoteDataSourceProvider.overrideWithValue(
        FakeAuthDataSource.seeded(),
      ),
    ],
  );

  testWidgets('empty submit shows required errors', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('This field is required'), findsNWidgets(2));
  });

  testWidgets('invalid email is flagged before any request', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'nope');
    await tester.enterText(find.byType(TextFormField).at(1), 'whatever');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('wrong credentials show a clear message', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });
}
