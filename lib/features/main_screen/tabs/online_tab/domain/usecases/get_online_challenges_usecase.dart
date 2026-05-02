import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';

class GetOnlineChallengesUsecase {
  GetOnlineChallengesUsecase({required OnlineRepository onlineRepository})
      : _onlineRepository = onlineRepository;

  final OnlineRepository _onlineRepository;

  Future<Either<Failure, List<ChallengeRequestModel>>> call() {
    return _onlineRepository.getChallenges();
  }
}
