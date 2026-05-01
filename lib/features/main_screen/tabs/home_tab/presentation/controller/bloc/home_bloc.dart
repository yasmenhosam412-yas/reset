import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_comment_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_like_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_posts_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetHomePostsUsecase getHomePostsUsecase,
    required AddHomePostUsecase addHomePostUsecase,
    required AddHomeCommentUsecase addHomeCommentUsecase,
    required AddHomePostLikeUsecase addHomePostLikeUsecase,
  })  : _getHomePostsUsecase = getHomePostsUsecase,
        _addHomePostUsecase = addHomePostUsecase,
        _addHomeCommentUsecase = addHomeCommentUsecase,
        _addHomePostLikeUsecase = addHomePostLikeUsecase,
        super(HomeState.initial()) {
    on<HomePostsRequested>(_onPostsRequested);
    on<HomePostCreateRequested>(_onPostCreateRequested);
    on<HomeCommentCreateRequested>(_onCommentCreateRequested);
    on<HomePostLikeRequested>(_onPostLikeRequested);
  }

  final GetHomePostsUsecase _getHomePostsUsecase;
  final AddHomePostUsecase _addHomePostUsecase;
  final AddHomeCommentUsecase _addHomeCommentUsecase;
  final AddHomePostLikeUsecase _addHomePostLikeUsecase;

  Future<void> _onPostsRequested(
    HomePostsRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final result = await _getHomePostsUsecase();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HomeStatus.failure,
          posts: const [],
          errorMessage: failure.message,
        ),
      ),
      (posts) => emit(
        state.copyWith(
          status: HomeStatus.loaded,
          posts: List.of(posts, growable: false),
        ),
      ),
    );
  }

  Future<void> _onPostCreateRequested(
    HomePostCreateRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final addResult = await _addHomePostUsecase(
      postContent: event.postContent,
      postImage: event.postImage,
      imageBytes: event.imageBytes,
      imageContentType: event.imageContentType,
    );

    final failure = addResult.fold((l) => l, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: failure.message,
        ),
      );
      return;
    }

    final listResult = await _getHomePostsUsecase();
    listResult.fold(
      (f) => emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: f.message,
        ),
      ),
      (posts) => emit(
        state.copyWith(
          status: HomeStatus.loaded,
          posts: List.of(posts, growable: false),
        ),
      ),
    );
  }

  Future<void> _onCommentCreateRequested(
    HomeCommentCreateRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final addResult = await _addHomeCommentUsecase(
      postId: event.postId,
      comment: event.comment,
    );

    final failure = addResult.fold((l) => l, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: failure.message,
        ),
      );
      return;
    }

    final listResult = await _getHomePostsUsecase();
    listResult.fold(
      (f) => emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: f.message,
        ),
      ),
      (posts) => emit(
        state.copyWith(
          status: HomeStatus.loaded,
          posts: List.of(posts, growable: false),
        ),
      ),
    );
  }

  Future<void> _onPostLikeRequested(
    HomePostLikeRequested event,
    Emitter<HomeState> emit,
  ) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final previousPosts = state.posts;
    final optimistic = _postsWithToggledLike(previousPosts, event.postId, uid);
    emit(
      state.copyWith(
        posts: optimistic,
        status: HomeStatus.loaded,
        clearError: true,
      ),
    );

    final likeResult = await _addHomePostLikeUsecase(postId: event.postId);
    likeResult.fold(
      (failure) => emit(
        state.copyWith(
          posts: previousPosts,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }
}

List<PostModel> _postsWithToggledLike(
  List<PostModel> posts,
  String postId,
  String userId,
) {
  return posts
      .map((p) {
        if (p.id != postId) return p;
        final next = List<String>.from(p.likes);
        if (next.contains(userId)) {
          next.remove(userId);
        } else {
          next.add(userId);
        }
        return p.copyWith(likes: next);
      })
      .toList(growable: false);
}
