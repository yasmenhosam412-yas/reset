import 'dart:typed_data';

abstract class ProfileEvent {}

final class ProfileLoadRequested extends ProfileEvent {}

final class ProfileFriendRequestResponded extends ProfileEvent {
  ProfileFriendRequestResponded({
    required this.requestId,
    required this.accept,
  });

  final String requestId;
  final bool accept;
}

final class ProfileEdited extends ProfileEvent {
  ProfileEdited({
    required this.username,
    this.avatarBytes,
    this.avatarContentType,
  });

  final String username;
  final Uint8List? avatarBytes;
  final String? avatarContentType;
}

final class ProfileMatchInvitesChanged extends ProfileEvent {
  ProfileMatchInvitesChanged(this.accepts);

  final bool accepts;
}

final class ProfilePushNotificationsChanged extends ProfileEvent {
  ProfilePushNotificationsChanged(this.enabled);

  final bool enabled;
}


