import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/lineup_race_board_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class GetLineupRaceLeaderboardUsecase {
  GetLineupRaceLeaderboardUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, List<LineupRaceBoardRow>>> call({
    required String raceKey,
    int limit = 40,
  }) {
    return _homeRepository.fetchLineupRaceLeaderboard(
      raceKey: raceKey,
      limit: limit,
    );
  }
}
