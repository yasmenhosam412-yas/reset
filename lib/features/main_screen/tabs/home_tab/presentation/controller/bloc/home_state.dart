import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';

enum HomeStatus {
  initial,
  loading,
  loaded,
  failure,
}

class HomeState {
  const HomeState({
    required this.status,
    required this.posts,
    this.errorMessage,
  });

  factory HomeState.initial() {
    return const HomeState(
      status: HomeStatus.initial,
      posts: [],
    );
  }

  final HomeStatus status;
  final List<PostModel> posts;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    List<PostModel>? posts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
