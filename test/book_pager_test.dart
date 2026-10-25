import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tajvid_yoli/features/quran/book_pager.dart';

void main() {
  Widget book() => const MaterialApp(
          home: Scaffold(
              body: BookPager(
        title: 'Fotiha',
        pages: [
          ColoredBox(
              color: Color(0xFFFBF6E8),
              child: Center(child: Text('Birinchi bet'))),
          ColoredBox(
              color: Color(0xFFFBF6E8),
              child: Center(child: Text('Ikkinchi bet'))),
        ],
      )));

  testWidgets('cover turns in perspective and navigation respects boundaries',
      (tester) async {
    await tester.pumpWidget(book());
    expect(find.text('Muqova'), findsOneWidget);
    await tester.tap(find.text('Kitobni ochish'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final transform =
        tester.widget<Transform>(find.byKey(const ValueKey('turning-leaf')));
    expect(transform.transform.entry(0, 0), lessThan(1));
    expect(transform.transform.entry(3, 2), isNot(0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Keyingi bet'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Keyingi bet'))
            .onPressed,
        isNull);
    await tester.tap(find.byTooltip('Oldingi bet'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short drag settles back, full rightward drag advances',
      (tester) async {
    await tester.pumpWidget(book());
    await tester.tap(find.text('Kitobni ochish'));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('book-pages'));
    final start = tester.getCenter(surface);
    final short = await tester.startGesture(start);
    await short.moveBy(const Offset(70, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await short.up();
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.drag(surface, const Offset(450, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.drag(surface, const Offset(-450, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
