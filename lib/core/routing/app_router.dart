import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/features/authentication/presentation/pages/forgot_password_screen.dart';
import 'package:new_project/features/authentication/presentation/pages/login_screen.dart';
import 'package:new_project/features/authentication/presentation/pages/signup_screen.dart';
import 'package:new_project/features/main_screen/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouter {
  static const String loginPath = '/';
  static const String signupPath = '/signup';
  static const String forgotPasswordPath = '/forgot-password';
  static const String mainScreenPath = '/main-screen';

  static final GoRouter router = GoRouter(
    initialLocation: (getIt<SupabaseClient>().auth.currentUser?.id != null)
        ? mainScreenPath
        : loginPath,
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
