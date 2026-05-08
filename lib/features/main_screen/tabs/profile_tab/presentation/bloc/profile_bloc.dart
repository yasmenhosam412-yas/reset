import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/push/push_bootstrap.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/load_profile_dashboard_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/respond_profile_friend_request_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/update_accepts_match_invites_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/update_push_notifications_enabled_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/update_profile_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_event.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required LoadProfileDashboardUsecase loadProfileDashboardUsecase,
    required RespondProfileFriendRequestUsecase
        respondProfileFriendRequestUsecase,
    required UpdateProfileUsecase updateProfileUsecase,
    required UpdateAcceptsMatchInvitesUsecase updateAcceptsMatchInvitesUsecase,
    required UpdatePushNotificationsEnabledUsecase
        updatePushNotificationsEnabledUsecase,
  })  : _loadProfileDashboardUsecase = loadProfileDashboardUsecase,
        _respondProfileFriendRequestUsecase =
            respondProfileFriendRequestUsecase,
        _updateProfileUsecase = updateProfileUsecase,
        _updateAcceptsMatchInvitesUsecase = updateAcceptsMatchInvitesUsecase,
        _updatePushNotificationsEnabledUsecase =
            updatePushNotificationsEnabledUsecase,
        super(ProfileState.initial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileFriendRequestResponded>(_onFriendRequestResponded);
    on<ProfileEdited>(_onProfileEdited);
    on<ProfileMatchInvitesChanged>(_onMatchInvitesChanged);
    on<ProfilePushNotificationsChanged>(_onPushNotificationsChanged);
  }

  final LoadProfileDashboardUsecase _loadProfileDashboardUsecase;
  final RespondProfileFriendRequestUsecase _respondProfileFriendRequestUsecase;
  final UpdateProfileUsecase _updateProfileUsecase;
  final UpdateAcceptsMatchInvitesUsecase _updateAcceptsMatchInvitesUsecase;
  final UpdatePushNotificationsEnabledUsecase
      _updatePushNotificationsEnabledUsecase;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ProfileStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _loadProfileDashboardUsecase();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: failure.message,
          dashboard: null,
        ),
      ),
      (dashboard) => emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          dashboard: dashboard,
        ),
      ),
    );
  }

  Future<void> _onFriendRequestResponded(
    ProfileFriendRequestResponded event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        busyFriendRequestId: event.requestId,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _respondProfileFriendRequestUsecase(
      requestId: event.requestId,
      accept: event.accept,
    );

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message,
            clearSuccess: true,
            clearBusyFriendRequest: true,
          ),
        );
      },
      (_) async {
        emit(
          state.copyWith(
            successType: event.accept
                ? ProfileSuccessType.friendRequestAccepted
                : ProfileSuccessType.friendRequestDeclined,
            clearError: true,
            clearBusyFriendRequest: true,
          ),
        );
        add(ProfileLoadRequested());
      },
    );
  }

  Future<void> _onProfileEdited(
    ProfileEdited event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        profileSaveBusy: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _updateProfileUsecase(
      username: event.username,
      avatarBytes: event.avatarBytes,
      avatarContentType: event.avatarContentType,
    );

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            profileSaveBusy: false,
            errorMessage: failure.message,
            clearSuccess: true,
          ),
        );
      },
      (_) async {
        emit(
          state.copyWith(
            profileSaveBusy: false,
            successType: ProfileSuccessType.profileUpdated,
            clearError: true,
          ),
        );
        add(ProfileLoadRequested());
      },
    );
  }

  Future<void> _onMatchInvitesChanged(
    ProfileMatchInvitesChanged event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));

    final dash = state.dashboard;
    if (dash != null) {
      emit(
        state.copyWith(
          dashboard: ProfileDashboardModel(
            user: dash.user,
            email: dash.email,
            stats: dash.stats,
            incomingFriendRequests: dash.incomingFriendRequests,
            acceptsMatchInvites: event.accepts,
            pushNotificationsEnabled: dash.pushNotificationsEnabled,
          ),
        ),
      );
    }

    final result = await _updateAcceptsMatchInvitesUsecase(event.accepts);
    await result.fold(
      (failure) async {
        if (dash != null) {
          emit(
            state.copyWith(
              dashboard: dash,
              errorMessage: failure.message,
              clearSuccess: true,
            ),
          );
        } else {
          emit(
            state.copyWith(
              errorMessage: failure.message,
              clearSuccess: true,
            ),
          );
        }
      },
      (_) async {
        add(ProfileLoadRequested());
      },
    );
  }

  Future<void> _onPushNotificationsChanged(
    ProfilePushNotificationsChanged event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));

    final dash = state.dashboard;
    if (dash != null) {
      emit(
        state.copyWith(
          dashboard: ProfileDashboardModel(
            user: dash.user,
            email: dash.email,
            stats: dash.stats,
            incomingFriendRequests: dash.incomingFriendRequests,
            acceptsMatchInvites: dash.acceptsMatchInvites,
            pushNotificationsEnabled: event.enabled,
          ),
        ),
      );
    }

    final result = await _updatePushNotificationsEnabledUsecase(event.enabled);
    await result.fold(
      (failure) async {
        if (dash != null) {
          emit(
            state.copyWith(
              dashboard: dash,
              errorMessage: failure.message,
              clearSuccess: true,
            ),
          );
        } else {
          emit(
            state.copyWith(
              errorMessage: failure.message,
              clearSuccess: true,
            ),
          );
        }
      },
      (_) async {
        unawaited(
          PushBootstrap.syncPushPreferenceWithProfile(
            Supabase.instance.client,
          ),
        );
        add(ProfileLoadRequested());
      },
    );
  }
}
