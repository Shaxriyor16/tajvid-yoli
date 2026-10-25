import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tajvid_yoli/core/responsive/adaptive_shell.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';

class _Counter extends StatefulWidget {
  final String label;
  const _Counter(this.label);
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => taps++),
        child: Center(child: Text('${widget.label}:$taps')),
      );
}

GoRouter _router() => GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (c, s, shell) => AdaptiveShell(navigationShell: shell),
          branches: [
            for (final p in ['home', 'quran', 'ai-check', 'profile'])
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/$p',
                  pageBuilder: (c, s) => NoTransitionPage(child: _Counter(p)),
                ),
              ]),
          ],
        ),
      ],
    );

void main() {
  for (final locale in [const Locale('uz'), const Locale('ar')]) {
    testWidgets('tabs switch, keep state and pill follows (${locale.languageCode})',
        (tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: _router(),
        theme: AppTheme.dark,
        locale: locale,
        supportedLocales: const [Locale('uz'), Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('home:0'));
      await tester.pump();
      expect(find.text('home:1'), findsOneWidget);

      // 3-tab (AI tekshiruv): nav tugmasi bosiladi, sahifa almashadi
      final bar = find.byType(AnimatedAlign);
      expect(bar, findsOneWidget);
      final rtl = locale.languageCode == 'ar';
      final w = tester.view.physicalSize.width;
      // tab i markazi: (w-32)/4 * (i+0.5) + 16, RTL da teskari
      double cx(int i) {
        final x = 16 + (w - 32) / 4 * (i + 0.5);
        return rtl ? w - x : x;
      }

      await tester.tapAt(Offset(cx(2), 956 - 24 - 36));
      await tester.pumpAndSettle();
      expect(find.text('ai-check:0'), findsOneWidget);

      // pill tanlangan tab ustida turibdi
      final pill = tester.getCenter(find
          .descendant(of: bar, matching: find.byType(FractionallySizedBox))
          .first);
      expect((pill.dx - cx(2)).abs() < 3, isTrue,
          reason: 'pill dx=${pill.dx} expected ${cx(2)}');

      // orqaga: home holati saqlangan
      await tester.tapAt(Offset(cx(0), 956 - 24 - 36));
      await tester.pumpAndSettle();
      expect(find.text('home:1'), findsOneWidget);
    });
  }
}
