import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/config/flavor.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/app_info/domain/entities/app_info.dart';
import 'package:property_manager/features/app_info/presentation/pages/app_info_page.dart';
import 'package:property_manager/features/app_info/presentation/providers/app_info_providers.dart';

import '../../../helpers/pump_app.dart';

void main() {
  const info = AppInfo(
    appName: 'Property Manager',
    version: '1.0.0',
    buildNumber: '3',
    flavor: Flavor.dev,
  );

  testWidgets('shows app details when loaded', (tester) async {
    await tester.pumpApp(
      const AppInfoPage(),
      overrides: [appInfoProvider.overrideWith((ref) async => info)],
    );
    await tester.pumpAndSettle();

    expect(find.text('Property Manager'), findsOneWidget);
    expect(find.text('1.0.0 (3)'), findsOneWidget);
    expect(find.text('DEV'), findsOneWidget);
    expect(find.text('Not configured'), findsOneWidget);
  });

  testWidgets('shows localized error, then recovers on Retry', (tester) async {
    var calls = 0;
    await tester.pumpApp(
      const AppInfoPage(),
      overrides: [
        appInfoProvider.overrideWith((ref) async {
          calls++;
          if (calls == 1) throw const NetworkFailure();
          return info;
        }),
      ],
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Property Manager'), findsOneWidget);
    expect(calls, 2);
  });
}
