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
}
