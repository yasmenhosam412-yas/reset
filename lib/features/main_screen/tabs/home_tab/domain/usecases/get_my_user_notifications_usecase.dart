import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/user_feed_notification_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class GetMyUserNotificationsUsecase {
  GetMyUserNotificationsUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, List<UserFeedNotificationModel>>> call({
    int limit = 50,
  }) {
    return _homeRepository.getMyUserNotifications(limit: limit);
  }
}
