import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_comment_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_like_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_accepted_friend_ids_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_posts_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/send_home_challenge_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/send_home_friend_request_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetHomePostsUsecase getHomePostsUsecase,
    required GetHomeAcceptedFriendIdsUsecase getHomeAcceptedFriendIdsUsecase,
    required AddHomePostUsecase addHomePostUsecase,
    required AddHomeCommentUsecase addHomeCommentUsecase,
    required AddHomePostLikeUsecase addHomePostLikeUsecase,
    required SendHomeFriendRequestUsecase sendHomeFriendRequestUsecase,
    required SendHomeChallengeUsecase sendHomeChallengeUsecase,
  })  : _getHomePostsUsecase = getHomePostsUsecase,
        _getHomeAcceptedFriendIdsUsecase = getHomeAcceptedFriendIdsUsecase,
        _addHomePostUsecase = addHomePostUsecase,
        _addHomeCommentUsecase = addHomeCommentUsecase,
        _addHomePostLikeUsecase = addHomePostLikeUsecase,
        _sendHomeFriendRequestUsecase = sendHomeFriendRequestUsecase,
        _sendHomeChallengeUsecase = sendHomeChallengeUsecase,
        super(HomeState.initial()) {
    on<HomePostsRequested>(_onPostsRequested);
    on<HomePostCreateRequested>(_onPostCreateRequested);
    on<HomeCommentCreateRequested>(_onCommentCreateRequested);
    on<HomePostLikeRequested>(_onPostLikeRequested);
    on<HomeSendFriendRequest>(_onSendFriendRequest);
    on<HomeSendChallenge>(_onSendChallenge);
  }

  final GetHomePostsUsecase _getHomePostsUsecase;
  final GetHomeAcceptedFriendIdsUsecase _getHomeAcceptedFriendIdsUsecase;
  final AddHomePostUsecase _addHomePostUsecase;
  final AddHomeCommentUsecase _addHomeCommentUsecase;
  final AddHomePostLikeUsecase _addHomePostLikeUsecase;
  final SendHomeFriendRequestUsecase _sendHomeFriendRequestUsecase;
  final SendHomeChallengeUsecase _sendHomeChallengeUsecase;

  Future<Set<String>> _fetchAcceptedFriendIds() async {
    final r = await _getHomeAcceptedFriendIdsUsecase();
    return r.fold(
      (_) => <String>{},
      (s) => s.map((e) => e.trim().toLowerCase()).toSet(),
    );
  }

  Future<void> _onPostsRequested(
    HomePostsRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final result = await _getHomePostsUsecase();
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: HomeStatus.failure,
          posts: const [],
          acceptedFriendUserIds: const {},
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (posts) async {
        final friendIds = await _fetchAcceptedFriendIds();
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            posts: List.of(posts, growable: false),
            acceptedFriendUserIds: friendIds,
            clearSuccess: true,
          ),
        );
      },
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
          clearSuccess: true,
        ),
      );
      return;
    }

    final listResult = await _getHomePostsUsecase();
    await listResult.fold(
      (f) async => emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: f.message,
          clearSuccess: true,
        ),
      ),
      (posts) async {
        final friendIds = await _fetchAcceptedFriendIds();
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            posts: List.of(posts, growable: false),
            acceptedFriendUserIds: friendIds,
            clearSuccess: true,
          ),
        );
      },
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
          clearSuccess: true,
        ),
      );
      return;
    }

    final listResult = await _getHomePostsUsecase();
    await listResult.fold(
      (f) async => emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: f.message,
          clearSuccess: true,
        ),
      ),
      (posts) async {
        final friendIds = await _fetchAcceptedFriendIds();
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            posts: List.of(posts, growable: false),
            acceptedFriendUserIds: friendIds,
            clearSuccess: true,
          ),
        );
      },
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
          clearSuccess: true,
        ),
      ),
      (_) {},
    );
  }

  Future<void> _onSendFriendRequest(
    HomeSendFriendRequest event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));
    final name = event.userModel.username.trim().isEmpty
        ? 'User'
        : event.userModel.username.trim();
    final targetId = event.userModel.id.trim().toLowerCase();
    if (targetId.isNotEmpty &&
        state.acceptedFriendUserIds.contains(targetId)) {
      emit(
        state.copyWith(
          successMessage: 'You are already friends with $name.',
          clearError: true,
        ),
      );
      return;
    }
    final result = await _sendHomeFriendRequestUsecase(event.userModel);
    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (_) => emit(
        state.copyWith(
          successMessage: 'Friend request sent to $name',
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onSendChallenge(
    HomeSendChallenge event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));
    final name = event.userModel.username.trim().isEmpty
        ? 'User'
        : event.userModel.username.trim();
    final result = await _sendHomeChallengeUsecase(
      event.userModel,
      event.gameId,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (_) => emit(
        state.copyWith(
          successMessage: 'Challenge sent to $name',
          clearError: true,
        ),
      ),
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
