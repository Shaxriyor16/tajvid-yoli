import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/db/app_database.dart';
import 'core/services/notification_service.dart';
import 'core/services/audio_player_service.dart';
import 'features/quran/quran_data.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/auth_bloc.dart'; // <-- qo'shildi
import 'core/bloc/app_config_cubit.dart';
import 'core/services/ai_service.dart';
import 'core/utils/onboarding_store.dart';
import 'firebase_options.dart';
import 'core/services/logger_service.dart';

const _appCheckAndroidDebugToken =
    String.fromEnvironment('APP_CHECK_ANDROID_DEBUG_TOKEN');
const _appCheckIosDebugToken =
    String.fromEnvironment('APP_CHECK_IOS_DEBUG_TOKEN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await OnboardingStore.init();

  // Crashlytics: framework xatolarini ushlash
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
      return true;
    };
    try {
      await FirebaseAppCheck.instance
          .activate(
            providerAndroid: kReleaseMode
                ? const AndroidPlayIntegrityProvider()
                : AndroidDebugProvider(
                    debugToken: _appCheckAndroidDebugToken.isEmpty
                        ? null
                        : _appCheckAndroidDebugToken,
                  ),
            providerApple: kReleaseMode
                ? const AppleDeviceCheckProvider()
                : AppleDebugProvider(
                    debugToken: _appCheckIosDebugToken.isEmpty
                        ? null
                        : _appCheckIosDebugToken,
                  ),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e, s) {
      AppLogger.e('App Check ishga tushmadi', error: e, stackTrace: s);
    }
  }

  // Analytics
  unawaited(FirebaseAnalytics.instance.logAppOpen().catchError((Object _) {}));

  final database = AppDatabase();
  final authService = AuthService();

  final notificationService = NotificationService();
  unawaited(notificationService.init().catchError((Object e, StackTrace s) {
    AppLogger.e('Bildirishnomalar ishga tushmadi', error: e, stackTrace: s);
  }));

  final quranRepository = QuranRepository(
    apiService: QuranApiService(),
    database: database,
  );

  final aiService = AiService();
  final audioPlayerService = AudioPlayerService();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider<NotificationService>.value(
            value: notificationService),
        RepositoryProvider<QuranRepository>.value(value: quranRepository),
        RepositoryProvider<AuthService>.value(value: authService),
        RepositoryProvider<AiService>.value(value: aiService),
        RepositoryProvider<AudioPlayerService>.value(value: audioPlayerService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AppConfigCubit()),
          BlocProvider(
            create: (context) => AuthBloc(
              context.read<AuthService>(),
              context.read<AppDatabase>(),
            )..add(AuthCheckRequested()),
          ),
        ],
        child: const TajvidYoliApp(),
      ),
    ),
  );
}
