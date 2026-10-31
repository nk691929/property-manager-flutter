import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/not_found_page.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/features/app_info/presentation/pages/app_info_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: ref.watch(appConfigProvider).verboseLogging,
    // MVP 1 adds `redirect:` here for auth and role-based guards.
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const AppInfoPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundPage(location: state.uri.toString()),
  );
  ref.onDispose(router.dispose);
  return router;
}
