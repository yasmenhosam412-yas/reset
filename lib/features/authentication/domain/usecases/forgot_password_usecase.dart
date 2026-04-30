import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/domain/repositories/auth_repository.dart';

class ForgotPasswordUsecase {
  final AuthRepository authRepository;

  ForgotPasswordUsecase({required this.authRepository});

  Future<Either<Failure, String>> sendCode({required String email}) {
    return authRepository.sendPasswordRecoveryOtp(email: email);
  }

  Future<Either<Failure, String>> verifyAndReset({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return authRepository.verifyOtpAndSetNewPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  Future<Either<Failure, String>> sendMagicLink({
    required String email,
    required String redirectTo,
  }) {
    return authRepository.sendPasswordResetMagicLink(
      email: email,
      redirectTo: redirectTo,
    );
  }
}
