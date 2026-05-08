import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/comment_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/entities/post_entity.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/post_reactions_codec.dart';

class PostModel extends PostEntity {
  PostModel({
    required super.id,
    required super.userModel,
    required super.postImage,
    required super.postContent,
    required super.likes,
    required super.comments,
    super.createdAt,
    super.allowShare,
    super.postVisibility,
    super.postType,
    super.adLink,
  });

  PostModel copyWith({
    String? id,
    UserModel? userModel,
    String? postImage,
    String? postContent,
    List<String>? likes,
    List<CommentModel>? comments,
    DateTime? createdAt,
    bool? allowShare,
    String? postVisibility,
    String? postType,
    String? adLink,
  }) {
    return PostModel(
      id: id ?? this.id,
      userModel: userModel ?? this.userModel,
      postImage: postImage ?? this.postImage,
      postContent: postContent ?? this.postContent,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      allowShare: allowShare ?? this.allowShare,
      postVisibility: postVisibility ?? this.postVisibility,
      postType: postType ?? this.postType,
      adLink: adLink ?? this.adLink,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final user = userJson is Map
        ? UserModel.fromJson(Map<String, dynamic>.from(userJson))
        : UserModel(
            id: json['author_id']?.toString() ?? '',
            username: (json['author'] ?? json['username'] ?? 'Unknown').toString(),
            avatarUrl: json['author_avatar_url'] as String?,
          );

    return PostModel(
      id: json['id']?.toString() ?? '',
      userModel: user,
      postImage: json['post_image'] as String? ?? '',
      postContent: json['post_content'] as String? ?? '',
      likes: normalizeLikesJson(json['likes']),
      comments: (json['comments'] as List? ?? const [])
          .map(
            (e) => CommentModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      createdAt: _parseDateTime(json['created_at']),
      allowShare: _parseAllowShare(json['allow_share']),
      postVisibility: _parsePostVisibility(json['post_visibility']),
      postType: _parsePostType(json['post_type']),
      adLink: _parseAdLink(json['ad_link']),
    );
  }

  static bool _parseAllowShare(dynamic raw) {
    if (raw == null) return true;
    if (raw is bool) return raw;
    if (raw is String) {
      final s = raw.toLowerCase();
      return s == 'true' || s == 't' || s == '1';
    }
    return true;
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static String _parsePostVisibility(dynamic raw) {
    final v = (raw?.toString() ?? '').trim().toLowerCase();
    if (v == 'friends') return 'friends';
    return 'general';
  }

  static String _parsePostType(dynamic raw) {
    final v = (raw?.toString() ?? '').trim().toLowerCase();
    switch (v) {
      case 'announcement':
      case 'celebration':
      case 'ads':
        return v;
      default:
        return 'post';
    }
  }

  static String? _parseAdLink(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }
}
