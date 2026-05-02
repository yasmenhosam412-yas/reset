import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';

class GetOnlineFriendsUsecase {
  GetOnlineFriendsUsecase({required OnlineRepository onlineRepository})
      : _onlineRepository = onlineRepository;

  final OnlineRepository _onlineRepository;

  Future<Either<Failure, List<UserModel>>> call() {
    return _onlineRepository.getFriends();
  }
}
