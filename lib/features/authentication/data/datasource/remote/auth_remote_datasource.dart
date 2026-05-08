abstract class AuthRemoteDatasource {
  Future<void> login({required String email, required String password});
  Future<void> logout();
  Future<void> deleteAccount();
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
}
