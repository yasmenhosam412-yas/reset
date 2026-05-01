import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class AddHomeCommentUsecase {
  AddHomeCommentUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, void>> call({
    required String postId,
    required String comment,
  }) {
    return _homeRepository.addComment(postId: postId, comment: comment);
  }
}
