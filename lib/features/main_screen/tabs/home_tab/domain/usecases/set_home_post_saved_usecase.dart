import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class SetHomePostSavedUsecase {
  SetHomePostSavedUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, void>> call({
    required String postId,
    required bool saved,
  }) {
    return _homeRepository.setPostSaved(postId: postId, saved: saved);
  }
}
