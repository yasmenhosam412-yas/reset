import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/load_profile_dashboard_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/respond_profile_friend_request_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_event.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required LoadProfileDashboardUsecase loadProfileDashboardUsecase,
    required RespondProfileFriendRequestUsecase
        respondProfileFriendRequestUsecase,
  })  : _loadProfileDashboardUsecase = loadProfileDashboardUsecase,
        _respondProfileFriendRequestUsecase =
            respondProfileFriendRequestUsecase,
        super(ProfileState.initial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileFriendRequestResponded>(_onFriendRequestResponded);
  }

  final LoadProfileDashboardUsecase _loadProfileDashboardUsecase;
  final RespondProfileFriendRequestUsecase _respondProfileFriendRequestUsecase;

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
    emit(state.copyWith(clearError: true, clearSuccess: true));

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
          ),
        );
      },
      (_) async {
        emit(
          state.copyWith(
            successMessage: event.accept
                ? 'Friend request accepted'
                : 'Friend request declined',
            clearError: true,
          ),
        );
        add(ProfileLoadRequested());
      },
    );
  }
}
