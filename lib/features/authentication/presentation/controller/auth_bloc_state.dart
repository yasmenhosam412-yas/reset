enum AuthState {
  idle,
  loading,
  loadedLogin,
  loadedSignup,
  loadedOut,
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
