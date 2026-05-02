import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';

class SetOnlineChallengeReadyUsecase {
  SetOnlineChallengeReadyUsecase({required OnlineRepository onlineRepository})
      : _onlineRepository = onlineRepository;

  final OnlineRepository _onlineRepository;

  /// Returns `true` if both players are ready after this update.
  Future<Either<Failure, bool>> call(String challengeId) {
    return _onlineRepository.setChallengeReady(challengeId: challengeId);
  }
}
