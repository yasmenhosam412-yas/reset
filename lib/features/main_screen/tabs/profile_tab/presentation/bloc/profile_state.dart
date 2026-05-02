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
  });

  factory ProfileState.initial() {
    return const ProfileState(status: ProfileStatus.initial);
  }

  final ProfileStatus status;
  final ProfileDashboardModel? dashboard;
  final String? errorMessage;
  final String? successMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileDashboardModel? dashboard,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}
