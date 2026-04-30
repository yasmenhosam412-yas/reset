import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/domain/repositories/auth_repository.dart';

class SetPasswordAfterRecoveryUsecase {
  final AuthRepository authRepository;

  SetPasswordAfterRecoveryUsecase({required this.authRepository});

  Future<Either<Failure, String>> call({required String newPassword}) {
    return authRepository.updatePasswordAfterRecovery(newPassword: newPassword);
  }
}
