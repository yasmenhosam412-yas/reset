abstract class AuthRemoteDatasource {
  Future<void> login({required String email, required String password});
  Future<void> logout();
  Future<void> signup({
    required String email,
    required String password,
    required String username,
  });
  /// Sends a one-time code to [email] (email OTP). User must already exist.
  Future<void> sendPasswordRecoveryOtp({required String email});

  /// Verifies the email OTP, sets a new password (user gains a session), then signs out
  /// so they can log in with the new password.
  Future<void> verifyOtpAndSetNewPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  /// Sends a password recovery email with a magic link. The link redirects to
  /// [redirectTo] with `#access_token=...&refresh_token=...&type=recovery` in the URL.
  Future<void> sendPasswordResetMagicLink({
    required String email,
    required String redirectTo,
  });

  Future<void> updatePasswordForCurrentUser({required String newPassword});
}
