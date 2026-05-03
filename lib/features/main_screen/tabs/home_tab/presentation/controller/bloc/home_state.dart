import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';

enum HomeStatus {
  initial,
  loading,
  loaded,
  failure
}

class HomeState {
  const HomeState({
    required this.status,
    required this.posts,
    this.acceptedFriendUserIds = const {},
    this.errorMessage,
    this.successMessage,
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
  final String? errorMessage;
  final String? successMessage;

  HomeState copyWith({
    HomeStatus? status,
    List<PostModel>? posts,
    Set<String>? acceptedFriendUserIds,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      acceptedFriendUserIds:
          acceptedFriendUserIds ?? this.acceptedFriendUserIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}
