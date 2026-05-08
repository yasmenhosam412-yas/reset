import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  failure,
}

enum ProfileSuccessType {
  friendRequestAccepted,
  friendRequestDeclined,
  profileUpdated,
}

class ProfileState {
  const ProfileState({
    required this.status,
    this.dashboard,
    this.errorMessage,
    this.successMessage,
    this.successType,
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
  final ProfileSuccessType? successType;

  /// Friend-request row being accepted or declined (disables buttons).
  final String? busyFriendRequestId;

  /// Saving display name / avatar from the edit sheet.
  final bool profileSaveBusy;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileDashboardModel? dashboard,
    String? errorMessage,
    String? successMessage,
    ProfileSuccessType? successType,
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
      successType: clearSuccess ? null : (successType ?? this.successType),
      busyFriendRequestId: clearBusyFriendRequest
          ? null
          : (busyFriendRequestId ?? this.busyFriendRequestId),
      profileSaveBusy: profileSaveBusy ?? this.profileSaveBusy,
    );
  }
}
