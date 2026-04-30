abstract class AuthBlocEvent {}

class AuthLoginEvent extends AuthBlocEvent {
  final String email;
  final String password;

  AuthLoginEvent({required this.email, required this.password});
}

class AuthSignupEvent extends AuthBlocEvent {
  final String email;
  final String password;
  final String username;

  AuthSignupEvent({
    required this.email,
    required this.password,
    required this.username,
  });
}

class AuthLogoutEvent extends AuthBlocEvent {}

class AuthSendRecoveryOtpEvent extends AuthBlocEvent {
  final String email;

  AuthSendRecoveryOtpEvent({required this.email});
}

class AuthVerifyRecoveryOtpEvent extends AuthBlocEvent {
  final String email;
  final String otp;
  final String newPassword;

  AuthVerifyRecoveryOtpEvent({
    required this.email,
    required this.otp,
    required this.newPassword,
  });
}

class AuthSendRecoveryMagicLinkEvent extends AuthBlocEvent {
  final String email;

  AuthSendRecoveryMagicLinkEvent({required this.email});
}

class AuthSetPasswordAfterRecoveryEvent extends AuthBlocEvent {
  final String newPassword;

  AuthSetPasswordAfterRecoveryEvent({required this.newPassword});
}

class AuthResetToIdleEvent extends AuthBlocEvent {}
