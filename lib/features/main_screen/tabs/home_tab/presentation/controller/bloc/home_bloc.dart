import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_comment_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/post_reactions_codec.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_like_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/delete_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/update_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_accepted_friend_ids_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_posts_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/send_home_challenge_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/send_home_friend_request_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_titles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetHomePostsUsecase getHomePostsUsecase,
    required GetHomeAcceptedFriendIdsUsecase getHomeAcceptedFriendIdsUsecase,
    required AddHomePostUsecase addHomePostUsecase,
    required DeleteHomePostUsecase deleteHomePostUsecase,
    required UpdateHomePostUsecase updateHomePostUsecase,
    required AddHomeCommentUsecase addHomeCommentUsecase,
    required AddHomePostLikeUsecase addHomePostLikeUsecase,
    required SendHomeFriendRequestUsecase sendHomeFriendRequestUsecase,
    required SendHomeChallengeUsecase sendHomeChallengeUsecase,
  })  : _getHomePostsUsecase = getHomePostsUsecase,
        _getHomeAcceptedFriendIdsUsecase = getHomeAcceptedFriendIdsUsecase,
        _addHomePostUsecase = addHomePostUsecase,
        _deleteHomePostUsecase = deleteHomePostUsecase,
        _updateHomePostUsecase = updateHomePostUsecase,
        _addHomeCommentUsecase = addHomeCommentUsecase,
        _addHomePostLikeUsecase = addHomePostLikeUsecase,
        _sendHomeFriendRequestUsecase = sendHomeFriendRequestUsecase,
        _sendHomeChallengeUsecase = sendHomeChallengeUsecase,
        super(HomeState.initial()) {
    on<HomePostsRequested>(_onPostsRequested);
    on<HomePostCreateRequested>(_onPostCreateRequested);
    on<HomePostDeleteRequested>(_onPostDeleteRequested);
    on<HomePostUpdateRequested>(_onPostUpdateRequested);
    on<HomeCommentCreateRequested>(_onCommentCreateRequested);
    on<HomePostReactionRequested>(_onPostReactionRequested);
    on<HomeSendFriendRequest>(_onSendFriendRequest);
    on<HomeSendChallenge>(_onSendChallenge);
  }

  final GetHomePostsUsecase _getHomePostsUsecase;
  final GetHomeAcceptedFriendIdsUsecase _getHomeAcceptedFriendIdsUsecase;
  final AddHomePostUsecase _addHomePostUsecase;
  final DeleteHomePostUsecase _deleteHomePostUsecase;
  final UpdateHomePostUsecase _updateHomePostUsecase;
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
      allowShare: event.allowShare,
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

  Future<void> _onPostDeleteRequested(
    HomePostDeleteRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final del = await _deleteHomePostUsecase(postId: event.postId);

    final failure = del.fold((l) => l, (_) => null);
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
            successMessage: 'Post deleted',
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _onPostUpdateRequested(
    HomePostUpdateRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final upd = await _updateHomePostUsecase(
      postId: event.postId,
      postContent: event.postContent,
      imageBytes: event.imageBytes,
      imageContentType: event.imageContentType,
      clearImage: event.clearImage,
      allowShare: event.allowShare,
    );

    final failure = upd.fold((l) => l, (_) => null);
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
            successMessage: 'Post updated',
            clearError: true,
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

  Future<void> _onPostReactionRequested(
    HomePostReactionRequested event,
    Emitter<HomeState> emit,
  ) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final previousPosts = state.posts;
    final optimistic = _postsWithReaction(
      previousPosts,
      event.postId,
      uid,
      event.reaction,
    );
    emit(
      state.copyWith(
        posts: optimistic,
        status: HomeStatus.loaded,
        clearError: true,
      ),
    );

    final likeResult = await _addHomePostLikeUsecase(
      postId: event.postId,
      reaction: event.reaction,
    );
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
          successMessage:
              '${onlineGameTitle(event.gameId)} challenge sent to $name',
          clearError: true,
        ),
      ),
    );
  }
}

List<PostModel> _postsWithReaction(
  List<PostModel> posts,
  String postId,
  String userId,
  String? reaction,
) {
  return posts
      .map((p) {
        if (p.id != postId) return p;
        final next = List<String>.from(p.likes);
        final uNorm = userId.trim().toLowerCase();
        next.removeWhere(
          (e) => postReactionEntryUserId(e).trim().toLowerCase() == uNorm,
        );
        final r = reaction?.trim().toLowerCase();
        if (r != null &&
            r.isNotEmpty &&
            kPostReactionKeys.contains(r)) {
          next.add(encodePostReactionEntry(userId, r));
        }
        return p.copyWith(likes: next);
      })
      .toList(growable: false);
}
