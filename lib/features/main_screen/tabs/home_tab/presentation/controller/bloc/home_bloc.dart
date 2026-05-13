import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_comment_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/delete_home_comment_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/block_home_user_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/report_home_user_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/post_reactions_codec.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_like_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/delete_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/update_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_accepted_friend_ids_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_pending_outgoing_friend_ids_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_posts_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_saved_post_ids_among_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_saved_posts_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/set_home_post_saved_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/send_home_challenge_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/send_home_friend_request_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/withdraw_home_friend_request_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetHomePostsUsecase getHomePostsUsecase,
    required GetHomeAcceptedFriendIdsUsecase getHomeAcceptedFriendIdsUsecase,
    required GetHomePendingOutgoingFriendIdsUsecase
    getHomePendingOutgoingFriendIdsUsecase,
    required AddHomePostUsecase addHomePostUsecase,
    required DeleteHomePostUsecase deleteHomePostUsecase,
    required UpdateHomePostUsecase updateHomePostUsecase,
    required AddHomeCommentUsecase addHomeCommentUsecase,
    required DeleteHomeCommentUsecase deleteHomeCommentUsecase,
    required BlockHomeUserUsecase blockHomeUserUsecase,
    required ReportHomeUserUsecase reportHomeUserUsecase,
    required AddHomePostLikeUsecase addHomePostLikeUsecase,
    required SendHomeFriendRequestUsecase sendHomeFriendRequestUsecase,
    required WithdrawHomeFriendRequestUsecase withdrawHomeFriendRequestUsecase,
    required SendHomeChallengeUsecase sendHomeChallengeUsecase,
    required GetHomeSavedPostIdsAmongUsecase getHomeSavedPostIdsAmongUsecase,
    required SetHomePostSavedUsecase setHomePostSavedUsecase,
    required GetHomeSavedPostsUsecase getHomeSavedPostsUsecase,
  }) : _getHomePostsUsecase = getHomePostsUsecase,
       _getHomeAcceptedFriendIdsUsecase = getHomeAcceptedFriendIdsUsecase,
       _getHomePendingOutgoingFriendIdsUsecase =
           getHomePendingOutgoingFriendIdsUsecase,
       _addHomePostUsecase = addHomePostUsecase,
       _deleteHomePostUsecase = deleteHomePostUsecase,
       _updateHomePostUsecase = updateHomePostUsecase,
       _addHomeCommentUsecase = addHomeCommentUsecase,
       _deleteHomeCommentUsecase = deleteHomeCommentUsecase,
       _blockHomeUserUsecase = blockHomeUserUsecase,
       _reportHomeUserUsecase = reportHomeUserUsecase,
       _addHomePostLikeUsecase = addHomePostLikeUsecase,
       _sendHomeFriendRequestUsecase = sendHomeFriendRequestUsecase,
       _withdrawHomeFriendRequestUsecase = withdrawHomeFriendRequestUsecase,
       _sendHomeChallengeUsecase = sendHomeChallengeUsecase,
       _getHomeSavedPostIdsAmongUsecase = getHomeSavedPostIdsAmongUsecase,
       _setHomePostSavedUsecase = setHomePostSavedUsecase,
       _getHomeSavedPostsUsecase = getHomeSavedPostsUsecase,
       super(HomeState.initial()) {
    on<HomePostsRequested>(_onPostsRequested);
    on<HomePostCreateRequested>(_onPostCreateRequested);
    on<HomePostDeleteRequested>(_onPostDeleteRequested);
    on<HomePostUpdateRequested>(_onPostUpdateRequested);
    on<HomeCommentCreateRequested>(_onCommentCreateRequested);
    on<HomeCommentDeleteRequested>(_onCommentDeleteRequested);
    on<HomeUserBlockRequested>(_onUserBlockRequested);
    on<HomeUserReportRequested>(_onUserReportRequested);
    on<HomePostReactionRequested>(_onPostReactionRequested);
    on<HomeSendFriendRequest>(_onSendFriendRequest);
    on<HomeWithdrawFriendRequest>(_onWithdrawFriendRequest);
    on<HomeSendChallenge>(_onSendChallenge);
    on<HomePostSaveToggled>(_onPostSaveToggled);
    on<HomeSavedPostsLoadRequested>(_onSavedPostsLoadRequested);
    on<ResetHomeEvent>(_onResetHome);
  }

  final GetHomePostsUsecase _getHomePostsUsecase;
  final GetHomeAcceptedFriendIdsUsecase _getHomeAcceptedFriendIdsUsecase;
  final GetHomePendingOutgoingFriendIdsUsecase
  _getHomePendingOutgoingFriendIdsUsecase;
  final AddHomePostUsecase _addHomePostUsecase;
  final DeleteHomePostUsecase _deleteHomePostUsecase;
  final UpdateHomePostUsecase _updateHomePostUsecase;
  final AddHomeCommentUsecase _addHomeCommentUsecase;
  final DeleteHomeCommentUsecase _deleteHomeCommentUsecase;
  final BlockHomeUserUsecase _blockHomeUserUsecase;
  final ReportHomeUserUsecase _reportHomeUserUsecase;
  final AddHomePostLikeUsecase _addHomePostLikeUsecase;
  final SendHomeFriendRequestUsecase _sendHomeFriendRequestUsecase;
  final WithdrawHomeFriendRequestUsecase _withdrawHomeFriendRequestUsecase;
  final SendHomeChallengeUsecase _sendHomeChallengeUsecase;
  final GetHomeSavedPostIdsAmongUsecase _getHomeSavedPostIdsAmongUsecase;
  final SetHomePostSavedUsecase _setHomePostSavedUsecase;
  final GetHomeSavedPostsUsecase _getHomeSavedPostsUsecase;
  int _lastLimit = 20;
  int _lastOffset = 0;

  Future<Set<String>> _fetchAcceptedFriendIds() async {
    final r = await _getHomeAcceptedFriendIdsUsecase();
    return r.fold(
      (_) => <String>{},
      (s) => s.map((e) => e.trim().toLowerCase()).toSet(),
    );
  }

  Future<Set<String>> _fetchPendingOutgoingFriendIds() async {
    final r = await _getHomePendingOutgoingFriendIdsUsecase();
    return r.fold(
      (_) => <String>{},
      (s) => s.map((e) => e.trim().toLowerCase()).toSet(),
    );
  }

  Future<({Set<String> accepted, Set<String> pendingOutgoing})>
  _fetchFriendLinkSets() async {
    final accepted = await _fetchAcceptedFriendIds();
    final pendingOutgoing = await _fetchPendingOutgoingFriendIds();
    return (accepted: accepted, pendingOutgoing: pendingOutgoing);
  }

  Future<void> _onPostsRequested(
    HomePostsRequested event,
    Emitter<HomeState> emit,
  ) async {
    _lastLimit = event.limit;
    _lastOffset = event.offset;
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final result = await _getHomePostsUsecase(
      limit: event.limit,
      offset: event.offset,
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: HomeStatus.failure,
          posts: const [],
          acceptedFriendUserIds: const {},
          pendingOutgoingFriendUserIds: const {},
          savedPostIds: const {},
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (posts) async {
        final links = await _fetchFriendLinkSets();
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            posts: List.of(posts, growable: false),
            acceptedFriendUserIds: links.accepted,
            pendingOutgoingFriendUserIds: links.pendingOutgoing,
            clearSuccess: true,
          ),
        );
        await _mergeSavedIdsForCurrentPosts(emit, posts);
      },
    );
  }

  Future<void> _reloadPosts(
    Emitter<HomeState> emit, {
    HomeSuccessType? successType,
    String? successName,
    int? successGameId,
  }) async {
    final listResult = await _getHomePostsUsecase(
      limit: _lastLimit,
      offset: _lastOffset,
    );
    await listResult.fold(
      (f) async => emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: f.message,
          clearSuccess: true,
        ),
      ),
      (posts) async {
        final links = await _fetchFriendLinkSets();
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            posts: List.of(posts, growable: false),
            acceptedFriendUserIds: links.accepted,
            pendingOutgoingFriendUserIds: links.pendingOutgoing,
            successType: successType,
            successName: successName,
            successGameId: successGameId,
            clearError: true,
            clearSuccess: successType == null,
          ),
        );
        await _mergeSavedIdsForCurrentPosts(emit, posts);
      },
    );
  }

  Future<void> _onPostCreateRequested(
    HomePostCreateRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: HomeStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    final addResult = await _addHomePostUsecase(
      postContent: event.postContent,
      postImage: event.postImage,
      imageBytes: event.imageBytes,
      imageContentType: event.imageContentType,
      mediaLocalPath: event.mediaLocalPath,
      allowShare: event.allowShare,
      postVisibility: event.postVisibility,
      postType: event.postType,
      adLink: event.adLink,
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
    await _reloadPosts(emit, successType: HomeSuccessType.postCreated);
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
    await _reloadPosts(emit, successType: HomeSuccessType.postDeleted);
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
      postVisibility: event.postVisibility,
      postType: event.postType,
      adLink: event.adLink,
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
    await _reloadPosts(emit, successType: HomeSuccessType.postUpdated);
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
    await _reloadPosts(emit);
    await _refreshSavedOverlayIfShowingPost(emit, event.postId);
  }

  Future<void> _onCommentDeleteRequested(
    HomeCommentDeleteRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final delResult = await _deleteHomeCommentUsecase(
      commentId: event.commentId,
    );

    final failure = delResult.fold((l) => l, (_) => null);
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
    await _reloadPosts(emit);
    await _refreshSavedOverlayIfShowingPost(emit, event.postId);
  }

  Future<void> _onUserBlockRequested(
    HomeUserBlockRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final r = await _blockHomeUserUsecase(blockedUserId: event.blockedUserId);
    final failure = r.fold((l) => l, (_) => null);
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
    await _reloadPosts(emit, successType: HomeSuccessType.userBlocked);
    await _refreshSavedPostsOverlayIfNonEmpty(emit);
  }

  Future<void> _onUserReportRequested(
    HomeUserReportRequested event,
    Emitter<HomeState> emit,
  ) async {
    final r = await _reportHomeUserUsecase(
      reportedUserId: event.reportedUserId,
      reason: event.reason,
      details: event.details,
      context: event.context,
    );
    final failure = r.fold((l) => l, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      );
      return;
    }
    emit(state.copyWith(clearSuccess: true));
    emit(
      state.copyWith(
        successType: HomeSuccessType.userReported,
        clearError: true,
      ),
    );
  }

  Future<void> _refreshSavedPostsOverlayIfNonEmpty(
    Emitter<HomeState> emit,
  ) async {
    if (state.savedPostsOverlay.isEmpty) return;
    final r = await _getHomeSavedPostsUsecase(limit: 80, offset: 0);
    await r.fold(
      (_) async {},
      (posts) async {
        final ids = posts
            .map((p) => p.id.trim())
            .where((e) => e.isNotEmpty)
            .toSet();
        emit(
          state.copyWith(
            savedPostsOverlay: List.of(posts, growable: false),
            savedPostIds: {...state.savedPostIds, ...ids},
          ),
        );
      },
    );
  }

  Future<void> _refreshSavedOverlayIfShowingPost(
    Emitter<HomeState> emit,
    String postId,
  ) async {
    final pid = postId.trim();
    if (pid.isEmpty) return;
    if (!state.savedPostsOverlay.any((p) => p.id.trim() == pid)) return;
    final r = await _getHomeSavedPostsUsecase(limit: 80, offset: 0);
    await r.fold(
      (_) async {},
      (posts) async {
        emit(
          state.copyWith(
            savedPostsOverlay: List.of(posts, growable: false),
            savedPostIds: {
              ...state.savedPostIds,
              ...posts.map((p) => p.id.trim()).where((e) => e.isNotEmpty),
            },
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
    final previousOverlay = state.savedPostsOverlay;
    final optimistic = _postsWithReaction(
      previousPosts,
      event.postId,
      uid,
      event.reaction,
    );
    final optimisticOverlay = _postsWithReaction(
      previousOverlay,
      event.postId,
      uid,
      event.reaction,
    );
    emit(
      state.copyWith(
        posts: optimistic,
        savedPostsOverlay: optimisticOverlay,
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
          savedPostsOverlay: previousOverlay,
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
        ? ''
        : event.userModel.username.trim();
    final targetId = event.userModel.id.trim().toLowerCase();
    if (targetId.isNotEmpty && state.acceptedFriendUserIds.contains(targetId)) {
      emit(
        state.copyWith(
          successType: HomeSuccessType.alreadyFriends,
          successName: name,
          clearError: true,
        ),
      );
      return;
    }
    final result = await _sendHomeFriendRequestUsecase(event.userModel);
    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message, clearSuccess: true),
      ),
      (_) {
        final nextPending = targetId.isNotEmpty
            ? {...state.pendingOutgoingFriendUserIds, targetId}
            : state.pendingOutgoingFriendUserIds;
        emit(
          state.copyWith(
            successType: HomeSuccessType.friendRequestSent,
            successName: name,
            clearError: true,
            pendingOutgoingFriendUserIds: nextPending,
          ),
        );
      },
    );
  }

  Future<void> _onWithdrawFriendRequest(
    HomeWithdrawFriendRequest event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));
    final name = event.userModel.username.trim().isEmpty
        ? ''
        : event.userModel.username.trim();
    final targetId = event.userModel.id.trim().toLowerCase();
    final result = await _withdrawHomeFriendRequestUsecase(event.userModel);
    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message, clearSuccess: true),
      ),
      (_) {
        final next = Set<String>.from(state.pendingOutgoingFriendUserIds);
        if (targetId.isNotEmpty) next.remove(targetId);
        emit(
          state.copyWith(
            successType: HomeSuccessType.friendRequestWithdrawn,
            successName: name,
            clearError: true,
            pendingOutgoingFriendUserIds: next,
          ),
        );
      },
    );
  }

  Future<void> _onSendChallenge(
    HomeSendChallenge event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));
    final name = event.userModel.username.trim().isEmpty
        ? ''
        : event.userModel.username.trim();
    final result = await _sendHomeChallengeUsecase(
      event.userModel,
      event.gameId,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message, clearSuccess: true),
      ),
      (_) => emit(
        state.copyWith(
          successType: HomeSuccessType.challengeSent,
          successName: name,
          successGameId: event.gameId,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _mergeSavedIdsForCurrentPosts(
    Emitter<HomeState> emit,
    List<PostModel> posts,
  ) async {
    final ids = posts.map((p) => p.id.trim()).where((e) => e.isNotEmpty);
    final idList = ids.toList(growable: false);
    if (idList.isEmpty) return;
    final r = await _getHomeSavedPostIdsAmongUsecase(idList);
    await r.fold(
      (_) async {},
      (among) async {
        emit(
          state.copyWith(
            savedPostIds: {...state.savedPostIds, ...among},
          ),
        );
      },
    );
  }

  Future<void> _onPostSaveToggled(
    HomePostSaveToggled event,
    Emitter<HomeState> emit,
  ) async {
    final id = event.postId.trim();
    if (id.isEmpty) return;
    final want = event.saved;
    final previousIds = Set<String>.from(state.savedPostIds);
    final nextIds = Set<String>.from(state.savedPostIds);
    if (want) {
      nextIds.add(id);
    } else {
      nextIds.remove(id);
    }
    emit(state.copyWith(savedPostIds: nextIds, clearError: true));

    final r = await _setHomePostSavedUsecase(postId: id, saved: want);
    r.fold(
      (failure) => emit(
        state.copyWith(
          savedPostIds: previousIds,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (_) {
        final clearedOverlay = want
            ? state.savedPostsOverlay
            : state.savedPostsOverlay
                  .where((p) => p.id.trim() != id)
                  .toList(growable: false);
        emit(
          state.copyWith(
            savedPostsOverlay: clearedOverlay,
            successType: want
                ? HomeSuccessType.postSaved
                : HomeSuccessType.postUnsaved,
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _onSavedPostsLoadRequested(
    HomeSavedPostsLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(savedPostsLoading: true, clearError: true));
    final r = await _getHomeSavedPostsUsecase(
      limit: event.limit,
      offset: event.offset,
    );
    await r.fold(
      (failure) async => emit(
        state.copyWith(
          savedPostsLoading: false,
          errorMessage: failure.message,
          clearSuccess: true,
        ),
      ),
      (posts) async {
        final ids = posts
            .map((p) => p.id.trim())
            .where((e) => e.isNotEmpty)
            .toSet();
        emit(
          state.copyWith(
            savedPostsLoading: false,
            savedPostsOverlay: List.of(posts, growable: false),
            savedPostIds: {...state.savedPostIds, ...ids},
            clearSuccess: true,
          ),
        );
      },
    );
  }

  FutureOr<void> _onResetHome(ResetHomeEvent event, Emitter<HomeState> emit) {
    emit(HomeState.initial());
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
        if (r != null && r.isNotEmpty && kPostReactionKeys.contains(r)) {
          next.add(encodePostReactionEntry(userId, r));
        }
        return p.copyWith(likes: next);
      })
      .toList(growable: false);
}
