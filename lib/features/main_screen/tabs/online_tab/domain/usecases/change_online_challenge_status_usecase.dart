import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';

class ChangeOnlineChallengeStatusUsecase {
  ChangeOnlineChallengeStatusUsecase({required OnlineRepository onlineRepository})
      : _onlineRepository = onlineRepository;

  final OnlineRepository _onlineRepository;

  Future<Either<Failure, void>> call({
    required String challengeId,
    required String status,
  }) {
    return _onlineRepository.changeChallengeStatus(
      challengeId: challengeId,
      status: status,
    );
  }
}
