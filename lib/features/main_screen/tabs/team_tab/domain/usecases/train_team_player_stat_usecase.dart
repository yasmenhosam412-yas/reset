import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_challenge_results.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class TrainTeamPlayerStatUsecase {
  TrainTeamPlayerStatUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, TeamTrainPlayerResult>> call({
    required int playerSlot,
    required String statKey,
  }) {
    return _homeRepository.trainTeamPlayerStat(
      playerSlot: playerSlot,
      statKey: statKey,
    );
  }
}
