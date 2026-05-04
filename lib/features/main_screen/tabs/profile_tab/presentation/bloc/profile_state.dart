import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  failure,
}

class ProfileState {
  const ProfileState({
    required this.status,
    this.dashboard,
    this.errorMessage,
    this.successMessage,
    this.busyFriendRequestId,
    this.profileSaveBusy = false,
  });

  factory ProfileState.initial() {
    return const ProfileState(status: ProfileStatus.initial);
  }

  final ProfileStatus status;
  final ProfileDashboardModel? dashboard;
  final String? errorMessage;
  final String? successMessage;

  /// Friend-request row being accepted or declined (disables buttons).
  final String? busyFriendRequestId;

  /// Saving display name / avatar from the edit sheet.
  final bool profileSaveBusy;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileDashboardModel? dashboard,
    String? errorMessage,
    String? successMessage,
    String? busyFriendRequestId,
    bool? profileSaveBusy,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearBusyFriendRequest = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      busyFriendRequestId: clearBusyFriendRequest
          ? null
          : (busyFriendRequestId ?? this.busyFriendRequestId),
      profileSaveBusy: profileSaveBusy ?? this.profileSaveBusy,
    );
  }
}
