import 'dart:typed_data';

import 'package:new_project/features/authentication/data/models/user_model.dart';

abstract class HomeEvent {}

final class HomePostsRequested extends HomeEvent {}

final class HomePostCreateRequested extends HomeEvent {
  HomePostCreateRequested({
    required this.postContent,
    this.postImage = '',
    this.imageBytes,
    this.imageContentType,
  });

  final String postContent;
  final String postImage;
  final Uint8List? imageBytes;
  final String? imageContentType;
}

final class HomeCommentCreateRequested extends HomeEvent {
  HomeCommentCreateRequested({required this.postId, required this.comment});

  final String postId;
  final String comment;
}

final class HomePostLikeRequested extends HomeEvent {
  HomePostLikeRequested({required this.postId});

  final String postId;
}

final class HomeSendFriendRequest extends HomeEvent {
  HomeSendFriendRequest({required this.userModel});

  final UserModel userModel;
}

final class HomeSendChallenge extends HomeEvent {
  HomeSendChallenge({required this.userModel, required this.gameId});
  
  final UserModel userModel;
  final int gameId;
}
