import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  });
  Future<Either<Failure, String>> signup({
    required String email,
    required String password,
    required String username,
  });
  Future<Either<Failure, String>> logout();
  Future<Either<Failure, String>> sendPasswordRecoveryOtp({
    required String email,
  });

  Future<Either<Failure, String>> verifyOtpAndSetNewPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<Either<Failure, String>> sendPasswordResetMagicLink({
    required String email,
    required String redirectTo,
  });

  Future<Either<Failure, String>> updatePasswordAfterRecovery({
    required String newPassword,
  });
}
