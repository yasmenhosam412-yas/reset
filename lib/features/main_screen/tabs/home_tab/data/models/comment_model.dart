import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  CommentModel({required super.userModel, required super.comment});

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is Map) {
      return CommentModel(
        userModel: UserModel.fromJson(Map<String, dynamic>.from(userJson)),
        comment: json['comment'] as String? ?? json['text'] as String? ?? '',
      );
    }
    return CommentModel(
      userModel: UserModel(
        id: json['author_id']?.toString() ?? '',
        username: (json['author'] ?? json['username'] ?? 'Unknown').toString(),
        avatarUrl: json['avatar_url'] as String?,
      ),
      comment: json['comment'] as String? ?? json['text'] as String? ?? '',
    );
  }
}
