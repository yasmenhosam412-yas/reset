import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/domain/repositories/auth_repository.dart';

class DeleteAccountUsecase {
  final AuthRepository authRepository;

  DeleteAccountUsecase({required this.authRepository});

  Future<Either<Failure, String>> call() async {
    return await authRepository.deleteAccount();
  }
}

