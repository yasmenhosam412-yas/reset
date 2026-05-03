import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/features/authentication/presentation/pages/forgot_password_screen.dart';
import 'package:new_project/features/authentication/presentation/pages/login_screen.dart';
import 'package:new_project/features/authentication/presentation/pages/signup_screen.dart';
import 'package:new_project/features/main_screen/main_screen.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_route_args.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_session_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notifies [GoRouter] whenever Supabase auth changes (session restore, sign-in,
/// token refresh, sign-out). Without this, [initialLocation] is evaluated once and
/// can point at login before the persisted session is ready — a hot restart / R
/// then looks like an unwanted sign-out.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    _sub = stream.listen(
      (_) => notifyListeners(),
      onError: (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static const String loginPath = '/';
  static const String signupPath = '/signup';
  static const String forgotPasswordPath = '/forgot-password';
  static const String mainScreenPath = '/main-screen';
  static const String gameSessionPath = '/game-session';

  static final GoRouter router = GoRouter(
    initialLocation: loginPath,
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    overridePlatformDefaultLocation: true,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final loc = state.matchedLocation;

      final onPublicAuth = loc == loginPath ||
          loc == signupPath ||
          loc == forgotPasswordPath;

      if (user == null && !onPublicAuth) {
        return loginPath;
      }
      if (user != null && loc == loginPath) {
        return mainScreenPath;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signupPath,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: forgotPasswordPath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: mainScreenPath,
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: gameSessionPath,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! OnlineGameRouteArgs) {
            return const Scaffold(
              body: Center(child: Text('Missing match data.')),
            );
          }
          return OnlineGameSessionPage(args: extra);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Page not found'),
              const SizedBox(height: 12),
              Text(
                state.uri.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(loginPath),
                child: const Text('Go to login'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
