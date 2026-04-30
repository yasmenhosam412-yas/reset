import 'package:flutter/foundation.dart';

/// GitHub Pages app URL (must match `flutter build web --base-href /reset/`).
/// Add this (and `.../**`) under Supabase → Authentication → URL configuration.
const String _kWebAuthRedirectBase =
    'https://yasmenhosam412-yas.github.io/reset/';

/// Optional override, e.g. local testing:
/// `flutter run -d chrome --dart-define=AUTH_REDIRECT_BASE=http://localhost:8080/`
const String _kAuthRedirectFromEnv = String.fromEnvironment(
  'AUTH_REDIRECT_BASE',
);

/// Return URL for `resetPasswordForEmail(redirectTo: ...)`.
/// Must be listed in Supabase **Redirect URLs**.
String passwordRecoveryRedirectUrl() {
  if (kIsWeb) {
    if (_kAuthRedirectFromEnv.isNotEmpty) {
      return _ensureTrailingSlash(_kAuthRedirectFromEnv.trim());
    }
    return _kWebAuthRedirectBase;
  }
  return 'com.example.new_project://reset-password/';
}

String _ensureTrailingSlash(String url) {
  return url.endsWith('/') ? url : '$url/';
}
