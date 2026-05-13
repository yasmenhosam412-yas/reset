import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';

enum HomeStatus {
  initial,
  loading,
  loaded,
  failure
}

enum HomeSuccessType {
  postCreated,
  postDeleted,
  postUpdated,
  postSaved,
  postUnsaved,
  alreadyFriends,
  friendRequestSent,
  friendRequestWithdrawn,
  challengeSent,
  userBlocked,
  userReported,
}

class HomeState {
  const HomeState({
    required this.status,
    required this.posts,
    this.acceptedFriendUserIds = const {},
    this.pendingOutgoingFriendUserIds = const {},
    this.savedPostIds = const {},
    this.savedPostsOverlay = const [],
    this.savedPostsLoading = false,
    this.errorMessage,
    this.successMessage,
    this.successType,
    this.successName,
    this.successGameId,
  });

  factory HomeState.initial() {
    return const HomeState(
      status: HomeStatus.initial,
      posts: [],
    );
  }

  final HomeStatus status;
  final List<PostModel> posts;
  /// Other users with an accepted friend relationship to the signed-in user.
  final Set<String> acceptedFriendUserIds;
  /// Users the signed-in user has sent a pending friend request to.
  final Set<String> pendingOutgoingFriendUserIds;
  /// Post ids the signed-in user has bookmarked (includes items not currently in [posts]).
  final Set<String> savedPostIds;
  /// Full models for the Saved-posts screen (ordered by server).
  final List<PostModel> savedPostsOverlay;
  final bool savedPostsLoading;
  final String? errorMessage;
  final String? successMessage;
  final HomeSuccessType? successType;
  final String? successName;
  final int? successGameId;

  HomeState copyWith({
    HomeStatus? status,
    List<PostModel>? posts,
    Set<String>? acceptedFriendUserIds,
    Set<String>? pendingOutgoingFriendUserIds,
    Set<String>? savedPostIds,
    List<PostModel>? savedPostsOverlay,
    bool? savedPostsLoading,
    String? errorMessage,
    String? successMessage,
    HomeSuccessType? successType,
    String? successName,
    int? successGameId,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      acceptedFriendUserIds:
          acceptedFriendUserIds ?? this.acceptedFriendUserIds,
      pendingOutgoingFriendUserIds:
          pendingOutgoingFriendUserIds ?? this.pendingOutgoingFriendUserIds,
      savedPostIds: savedPostIds ?? this.savedPostIds,
      savedPostsOverlay: savedPostsOverlay ?? this.savedPostsOverlay,
      savedPostsLoading: savedPostsLoading ?? this.savedPostsLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      successType: clearSuccess ? null : (successType ?? this.successType),
      successName: clearSuccess ? null : (successName ?? this.successName),
      successGameId: clearSuccess ? null : (successGameId ?? this.successGameId),
    );
  }
}
