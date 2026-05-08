import 'dart:typed_data';

import 'package:new_project/features/authentication/data/models/user_model.dart';

abstract class HomeEvent {}

final class HomePostsRequested extends HomeEvent {
  final int limit;
  final int offset;

  HomePostsRequested({required this.limit, required this.offset});
}

final class HomePostCreateRequested extends HomeEvent {
  HomePostCreateRequested({
    required this.postContent,
    this.postImage = '',
    this.imageBytes,
    this.imageContentType,
    this.allowShare = true,
    this.postVisibility = 'general',
    this.postType = 'post',
    this.adLink,
  });

  final String postContent;
  final String postImage;
  final Uint8List? imageBytes;
  final String? imageContentType;
  final bool allowShare;
  final String postVisibility;
  final String postType;
  final String? adLink;
}

final class HomePostDeleteRequested extends HomeEvent {
  HomePostDeleteRequested({required this.postId});

  final String postId;
}

final class HomePostUpdateRequested extends HomeEvent {
  HomePostUpdateRequested({
    required this.postId,
    required this.postContent,
    this.imageBytes,
    this.imageContentType,
    this.clearImage = false,
    required this.allowShare,
    this.postVisibility = 'general',
    this.postType = 'post',
    this.adLink,
  });

  final String postId;
  final String postContent;
  final Uint8List? imageBytes;
  final String? imageContentType;
  final bool clearImage;
  final bool allowShare;
  final String postVisibility;
  final String postType;
  final String? adLink;
}

final class HomeCommentCreateRequested extends HomeEvent {
  HomeCommentCreateRequested({required this.postId, required this.comment});

  final String postId;
  final String comment;
}

/// [reaction] is one of: like, love, laugh, wow, sad, care — or `null` to remove yours.
final class HomePostReactionRequested extends HomeEvent {
  HomePostReactionRequested({required this.postId, this.reaction});

  final String postId;
  final String? reaction;
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

final class ResetHomeEvent extends HomeEvent {}
