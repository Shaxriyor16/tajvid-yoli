import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/core/router/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/bloc/app_config_cubit.dart';
import 'core/l10n/app_localizations.dart';
import 'features/auth/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/router/router_refresh_stream.dart';
import 'dart:async';
import 'core/db/app_database.dart';
import 'core/services/notification_service.dart';
import 'core/services/update_service.dart';

class TajvidYoliApp extends StatefulWidget {
  const TajvidYoliApp({super.key});

  @override
  State<TajvidYoliApp> createState() => _TajvidYoliAppState();
}

class _TajvidYoliAppState extends State<TajvidYoliApp>
    with WidgetsBindingObserver {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final GoRouter _router;
  late final GoRouterRefreshStream _refresh;

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    _refresh = GoRouterRefreshStream(authBloc.stream);
    _router = AppRouter.createRouter(authBloc, refresh: _refresh);
    WidgetsBinding.instance.addObserver(this);
    _authSub = authBloc.stream.listen((s) {
      if (s is AuthAuthenticated) {
        _scheduleSync();
        _scheduleUpdateCheck();
      }
    });
    _langSub = context
        .read<AppConfigCubit>()
        .stream
        .map((c) => c.locale.languageCode)
        .distinct()
        .listen((_) => _scheduleSync());
    _scheduleSync();
  }

  /// Kirgandan bir necha soniya keyin yangi versiya borligini tekshiradi (bir marta).
  void _scheduleUpdateCheck() {
    Future<void>.delayed(const Duration(seconds: 6), () {
      final ctx = AppRouter.rootNavigatorKey.currentContext;
      if (mounted && ctx != null) UpdateService.checkAndPrompt(ctx);
    });
  }

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<String>? _langSub;
  Timer? _syncTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleSync();
  }

  /// Bildirishnoma jadvalini yangi til/seriya bilan qayta tuzadi
  /// (bosh ekran faollikni yozib bo'lishi uchun biroz kutiladi).
  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 4), () async {
      if (!mounted) return;
      try {
        final auth = context.read<AuthBloc>().state;
        final lang = context.read<AppConfigCubit>().state.locale.languageCode;
        var streak = 0;
        var activeToday = false;
        if (auth is AuthAuthenticated) {
          final db = context.read<AppDatabase>();
          streak = await db.getStreak(auth.user.uid);
          final user = await db.getUser(auth.user.uid);
          final last = user?.lastActiveAt;
          final now = DateTime.now();
          activeToday = last != null &&
              last.year == now.year &&
              last.month == now.month &&
              last.day == now.day;
        }
        if (!mounted) return;
        await context.read<NotificationService>().updateContext(
            lang: lang, streak: streak, activeToday: activeToday);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _authSub?.cancel();
    _langSub?.cancel();
    _router.dispose();
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(listener: (context, state) {
      if (state is AuthError && state.previous != null) {
        _messenger.currentState?.showSnackBar(SnackBar(
            content: Text(
                AppLocalizations(context.read<AppConfigCubit>().state.locale)
                    .get(state.message))));
      }
    }, child: BlocBuilder<AppConfigCubit, AppConfigState>(
      builder: (context, config) {
        return MaterialApp.router(
          scaffoldMessengerKey: _messenger,
          title: "Tajvid yo'li",
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: config.themeMode,
          locale: config.locale,
          supportedLocales: const [
            Locale('uz'),
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final overlayStyle = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor:
                  isDark ? AppColors.darkBackground : AppColors.lightBackground,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            );
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlayStyle,
              child: CupertinoTheme(
                data: isDark ? _cupertinoDark : _cupertinoLight,
                child: Container(
                  decoration: AppColors.adaptiveBackground(context),
                  child: child,
                ),
              ),
            );
          },
        );
      },
    ));
  }

  static const _cupertinoLight = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.lightEmerald,
    barBackgroundColor: Color(0xE6FAF8F2),
    scaffoldBackgroundColor: AppColors.lightBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.lightEmerald,
      textStyle: TextStyle(
        fontSize: 17,
        color: AppColors.lightOnBackground,
        inherit: true,
      ),
    ),
  );

  static const _cupertinoDark = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    barBackgroundColor: Color(0xE60A1A17),
    scaffoldBackgroundColor: AppColors.darkBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.primary,
      textStyle: TextStyle(
        fontSize: 17,
        color: AppColors.darkOnBackground,
        inherit: true,
      ),
    ),
  );
}
