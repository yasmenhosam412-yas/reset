import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/domain/repositories/auth_repository.dart';

class SignupUsecase {
  final AuthRepository authRepository;

  SignupUsecase({required this.authRepository});

  Future<Either<Failure, String>> call({
    required String username,
    required String email,
    required String password,
  }) async {
    return await authRepository.signup(
      email: email,
      password: password,
      username: username,
    );
  }
}
