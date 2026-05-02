import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class SendHomeChallengeUsecase {
  SendHomeChallengeUsecase({required HomeRepository homeRepository})
    : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, void>> call(UserModel userModel, int gameId) {
    return _homeRepository.sendChallengeRequest(userModel, gameId);
  }
}
