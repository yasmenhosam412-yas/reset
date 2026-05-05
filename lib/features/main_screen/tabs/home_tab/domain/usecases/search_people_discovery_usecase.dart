import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/people_discovery_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class SearchPeopleDiscoveryUsecase {
  SearchPeopleDiscoveryUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, List<PeopleDiscoveryRow>>> call(String query) {
    return _homeRepository.searchPeopleDiscovery(query);
  }
}
