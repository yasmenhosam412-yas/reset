import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/features/authentication/presentation/pages/forgot_password_screen.dart';
import 'package:new_project/features/authentication/presentation/pages/login_screen.dart';
import 'package:new_project/features/authentication/presentation/pages/signup_screen.dart';
import 'package:new_project/features/main_screen/main_screen.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_route_args.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_session_page.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/pages/help_support_page.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/pages/privacy_security_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const String privacySecurityPath = '/privacy-security';
  static const String helpSupportPath = '/help-support';

  static final GoRouter router = GoRouter(
    initialLocation: (Supabase.instance.client.auth.currentUser != null)
        ? mainScreenPath
        : loginPath,
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    overridePlatformDefaultLocation: true,
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
      GoRoute(
        path: privacySecurityPath,
        builder: (context, state) => const PrivacySecurityPage(),
      ),
      GoRoute(
        path: helpSupportPath,
        builder: (context, state) => const HelpSupportPage(),
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
