import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/core/widgets/permission_screen.dart';
import 'package:tajvid_yoli/features/auth/auth_bloc.dart';
import 'package:tajvid_yoli/features/auth/complete_profile_screen.dart';
import 'package:tajvid_yoli/features/auth/email_verification_screen.dart';
import 'package:tajvid_yoli/features/auth/loading_screen.dart';
import 'package:tajvid_yoli/features/quran/book_reader_screen.dart';
import 'package:tajvid_yoli/features/quran/quran_data.dart' as data;
import 'package:tajvid_yoli/features/recitation_finder/recitation_finder_screen.dart';
import 'quran_reliability_test.dart' show MemoryDatabase, FakeApi;
import 'widget_test.dart' show TestAuthBloc;

typedef _Step = Future<void> Function(WidgetTester tester);

void main() {
  final screens = <String, ({Widget Function() build, _Step? act})>{
    'loading': (build: () => const LoadingScreen(), act: null),
    'permissions': (build: () => const PermissionScreen(), act: null),
    'email-verification': (
      build: () => const EmailVerificationScreen(),
      act: null
    ),
    'complete-profile': (build: () => const CompleteProfileScreen(), act: null),
    'recitation-finder': (
      build: () => const RecitationFinderScreen(),
      act: null
    ),
    'book-reader': (
      build: () => const BookReaderScreen(surahNumber: 1),
      act: (tester) async {
        await tester.tap(find.text('Kitobni ochish'));
        await tester.pumpAndSettle();
      },
    ),
  };

  for (final entry in screens.entries) {
    for (final dark in [false, true]) {
      testWidgets('${entry.key} dark=$dark', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = true);
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
            const MethodChannel('com.llfbandit.record/messages'),
            (call) async => null);
        messenger.setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            (call) async {
          if (call.method == 'checkPermissionStatus') {
            return call.arguments == 7 ? 1 : 0;
          }
          return null;
        });
        await tester.runAsync(() async {
          for (final font in {
            'Inter': 'assets/fonts/Inter.ttf',
            'Chubbo': 'assets/fonts/Chubbo-Bold.ttf',
            'Supreme': 'assets/fonts/Supreme-Regular.ttf',
            'Amiri': 'assets/fonts/Amiri-Regular.ttf',
            'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
            'packages/cupertino_icons/CupertinoIcons':
                'packages/cupertino_icons/assets/CupertinoIcons.ttf',
          }.entries) {
            final loader = FontLoader(font.key)
              ..addFont(rootBundle.load(font.value));
            await loader.load();
          }
        });
        final auth = TestAuthBloc()
          ..setStateForTest(entry.key == 'email-verification'
              ? const AuthNeedsEmailVerification('student@example.com',
                  emailSent: true)
              : AuthUnauthenticated());
        final boundary = GlobalKey();
        final router = GoRouter(routes: [
          GoRoute(
            path: '/',
            builder: (ctx, _) => Container(
              decoration: AppColors.adaptiveBackground(ctx),
              child: entry.value.build(),
            ),
          ),
          GoRoute(path: '/onboarding', builder: (_, __) => const SizedBox()),
        ]);
        await tester.pumpWidget(RepositoryProvider<data.QuranRepository>.value(
          value: data.QuranRepository(
              apiService: FakeApi(), database: MemoryDatabase()),
          child: BlocProvider<AuthBloc>.value(
            value: auth,
            child: MaterialApp.router(
              routerConfig: router,
              locale: const Locale('uz'),
              supportedLocales: const [Locale('uz')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) =>
                  RepaintBoundary(key: boundary, child: child),
            ),
          ),
        ));
        if (entry.key == 'loading') {
          await tester.pump(const Duration(milliseconds: 900));
        } else {
          await tester.pumpAndSettle();
        }
        await entry.value.act?.call(tester);
        expect(tester.takeException(), isNull);
        await tester.runAsync(() => precacheImage(
            const AssetImage('assets/logo.png'), boundary.currentContext!));
        await tester.pump();
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('.artifacts/ui')..createSync(recursive: true);
          await File('${dir.path}/${entry.key}-${dark ? 'dark' : 'light'}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        if (entry.key == 'loading') {
          await tester.pump(const Duration(seconds: 2));
        }
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(auth.close);
        debugDisableShadows = true;
      });
    }
  }
}
