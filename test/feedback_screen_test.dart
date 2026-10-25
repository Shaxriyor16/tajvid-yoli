import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tajvid_yoli/core/bloc/app_config_cubit.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/features/auth/auth_bloc.dart';
import 'package:tajvid_yoli/features/auth/auth_model.dart';
import 'package:tajvid_yoli/features/feedback/feedback_screen.dart';
import 'package:tajvid_yoli/features/feedback/feedback_service.dart';
import 'widget_test.dart' show TestAuthBloc;

Future<TestAuthBloc> _pump(
    WidgetTester tester, FeedbackSender sender, Locale locale) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = TestAuthBloc()
    ..setStateForTest(AuthAuthenticated(UserModel(
      uid: 'u1',
      email: 'ali@gmail.com',
      firstName: 'Ali',
      lastName: 'Valiyev',
      provider: 'google',
      createdAt: DateTime(2026, 10, 24),
    )));
  final config = AppConfigCubit();
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: auth),
      BlocProvider<AppConfigCubit>.value(value: config),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('uz'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.dark,
      home: FeedbackScreen(sender: sender),
    ),
  ));
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  for (final locale in [const Locale('uz'), const Locale('ar')]) {
    testWidgets('feedback validates then sends (${locale.languageCode})',
        (tester) async {
      final sent = <FeedbackEntry>[];
      await _pump(tester, (e) async => sent.add(e), locale);

      // Baholamasdan yuborib bo'lmaydi
      await tester.tap(find.byIcon(CupertinoIcons.paperplane_fill));
      await tester.pump();
      expect(sent, isEmpty);

      // 4 yulduz + matn
      await tester.tap(find.byIcon(CupertinoIcons.star).at(3));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Juda yaxshi ilova');
      await tester.tap(find.byIcon(CupertinoIcons.paperplane_fill));
      await tester.pumpAndSettle();

      expect(sent, hasLength(1));
      expect(sent.single.rating, 4);
      expect(sent.single.uid, 'u1');
      expect(sent.single.name, 'Ali Valiyev');
      expect(sent.single.message, 'Juda yaxshi ilova');
      expect(sent.single.category, 'idea');
      expect(find.byIcon(CupertinoIcons.checkmark_alt), findsOneWidget);
    });
  }

  testWidgets('send failure keeps the form and shows an error',
      (tester) async {
    await _pump(tester, (e) async => throw Exception('offline'),
        const Locale('en'));
    await tester.tap(find.byIcon(CupertinoIcons.star).at(4));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Great');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not send'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  test('entry map matches the Firestore rules shape', () {
    const e = FeedbackEntry(
      uid: 'u1',
      name: 'A',
      email: 'a@b.c',
      rating: 5,
      category: 'bug',
      message: 'x',
      appVersion: '1.0.0+1',
      locale: 'zz',
    );
    final m = e.toMap();
    expect(
        m.keys.toSet(),
        {
          'uid', 'name', 'email', 'rating', 'category', 'message',
          'appVersion', 'platform', 'locale', 'status', 'createdAt'
        });
    expect(m['locale'], 'uz'); // noma'lum til qoidaga mos qiymatga tushadi
    expect(m['status'], 'new');
  });
}
