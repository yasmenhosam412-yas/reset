import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class GetHomePostsForAuthorUsecase {
  GetHomePostsForAuthorUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, List<PostModel>>> call({
    required String authorUserId,
    required int limit,
    required int offset,
  }) {
    return _homeRepository.getPostsForAuthor(
      authorUserId: authorUserId,
      limit: limit,
      offset: offset,
    );
  }
}
