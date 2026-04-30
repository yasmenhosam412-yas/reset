import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/login_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/signup_usecase.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_event.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_state.dart';

class AuthBloc extends Bloc<AuthBlocEvent, AuthBlocState> {
  final LoginUsecase loginUsecase;
  final SignupUsecase signupUsecase;
  final LogoutUsecase logoutUsecase;
  final ForgotPasswordUsecase forgotPasswordUsecase;

  AuthBloc({
    required this.loginUsecase,
    required this.signupUsecase,
    required this.logoutUsecase,
    required this.forgotPasswordUsecase,
  }) : super(AuthBlocState(authState: AuthState.idle)) {
    on<AuthLoginEvent>(_onLogin);
    on<AuthSignupEvent>(_onSignup);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthSendRecoveryOtpEvent>(_onSendRecoveryOtp);
    on<AuthVerifyRecoveryOtpEvent>(_onVerifyRecoveryOtp);
    on<AuthResetToIdleEvent>((_, emit) {
      emit(AuthBlocState(authState: AuthState.idle));
    });
  }

  Future<void> _onLogin(
    AuthLoginEvent event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocState(authState: AuthState.loading));
    final result = await loginUsecase(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(
        AuthBlocState(authState: AuthState.errorLogin, error: failure.message),
      ),
      (_) => emit(AuthBlocState(authState: AuthState.loadedLogin)),
    );
  }

  Future<void> _onSignup(
    AuthSignupEvent event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocState(authState: AuthState.loading));
    final result = await signupUsecase(
      username: event.username,
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(
        AuthBlocState(authState: AuthState.errorSignup, error: failure.message),
      ),
      (_) => emit(AuthBlocState(authState: AuthState.loadedSignup)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocState(authState: AuthState.loading));
    final result = await logoutUsecase();
    result.fold(
      (failure) => emit(
        AuthBlocState(authState: AuthState.errorOut, error: failure.message),
      ),
      (_) => emit(AuthBlocState(authState: AuthState.loadedOut)),
    );
  }

  Future<void> _onSendRecoveryOtp(
    AuthSendRecoveryOtpEvent event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocState(authState: AuthState.loading));
    final result = await forgotPasswordUsecase.sendCode(email: event.email);
    result.fold(
      (failure) => emit(
        AuthBlocState(
          authState: AuthState.errorForgotPassword,
          error: failure.message,
        ),
      ),
      (_) => emit(AuthBlocState(authState: AuthState.recoveryOtpSent)),
    );
  }

  Future<void> _onVerifyRecoveryOtp(
    AuthVerifyRecoveryOtpEvent event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocState(authState: AuthState.loading));
    final result = await forgotPasswordUsecase.verifyAndReset(
      email: event.email,
      otp: event.otp,
      newPassword: event.newPassword,
    );
    result.fold(
      (failure) => emit(
        AuthBlocState(
          authState: AuthState.errorForgotPassword,
          error: failure.message,
        ),
      ),
      (_) => emit(AuthBlocState(authState: AuthState.loadedForgotPassword)),
    );
  }
}
