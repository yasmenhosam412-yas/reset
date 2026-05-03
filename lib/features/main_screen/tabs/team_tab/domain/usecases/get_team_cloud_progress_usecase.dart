import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_cloud_snapshot.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class GetTeamCloudProgressUsecase {
  GetTeamCloudProgressUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, TeamCloudSnapshot>> call() {
    return _homeRepository.fetchTeamCloudSnapshot();
  }
}
