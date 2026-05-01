import 'package:get_it/get_it.dart';
import 'package:new_project/features/authentication/data/datasource/remote/auth_remote_datasource.dart';
import 'package:new_project/features/authentication/data/datasource/remote/auth_remote_datasource_impl.dart';
import 'package:new_project/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:new_project/features/authentication/domain/repositories/auth_repository.dart';
import 'package:new_project/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/login_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:new_project/features/authentication/domain/usecases/signup_usecase.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_datasource_impl.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/repositories/home_repository_impl.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_comment_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_like_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_posts_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

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

  getIt.registerLazySingleton<ForgotPasswordUsecase>(
    () => ForgotPasswordUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory(
    () => AuthBloc(
      loginUsecase: getIt(),
      signupUsecase: getIt(),
      logoutUsecase: getIt(),
      forgotPasswordUsecase: getIt(),
    ),
  );

  //------------------------------------------------------------------------

  getIt.registerLazySingleton<HomeDatasourceImpl>(
    () => HomeDatasourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<HomeRepositoryImpl>(
    () => HomeRepositoryImpl(homeDatasource: getIt<HomeDatasourceImpl>()),
  );

  getIt.registerLazySingleton<GetHomePostsUsecase>(
    () => GetHomePostsUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<AddHomePostUsecase>(
    () => AddHomePostUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<AddHomeCommentUsecase>(
    () => AddHomeCommentUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerLazySingleton<AddHomePostLikeUsecase>(
    () => AddHomePostLikeUsecase(homeRepository: getIt<HomeRepositoryImpl>()),
  );

  getIt.registerFactory(
    () => HomeBloc(
      getHomePostsUsecase: getIt(),
      addHomePostUsecase: getIt(),
      addHomeCommentUsecase: getIt(),
      addHomePostLikeUsecase: getIt(),
    ),
  );
}
