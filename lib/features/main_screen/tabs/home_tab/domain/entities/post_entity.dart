import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/entities/comment_entity.dart';

class PostEntity {
  final String id;
  final UserModel userModel;
  final String postImage;
  final String postContent;
  final List<String> likes;
  final List<CommentEntity> comments;
  final DateTime? createdAt;
  /// When false, other users must not repost this post.
  final bool allowShare;

  PostEntity({
    required this.id,
    required this.userModel,
    required this.postImage,
    required this.postContent,
    required this.likes,
    required this.comments,
    this.createdAt,
    this.allowShare = true,
  });
}
