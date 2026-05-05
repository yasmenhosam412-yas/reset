import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class AddHomePostLikeUsecase {
  AddHomePostLikeUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, void>> call({
    required String postId,
    String? reaction,
  }) {
    return _homeRepository.setPostReaction(postId: postId, reaction: reaction);
  }
}
