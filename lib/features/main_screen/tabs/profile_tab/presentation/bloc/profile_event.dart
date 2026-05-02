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
