import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';

abstract class HomeRepository {
  Future<Either<Failure, void>> addPost({
    required String postContent,
    String postImage = '',
    Uint8List? imageBytes,
    String? imageContentType,
  });

  Future<Either<Failure, void>> addComment({
    required String postId,
    required String comment,
  });

  Future<Either<Failure, void>> togglePostLike({required String postId});

  Future<Either<Failure, List<PostModel>>> getPosts();

    Future<Either<Failure,void>> sendFriendRequest(UserModel userModel);

  Future<Either<Failure, void>> sendChallengeRequest(
    UserModel userModel,
    int gameId,
  );

  Future<Either<Failure, ProfileDashboardModel>> loadProfileDashboard();

  Future<Either<Failure, void>> respondToFriendRequest({
    required String requestId,
    required bool accept,
  });
}
