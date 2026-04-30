import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/data/datasource/remote/auth_remote_datasource.dart';
import 'package:new_project/features/authentication/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource authRemoteDatasource;

  AuthRepositoryImpl({required this.authRemoteDatasource});
  @override
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  }) async {
    try {
      await authRemoteDatasource.login(email: email, password: password);
      return Right("Welcome User !");
    } on AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> logout() async {
    try {
      await authRemoteDatasource.logout();
      return Right("Logged Out");
    } on AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      await authRemoteDatasource.signup(
        email: email,
        password: password,
        username: username,
      );
      return Right("Signup Successfully");
    } on AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> sendPasswordRecoveryOtp({
    required String email,
  }) async {
    try {
      await authRemoteDatasource.sendPasswordRecoveryOtp(email: email);
      return const Right('Verification code sent');
    } on AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> verifyOtpAndSetNewPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await authRemoteDatasource.verifyOtpAndSetNewPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return const Right('Password updated');
    } on AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> sendPasswordResetMagicLink({
    required String email,
    required String redirectTo,
  }) async {
    try {
      await authRemoteDatasource.sendPasswordResetMagicLink(
        email: email,
        redirectTo: redirectTo,
      );
      return const Right('Reset link sent');
    } on AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> updatePasswordAfterRecovery({
    required String newPassword,
  }) async {
    try {
      await authRemoteDatasource.updatePasswordForCurrentUser(
        newPassword: newPassword,
      );
      return const Right('Password updated');
    } on AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
