import 'package:get_it/get_it.dart';
import 'package:new_project/core/navigation/main_shell_controller.dart';
import 'package:new_project/features/authentication/data/datasource/remote/auth_remote_datasource.dart';
import 'package:new_project/features/authentication/data/datasource/remote/auth_remote_datasource_impl.dart';
import 'package:new_project/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:new_project/features/authentication/domain/repositories/auth_repository.dart';
import 'package:new_project/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/delete_account_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/login_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/signup_usecase.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_datasource_impl.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/repositories/home_repository_impl.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_comment_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_like_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/delete_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/update_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_accepted_friend_ids_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_posts_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_my_user_notifications_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/send_home_challenge_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/remove_home_friend_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/search_people_discovery_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/send_home_friend_request_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/data/global_battles_repository.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/claim_team_daily_challenge_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/claim_team_academy_scrim_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/claim_team_squad_spar_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/get_team_cloud_progress_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/sync_team_squad_to_cloud_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/get_lineup_race_leaderboard_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/submit_lineup_race_entry_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/train_team_player_stat_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/data/online_datasourse_impl.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/repositories/online_repository_impl.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/change_online_challenge_status_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/get_online_challenges_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/get_online_friends_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/set_online_challenge_ready_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/load_profile_dashboard_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/respond_profile_friend_request_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/update_accepts_match_invites_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/update_push_notifications_enabled_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/update_profile_usecase.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<MainShellController>(MainShellController.new);

  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  //------------------AUTH------------------------------------
  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () =>
        AuthRepositoryImpl(authRemoteDatasource: getIt<AuthRemoteDatasource>()),
  );
  getIt.registerLazySingleton<LoginUsecase>(
    () => LoginUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SignupUsecase>(
    () => SignupUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<LogoutUsecase>(
    () => LogoutUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<DeleteAccountUsecase>(
    () => DeleteAccountUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<ForgotPasswordUsecase>(
    () => ForgotPasswordUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory(
    () => AuthBloc(
      loginUsecase: getIt(),
      signupUsecase: getIt(),
      logoutUsecase: getIt(),
      deleteAccountUsecase: getIt(),
      forgotPasswordUsecase: getIt(),
    ),
  );

  //------------------HOME------------------------------------

  getIt.registerLazySingleton<HomeDatasourceImpl>(
    () => HomeDatasourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<HomeRepositoryImpl>(
    () => HomeRepositoryImpl(homeDatasource: getIt<HomeDatasourceImpl>()),
  );

  getIt.registerLazySingleton<GetHomePostsUsecase>(
    () => GetHomePostsUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<GetMyUserNotificationsUsecase>(
    () => GetMyUserNotificationsUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<GetHomeAcceptedFriendIdsUsecase>(
    () => GetHomeAcceptedFriendIdsUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<AddHomePostUsecase>(
    () => AddHomePostUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<DeleteHomePostUsecase>(
    () => DeleteHomePostUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<UpdateHomePostUsecase>(
    () => UpdateHomePostUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<AddHomeCommentUsecase>(
    () => AddHomeCommentUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<AddHomePostLikeUsecase>(
    () => AddHomePostLikeUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<SendHomeFriendRequestUsecase>(
    () => SendHomeFriendRequestUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<RemoveHomeFriendUsecase>(
    () => RemoveHomeFriendUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<SearchPeopleDiscoveryUsecase>(
    () => SearchPeopleDiscoveryUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<SendHomeChallengeUsecase>(
    () => SendHomeChallengeUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<GetTeamCloudProgressUsecase>(
    () => GetTeamCloudProgressUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<SyncTeamSquadToCloudUsecase>(
    () => SyncTeamSquadToCloudUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<ClaimTeamDailyChallengeUsecase>(
    () => ClaimTeamDailyChallengeUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<ClaimTeamSquadSparUsecase>(
    () => ClaimTeamSquadSparUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<ClaimTeamAcademyScrimUsecase>(
    () => ClaimTeamAcademyScrimUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<TrainTeamPlayerStatUsecase>(
    () => TrainTeamPlayerStatUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<GetLineupRaceLeaderboardUsecase>(
    () => GetLineupRaceLeaderboardUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<SubmitLineupRaceEntryUsecase>(
    () => SubmitLineupRaceEntryUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<GlobalBattlesRepository>(
    () => GlobalBattlesRepository(client: getIt<SupabaseClient>()),
  );

  getIt.registerFactory(
    () => HomeBloc(
      getHomePostsUsecase: getIt(),
      getHomeAcceptedFriendIdsUsecase: getIt(),
      addHomePostUsecase: getIt(),
      deleteHomePostUsecase: getIt(),
      updateHomePostUsecase: getIt(),
      addHomeCommentUsecase: getIt(),
      addHomePostLikeUsecase: getIt(),
      sendHomeFriendRequestUsecase: getIt(),
      sendHomeChallengeUsecase: getIt(),
    ),
  );

  //------------------ONLINE TAB------------------------------------

  getIt.registerLazySingleton<OnlineDatasourseImpl>(
    () => OnlineDatasourseImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<OnlineRepository>(
    () => OnlineRepositoryImpl(onlineDatasourse: getIt<OnlineDatasourseImpl>()),
  );

  getIt.registerLazySingleton<GetOnlineFriendsUsecase>(
    () => GetOnlineFriendsUsecase(onlineRepository: getIt<OnlineRepository>()),
  );

  getIt.registerLazySingleton<GetOnlineChallengesUsecase>(
    () =>
        GetOnlineChallengesUsecase(onlineRepository: getIt<OnlineRepository>()),
  );

  getIt.registerLazySingleton<ChangeOnlineChallengeStatusUsecase>(
    () => ChangeOnlineChallengeStatusUsecase(
      onlineRepository: getIt<OnlineRepository>(),
    ),
  );

  getIt.registerLazySingleton<SetOnlineChallengeReadyUsecase>(
    () => SetOnlineChallengeReadyUsecase(
      onlineRepository: getIt<OnlineRepository>(),
    ),
  );

  getIt.registerFactory(
    () => OnlineBloc(
      getOnlineFriendsUsecase: getIt(),
      getOnlineChallengesUsecase: getIt(),
      changeOnlineChallengeStatusUsecase: getIt(),
      sendHomeChallengeUsecase: getIt(),
      setOnlineChallengeReadyUsecase: getIt(),
    ),
  );

  getIt.registerLazySingleton<LoadProfileDashboardUsecase>(
    () => LoadProfileDashboardUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<RespondProfileFriendRequestUsecase>(
    () => RespondProfileFriendRequestUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<UpdateProfileUsecase>(
    () => UpdateProfileUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<UpdateAcceptsMatchInvitesUsecase>(
    () => UpdateAcceptsMatchInvitesUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<UpdatePushNotificationsEnabledUsecase>(
    () => UpdatePushNotificationsEnabledUsecase(
      homeRepository: getIt<HomeRepositoryImpl>(),
    ),
  );

  getIt.registerFactory(
    () => ProfileBloc(
      loadProfileDashboardUsecase: getIt(),
      respondProfileFriendRequestUsecase: getIt(),
      updateProfileUsecase: getIt(),
      updateAcceptsMatchInvitesUsecase: getIt(),
      updatePushNotificationsEnabledUsecase: getIt(),
    ),
  );
}
