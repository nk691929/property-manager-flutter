import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/not_found_page.dart';
import 'package:property_manager/app/router/redirect.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/router/splash_page.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/features/admin_users/presentation/pages/admin_users_page.dart';
import 'package:property_manager/features/app_info/presentation/pages/app_info_page.dart';
import 'package:property_manager/features/auth/presentation/pages/login_page.dart';
import 'package:property_manager/features/auth/presentation/pages/register_page.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/home/presentation/pages/admin_home_page.dart';
import 'package:property_manager/features/home/presentation/pages/agent_home_page.dart';
import 'package:property_manager/features/home/presentation/pages/client_home_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Bumped on every auth change so go_router re-runs `redirect`.
  // We *listen* instead of *watch* so the router itself is never rebuilt
  // (a rebuilt router would reset navigation state).
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authStateProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.root,
    debugLogDiagnostics: ref.watch(appConfigProvider).verboseLogging,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      return resolveRedirect(
        isLoading: auth.isLoading,
        user: auth.value,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AppInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminHomePage(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminUsersPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.agent,
        builder: (context, state) => const AgentHomePage(),
      ),
      GoRoute(
        path: AppRoutes.client,
        builder: (context, state) => const ClientHomePage(),
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundPage(location: state.uri.toString()),
  );
  ref.onDispose(router.dispose);
  return router;
}
