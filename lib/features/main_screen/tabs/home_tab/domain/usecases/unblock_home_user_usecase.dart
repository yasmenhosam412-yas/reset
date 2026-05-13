import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class UnblockHomeUserUsecase {
  UnblockHomeUserUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, void>> call({required String blockedUserId}) {
    return _homeRepository.unblockUser(blockedUserId: blockedUserId);
  }
}
