import 'dart:typed_data';

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
  HomeCommentCreateRequested({
    required this.postId,
    required this.comment,
  });

  final String postId;
  final String comment;
}

final class HomePostLikeRequested extends HomeEvent {
  HomePostLikeRequested({required this.postId});

  final String postId;
}
