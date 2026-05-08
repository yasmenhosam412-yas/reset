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
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> logout() async {
    try {
      await authRemoteDatasource.logout();
      return Right("Logged Out");
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> deleteAccount() async {
    try {
      await authRemoteDatasource.deleteAccount();
      return Right("Account deleted");
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(failureFromException(e));
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
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(failureFromException(e));
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
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(failureFromException(e));
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
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(failureFromException(e));
    }
  }
}

Failure _mapAuthException(AuthException e) {
  if (_looksLikeUsernameTakenError(e.message)) {
    return ServerFailure(message: 'Username already taken. Try another one.');
  }
  if (authMessageLooksLikeNetworkFailure(e.message)) {
    return NetworkFailure();
  }
  return ServerFailure(message: e.message);
}

bool _looksLikeUsernameTakenError(String message) {
  final m = message.toLowerCase();
  final authDatabaseSaveFailed =
      m.contains('database error saving new user') ||
      m.contains('error saving new user');
  final mentionsUsername = m.contains('username');
  final mentionsConstraint =
      m.contains('profiles_username_unique') ||
      m.contains('duplicate key value') ||
      m.contains('violates unique constraint');
  final mentionsUnique =
      m.contains('duplicate') ||
      m.contains('unique') ||
      m.contains('already exists') ||
      m.contains('already taken') ||
      m.contains('23505');
  return authDatabaseSaveFailed ||
      (mentionsUsername && mentionsUnique) ||
      (mentionsConstraint && mentionsUnique);
}
