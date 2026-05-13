import 'package:new_project/features/authentication/data/models/user_model.dart';

class CommentEntity {
  final String id;
  final UserModel userModel;
  final String comment;

  CommentEntity({
    required this.id,
    required this.userModel,
    required this.comment,
  });
}
