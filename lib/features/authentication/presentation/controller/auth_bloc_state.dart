enum AuthState {
  idle,
  loading,
  loadedLogin,
  loadedSignup,
  loadedOut,
  /// Email OTP was sent; user should enter code and new password.
  recoveryOtpSent,
  /// Password reset magic link was sent to email.
  recoveryMagicLinkSent,
  loadedForgotPassword,
  errorLogin,
  errorSignup,
  errorOut,
  errorForgotPassword,
}

class AuthBlocState {
  final AuthState authState;
  final String? error;

  AuthBlocState({required this.authState, this.error});
}
