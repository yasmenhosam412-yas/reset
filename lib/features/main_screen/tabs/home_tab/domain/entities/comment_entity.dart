import 'package:new_project/features/authentication/data/models/user_model.dart';

class CommentEntity {
  final UserModel userModel;
  final String comment;

  CommentEntity({required this.userModel, required this.comment});
}
