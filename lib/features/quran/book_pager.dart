import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A single-page book reader with a two-sided, perspective page turn.
class BookPager extends StatefulWidget {
  final List<Widget> pages;
  final String title;

  const BookPager({super.key, required this.pages, required this.title});

  @override
  State<BookPager> createState() => _BookPagerState();
}

class _BookPagerState extends State<BookPager>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  int _page = 0;
  int _direction = 1;
  bool _settling = false;
  double _width = 1;
  final Map<int, Widget> _faceCache = {};

  int get _last => widget.pages.length;

  @override
  void didUpdateWidget(covariant BookPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    _faceCache.clear();
    if (_page > _last) {
      _page = _last;
      _turn.value = 0;
    }
  }

  bool _canTurn(int direction) =>
      _page + direction >= 0 && _page + direction <= _last;

  Future<void> _finish(bool commit) async {
    if (_settling) return;
    _settling = true;
    await _turn.animateTo(
      commit ? 1 : 0,
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    setState(() {
      if (commit) _page += _direction;
      _turn.value = 0;
      _settling = false;
    });
  }

  void _step(int direction) {
    if (_settling || _turn.value != 0 || !_canTurn(direction)) return;
    setState(() => _direction = direction);
    _finish(true);
  }

  Widget _cover() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            colors: [Color(0xFF123E38), Color(0xFF072B28)],
          ),
          border: Border.all(color: const Color(0xFFB08D3E), width: 3),
        ),
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_stories_rounded,
                size: 62, color: Color(0xFFE3CA85)),
            const SizedBox(height: 24),
            Text(widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 30,
                    color: Color(0xFFE3CA85))),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: () => _step(1), child: const Text('Kitobni ochish')),
          ]),
        ),
      );

  Widget _paperBack() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBF6E8), Color(0xFFECE0BF)],
          ),
        ),
      );

  Widget _pageFace(int index) => _faceCache.putIfAbsent(index, () {
        if (index == 0) return _cover();
        if (index > 0 && index <= _last) return widget.pages[index - 1];
        return _paperBack();
      });

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        _width = constraints.maxWidth;
        return GestureDetector(
          key: const ValueKey('book-pages'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            if (_settling || _width <= 0) return;
            final delta = details.primaryDelta ?? 0;
            if (_turn.value == 0) {
              final direction = delta > 0 ? 1 : -1;
              if (!_canTurn(direction)) return;
              setState(() => _direction = direction);
            }
            _turn.value = (_turn.value + delta * _direction / _width)
                .clamp(0.0, 1.0)
                .toDouble();
          },
          onHorizontalDragEnd: (details) {
            if (_turn.value == 0 || _settling) return;
            final velocity = (details.primaryVelocity ?? 0) * _direction;
            _finish(velocity > 450 || (velocity >= -450 && _turn.value > .3));
          },
          onHorizontalDragCancel: () {
            if (!_settling && _turn.value > 0) _finish(false);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE3D7B6),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38, blurRadius: 16, offset: Offset(0, 6))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AnimatedBuilder(
                animation: _turn,
                builder: (context, _) {
                  final progress = _turn.value;
                  final target = (_page + _direction).clamp(0, _last).toInt();
                  final nextUnder = target + _direction;
                  final front = RepaintBoundary(child: _pageFace(_page));
                  final back = RepaintBoundary(child: _pageFace(target));
                  final under = RepaintBoundary(child: _pageFace(nextUnder));
                  final angle = _direction * progress * math.pi;
                  final turningFace = progress <= .5
                      ? front
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateY(_direction * math.pi),
                          child: back,
                        );

                  return Stack(fit: StackFit.expand, children: [
                    IgnorePointer(child: under),
                    Transform(
                      key: const ValueKey('turning-leaf'),
                      alignment: _direction > 0
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, .0014)
                        ..rotateY(angle),
                      child: IgnorePointer(
                        ignoring: progress > 0 || _settling,
                        child: turningFace,
                      ),
                    ),
                    if (progress > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PageTurnShadowPainter(
                              progress: progress,
                              direction: _direction,
                            ),
                          ),
                        ),
                      ),
                    if (progress > 0)
                      Align(
                        alignment: _direction > 0
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: IgnorePointer(
                          child: Container(
                            width: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: _direction > 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                end: _direction > 0
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(
                                      alpha: .2 * math.sin(math.pi * progress)),
                                  Colors.white.withValues(
                                      alpha:
                                          .22 * math.sin(math.pi * progress)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]);
                },
              ),
            ),
          ),
        );
      })),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
            tooltip: 'Keyingi bet',
            onPressed: _page < _last && !_settling ? () => _step(1) : null,
            icon: const Icon(Icons.chevron_left_rounded)),
        Text(_page == 0 ? 'Muqova' : '$_page / $_last',
            key: const ValueKey('book-page-number')),
        IconButton(
            tooltip: 'Oldingi bet',
            onPressed: _page > 0 && !_settling ? () => _step(-1) : null,
            icon: const Icon(Icons.chevron_right_rounded)),
      ]),
    ]);
  }
}

class _PageTurnShadowPainter extends CustomPainter {
  final double progress;
  final int direction;

  const _PageTurnShadowPainter(
      {required this.progress, required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final strength = math.sin(math.pi * progress).clamp(0.0, 1.0).toDouble();
    final projectedWidth = size.width * math.cos(math.pi * progress).abs();
    final edgeX = direction > 0 ? size.width - projectedWidth : projectedWidth;
    final left = (edgeX - 24).clamp(0.0, size.width).toDouble();
    final right = (edgeX + 24).clamp(0.0, size.width).toDouble();
    if (right > left) {
      final shadowRect = Rect.fromLTRB(left, 0, right, size.height);
      final shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: .28 * strength),
          Colors.transparent,
        ],
      ).createShader(shadowRect);
      canvas.drawRect(shadowRect, Paint()..shader = shader);
    }

    final curl = 8 * strength;
    final side = direction > 0 ? 1.0 : -1.0;
    final edge = Path()
      ..moveTo(edgeX, 0)
      ..cubicTo(edgeX + side * curl, size.height * .3, edgeX - side * curl,
          size.height * .7, edgeX, size.height);
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .48 * strength),
    );
  }

  @override
  bool shouldRepaint(covariant _PageTurnShadowPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.direction != direction;
}
