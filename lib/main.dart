import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/app_locale_controller.dart';
import 'package:new_project/l10n/app_localizations.dart';
import 'package:new_project/core/push/foreground_local_notifications.dart';
import 'package:new_project/core/push/push_bootstrap.dart';
import 'package:new_project/core/routing/app_router.dart';
import 'package:new_project/core/utils/theme_data.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/data/global_battle_daily_digest.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/data/global_battle_digest_notifications.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/data/global_battles_repository.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc.dart';
import 'package:new_project/core/auth/account_freeze_guard.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_bloc.dart';
import 'package:new_project/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Root [ScaffoldMessenger] for global messages (e.g. account suspension).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tucjzlcvrcxvovfaxsuk.supabase.co',
    anonKey: 'sb_publishable_IYRhCn_KBmi_PYVubWFClQ_Wm6sF6mK',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  try {
    await Supabase.instance.client.auth.onAuthStateChange.first;
  } catch (e, st) {
    debugPrint('Auth initial state wait: $e\n$st');
  }

  registerAccountFreezeGuard(
    Supabase.instance.client,
    scaffoldMessengerKey: rootScaffoldMessengerKey,
  );

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseMessaging.instance.requestPermission();
      await ForegroundPushNotifications.register();
      await PushBootstrap.register(Supabase.instance.client);
    } catch (e, st) {
      debugPrint('Firebase / push bootstrap: $e\n$st');
    }
  }

  configureDependencies();
  await AppLocaleController.instance.load();

  if (!kIsWeb) {
    unawaited(_bootstrapGlobalBattleDigest());
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<AuthBloc>()),
        BlocProvider(create: (context) => getIt<HomeBloc>()),
        BlocProvider(create: (context) => getIt<OnlineBloc>()),
        BlocProvider(create: (context) => getIt<ProfileBloc>()),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> _bootstrapGlobalBattleDigest() async {
  try {
    if (Supabase.instance.client.auth.currentUser == null) return;
    await GlobalBattleDailyDigest.loadYesterdayDigest(
      getIt<GlobalBattlesRepository>(),
    );
    await GlobalBattleDigestNotifications.ensureScheduled();
  } catch (e, st) {
    debugPrint('Global battle digest bootstrap: $e\n$st');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLocaleController.instance,
      builder: (context, _) {
        return MaterialApp.router(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          locale: AppLocaleController.instance.locale,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          theme: AppTheme.themeData,
          routeInformationParser: AppRouter.router.routeInformationParser,
          routeInformationProvider: AppRouter.router.routeInformationProvider,
          routerDelegate: AppRouter.router.routerDelegate,
        );
      },
    );
  }
}
