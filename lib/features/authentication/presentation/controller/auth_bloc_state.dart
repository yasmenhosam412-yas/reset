enum AuthState {
  idle,
  loading,
  loadedLogin,
  loadedSignup,
  loadedOut,
  /// Email OTP was sent; user should enter code and new password.
  recoveryOtpSent,
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
