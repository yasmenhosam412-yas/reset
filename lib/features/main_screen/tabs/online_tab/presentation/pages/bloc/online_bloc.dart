import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/send_home_challenge_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/change_online_challenge_status_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/get_online_challenges_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/get_online_friends_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/set_online_challenge_ready_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineBloc extends Bloc<OnlineEvent, OnlineState> {
  OnlineBloc({
    required GetOnlineFriendsUsecase getOnlineFriendsUsecase,
    required GetOnlineChallengesUsecase getOnlineChallengesUsecase,
    required ChangeOnlineChallengeStatusUsecase
    changeOnlineChallengeStatusUsecase,
    required SendHomeChallengeUsecase sendHomeChallengeUsecase,
    required SetOnlineChallengeReadyUsecase setOnlineChallengeReadyUsecase,
  }) : _getOnlineFriendsUsecase = getOnlineFriendsUsecase,
       _getOnlineChallengesUsecase = getOnlineChallengesUsecase,
       _changeOnlineChallengeStatusUsecase = changeOnlineChallengeStatusUsecase,
       _sendHomeChallengeUsecase = sendHomeChallengeUsecase,
       _setOnlineChallengeReadyUsecase = setOnlineChallengeReadyUsecase,
       super(OnlineState.initial()) {
    on<OnlineLoadRequested>(_onLoadRequested);
    on<OnlineSendChallengeRequested>(_onSendChallengeRequested);
    on<OnlineChallengeDecisionRequested>(_onChallengeDecisionRequested);
    on<OnlinePendingMatchLobbyDismissed>(_onPendingMatchLobbyDismissed);
    on<OnlineChallengeReadyRequested>(_onChallengeReadyRequested);
    on<OnlineChallengesRealtimeUpdated>(_onChallengesRealtimeUpdated);
    on<OnlineGameLaunchConsumed>(_onGameLaunchConsumed);
    on<ResetOnlineTab>(_onResetOnlineTab);
  }

  /// Prevents pushing the same match onto the route stack more than once.
  final Set<String> _autoNavigatedChallengeIds = {};

  static String _normChallengeKey(String id) => id.trim().toLowerCase();

  RealtimeChannel? _gameChallengesChannel;

  final GetOnlineFriendsUsecase _getOnlineFriendsUsecase;
  final GetOnlineChallengesUsecase _getOnlineChallengesUsecase;
  final ChangeOnlineChallengeStatusUsecase _changeOnlineChallengeStatusUsecase;
  final SendHomeChallengeUsecase _sendHomeChallengeUsecase;
  final SetOnlineChallengeReadyUsecase _setOnlineChallengeReadyUsecase;

  Future<void> _onLoadRequested(
    OnlineLoadRequested event,
    Emitter<OnlineState> emit,
  ) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    emit(
      state.copyWith(
        status: OnlineStatus.loading,
        clearError: true,
        clearSuccess: true,
        currentUserId: uid,
      ),
    );

    final friendsResult = await _getOnlineFriendsUsecase();
    await friendsResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: OnlineStatus.failure,
            errorMessage: failure.message,
            friends: const [],
            challenges: const [],
          ),
        );
      },
      (friends) async {
        final challengesResult = await _getOnlineChallengesUsecase();
        challengesResult.fold(
          (failure) {
            emit(
              state.copyWith(
                status: OnlineStatus.failure,
                errorMessage: failure.message,
                friends: friends,
                challenges: const [],
              ),
            );
          },
          (challenges) {
            emit(
              state.copyWith(
                status: OnlineStatus.loaded,
                friends: List<UserModel>.unmodifiable(friends),
                challenges: List<ChallengeRequestModel>.unmodifiable(
                  challenges,
                ),
                currentUserId: uid,
              ),
            );
            _ensureGameChallengesRealtime();
            _tryEmitGameLaunchForReadyMatches(emit, challenges, uid, friends);
          },
        );
      },
    );
  }

  void _ensureGameChallengesRealtime() {
    if (_gameChallengesChannel != null) return;
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    _gameChallengesChannel = client
        .channel('game_challenges_row_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: HomeTable.gameChallenges,
          callback: (_) => add(OnlineChallengesRealtimeUpdated()),
        )
        .subscribe();
  }

  Future<void> _onChallengesRealtimeUpdated(
    OnlineChallengesRealtimeUpdated event,
    Emitter<OnlineState> emit,
  ) async {
    if (state.status == OnlineStatus.loading) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final result = await _getOnlineChallengesUsecase();
    result.fold((_) {}, (challenges) {
      final friends = state.friends;
      final leftGameInfo = _leftGameInfoFromDiff(
        previous: state.challenges,
        next: challenges,
        uid: uid,
        friends: friends,
      );
      emit(
        state.copyWith(
          challenges: List<ChallengeRequestModel>.unmodifiable(challenges),
          currentUserId: uid,
          successType: leftGameInfo == null ? null : OnlineSuccessType.leftMatch,
          successName: leftGameInfo?.opponentName,
          successGameId: leftGameInfo?.gameId,
          clearError: true,
          clearSuccess: leftGameInfo == null,
        ),
      );
      _tryEmitGameLaunchForReadyMatches(emit, challenges, uid, friends);
    });
  }

  ({String opponentName, int gameId})? _leftGameInfoFromDiff({
    required List<ChallengeRequestModel> previous,
    required List<ChallengeRequestModel> next,
    required String uid,
    required List<UserModel> friends,
  }) {
    final prevAcceptedById = <String, ChallengeRequestModel>{};
    for (final c in previous) {
      final id = c.id?.trim();
      if (id == null || id.isEmpty) continue;
      if (c.status.toLowerCase() != 'accepted') continue;
      prevAcceptedById[id] = c;
    }

    for (final c in next) {
      final id = c.id?.trim();
      if (id == null || id.isEmpty) continue;
      final old = prevAcceptedById[id];
      if (old == null) continue;
      if (c.status.toLowerCase() != 'cancelled') continue;
      if (c.fromId != uid && c.toId != uid) continue;

      final opponentId = c.fromId == uid ? c.toId : c.fromId;
      final opponentName = _friendDisplayName(friends, opponentId);
      return (opponentName: opponentName, gameId: c.gameId);
    }
    return null;
  }

  void _tryEmitGameLaunchForReadyMatches(
    Emitter<OnlineState> emit,
    List<ChallengeRequestModel> challenges,
    String? uid,
    List<UserModel> friends,
  ) {
    if (uid == null) return;
    if (state.pendingGameLaunch != null) return;

    for (final c in challenges) {
      final challengeId = c.id?.trim();
      if (challengeId == null || challengeId.isEmpty) continue;
      if (c.status.toLowerCase() != 'accepted') continue;
      if (!c.fromReady || !c.toReady) continue;
      if (c.fromId != uid && c.toId != uid) continue;
      if (_autoNavigatedChallengeIds.contains(_normChallengeKey(challengeId))) {
        continue;
      }

      final opponentId = c.fromId == uid ? c.toId : c.fromId;
      _autoNavigatedChallengeIds.add(_normChallengeKey(challengeId));
      emit(
        state.copyWith(
          pendingGameLaunch: OnlineGameLaunch(
            challengeId: challengeId,
            gameId: c.gameId,
            opponentUserId: opponentId,
            opponentDisplayName: _friendDisplayName(friends, opponentId),
            challengeFromUserId: c.fromId,
            challengeToUserId: c.toId,
          ),
        ),
      );
      return;
    }
  }

  String _friendDisplayName(List<UserModel> friends, String userId) {
    for (final f in friends) {
      if (f.id == userId) {
        final n = f.username.trim();
        return n.isEmpty ? 'Player' : n;
      }
    }
    if (userId.length <= 12) return userId;
    return '${userId.substring(0, 10)}…';
  }

  void _onGameLaunchConsumed(
    OnlineGameLaunchConsumed event,
    Emitter<OnlineState> emit,
  ) {
    final challenges = state.challenges;
    final uid = state.currentUserId;
    final friends = state.friends;
    emit(state.copyWith(clearPendingGameLaunch: true));
    _tryEmitGameLaunchForReadyMatches(emit, challenges, uid, friends);
  }

  Future<void> _onSendChallengeRequested(
    OnlineSendChallengeRequested event,
    Emitter<OnlineState> emit,
  ) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));

    final result = await _sendHomeChallengeUsecase(event.friend, event.gameId);

    await result.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message, clearSuccess: true));
      },
      (_) async {
        final raw = event.friend.username.trim();
        final short = raw.isEmpty ? '' : raw.split(' ').first;
        emit(
          state.copyWith(
            successType: OnlineSuccessType.challengeSent,
            successName: short,
            successGameId: event.gameId,
            clearError: true,
          ),
        );
        add(OnlineLoadRequested());
      },
    );
  }

  Future<void> _onChallengeDecisionRequested(
    OnlineChallengeDecisionRequested event,
    Emitter<OnlineState> emit,
  ) async {
    final id = event.challengeId.trim();
    if (id.isEmpty) return;

    emit(state.copyWith(clearError: true, clearSuccess: true));

    final result = await _changeOnlineChallengeStatusUsecase(
      challengeId: id,
      status: event.accept ? 'accept' : 'reject',
    );

    await result.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message, clearSuccess: true));
      },
      (_) async {
        if (!event.accept) {
          emit(
            state.copyWith(
              successType: OnlineSuccessType.challengeDeclined,
              clearError: true,
            ),
          );
          add(OnlineLoadRequested());
          return;
        }

        final showLobby =
            event.opponentDisplayName != null && event.gameId != null;

        if (showLobby) {
          final challengesRes = await _getOnlineChallengesUsecase();
          final challenges = challengesRes.fold(
            (_) => <ChallengeRequestModel>[],
            (list) => list,
          );
          final uid = Supabase.instance.client.auth.currentUser?.id;
          var myAcceptedCount = 0;
          if (uid != null) {
            for (final c in challenges) {
              if (c.status.toLowerCase() != 'accepted') continue;
              if (c.fromId == uid || c.toId == uid) myAcceptedCount++;
            }
          }

          if (myAcceptedCount <= 1) {
            emit(
              state.copyWith(
                pendingMatchLobby: AcceptedMatchPreview(
                  challengeId: id,
                  opponentDisplayName: event.opponentDisplayName!,
                  opponentAvatarUrl: event.opponentAvatarUrl,
                  gameId: event.gameId!,
                ),
                clearError: true,
                clearSuccess: true,
              ),
            );
          } else {
            emit(
              state.copyWith(
                successType: OnlineSuccessType.challengeAcceptedHasOtherMatches,
                clearError: true,
              ),
            );
          }
        } else {
          emit(
            state.copyWith(
              successType: OnlineSuccessType.challengeAccepted,
              clearError: true,
            ),
          );
        }
        add(OnlineLoadRequested());
      },
    );
  }

  void _onPendingMatchLobbyDismissed(
    OnlinePendingMatchLobbyDismissed event,
    Emitter<OnlineState> emit,
  ) {
    emit(state.copyWith(clearPendingMatchLobby: true));
  }

  Future<void> _onChallengeReadyRequested(
    OnlineChallengeReadyRequested event,
    Emitter<OnlineState> emit,
  ) async {
    final id = event.challengeId.trim();
    if (id.isEmpty) return;

    emit(state.copyWith(clearError: true, clearSuccess: true));

    final result = await _setOnlineChallengeReadyUsecase(id);
    await result.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message, clearSuccess: true));
      },
      (bothReady) async {
        if (bothReady) {
          emit(state.copyWith(clearError: true, clearSuccess: true));
        } else {
          emit(
            state.copyWith(
              successType: OnlineSuccessType.readyWaitingOpponent,
              clearError: true,
            ),
          );
        }
        add(OnlineLoadRequested());
      },
    );
  }

  @override
  Future<void> close() async {
    final ch = _gameChallengesChannel;
    _gameChallengesChannel = null;
    if (ch != null) {
      await Supabase.instance.client.removeChannel(ch);
    }
    return super.close();
  }

  FutureOr<void> _onResetOnlineTab(
    ResetOnlineTab event,
    Emitter<OnlineState> emit,
  ) {
    emit(OnlineState.initial());
  }
}
