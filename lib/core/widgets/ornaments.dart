import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Sakkiz uchli yulduz shaklidagi nishon (oyat/sura raqami uchun),
/// Qur'on mushaflaridagi oyat belgisini eslatadi.
class StarBadge extends StatelessWidget {
  final Widget child;
  final double size;
  final Color? color;
  final bool filled;

  const StarBadge({
    super.key,
    required this.child,
    this.size = 44,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppPalette.of(context).accentGold;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarPainter(c, filled),
        child: Center(child: child),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  final bool filled;
  const _StarPainter(this.color, this.filled);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final half = size.width * 0.34;
    final square =
        Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2);
    final fill = Paint()
      ..color = color.withValues(alpha: filled ? 0.9 : 0.12)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = color.withValues(alpha: filled ? 1 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (final angle in [0.0, 0.7853981634]) {
      canvas.save();
      canvas.rotate(angle);
      canvas.drawRect(square, fill);
      canvas.drawRect(square, line);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.filled != filled;
}

/// Yuklanish paytida bloklar o'rnida nafas olgandek miltillovchi joy.
class Pulse extends StatefulWidget {
  final Widget child;
  const Pulse({super.key, required this.child});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// Karta shaklidagi yuklanish bloki.
class SkeletonCard extends StatelessWidget {
  final double height;
  final double radius;
  const SkeletonCard({super.key, this.height = 76, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: palette.fieldFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.cardBorder),
      ),
    );
  }
}

/// Matn uchun gradient niqob. Oddiy [ShaderMask] niqob chegarasidan chiqib
/// turgan harf qismlarini (arabcha harflarning pastki/ustki cho'ziqlari)
/// gradientsiz, oq rangda chizib qo'yadi. Bu vidjet matn atrofiga zaxira
/// joy beradi, shunda butun harf gradient bilan bo'yaladi.
class PaddedShaderMask extends StatelessWidget {
  final ShaderCallback shaderCallback;
  final Widget child;
  final BlendMode blendMode;
  final EdgeInsets padding;

  const PaddedShaderMask({
    super.key,
    required this.shaderCallback,
    required this.child,
    this.blendMode = BlendMode.srcIn,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: blendMode,
      shaderCallback: shaderCallback,
      child: Padding(padding: padding, child: child),
    );
  }
}
