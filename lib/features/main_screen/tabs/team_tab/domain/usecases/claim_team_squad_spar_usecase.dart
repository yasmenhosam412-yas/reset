import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_challenge_results.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class ClaimTeamSquadSparUsecase {
  ClaimTeamSquadSparUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, TeamSquadSparResult>> call(String opponentUserId) {
    return _homeRepository.claimTeamSquadSpar(opponentUserId);
  }
}
