import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class SubmitLineupRaceEntryUsecase {
  SubmitLineupRaceEntryUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, int>> call(String raceKey) {
    return _homeRepository.submitLineupRaceEntry(raceKey);
  }
}
