import 'package:json_annotation/json_annotation.dart';
import 'package:new_project/features/authentication/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'user_model.g.dart';

@JsonSerializable(createToJson: false)
class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.username,
    @JsonKey(name: "avatar_url") super.avatarUrl,
  });

  factory UserModel.fromSupabaseUser(User user) {
    final metaData = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      username: metaData['username'] as String? ?? "",
      avatarUrl: metaData['avatar_url'] as String? ?? "",
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
