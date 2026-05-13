/// Row from [HomeTable.userNotifications] (likes, comments, friend requests).
class UserFeedNotificationModel {
  const UserFeedNotificationModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.data,
    this.createdAt,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  factory UserFeedNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return UserFeedNotificationModel(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: rawData is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawData)
          : rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : <String, dynamic>{},
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

abstract final class UserNotificationKind {
  static const postLike = 'post_like';
  static const postComment = 'post_comment';
  static const friendRequest = 'friend_request';
  static const partyRoomInvite = 'party_room_invite';
  static const commentMention = 'comment_mention';
}
