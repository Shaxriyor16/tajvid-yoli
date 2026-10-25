import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Ovoz yozish tugmasi: oltin shar, yozilayotganda pulsatsiya halqalari va
/// ixtiyoriy vaqt progressi. AI tekshiruv va sura topish ekranlari uchun umumiy.
class MicOrb extends StatefulWidget {
  final bool isRecording;
  final bool isBusy;
  final VoidCallback onTap;

  /// 0..1 — yozish vaqtining o'tgan qismi (berilmasa ko'rsatilmaydi).
  final double? progress;
  final double size;

  const MicOrb({
    super.key,
    required this.isRecording,
    required this.isBusy,
    required this.onTap,
    this.progress,
    this.size = 112,
  });

  @override
  State<MicOrb> createState() => _MicOrbState();
}

class _MicOrbState extends State<MicOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  bool get _active => widget.isRecording || widget.isBusy;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (_active) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant MicOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_active) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final color = widget.isBusy ? AppColors.primary : AppColors.gold2;
    final gradient = widget.isBusy
        ? AppColors.primaryGradient
        : (widget.isRecording
            ? AppColors.secondaryGradient
            : AppColors.goldGradient);
    return GestureDetector(
      onTap: widget.isBusy
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
      child: SizedBox(
        width: size + 80,
        height: size + 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_active)
              for (final phase in const [0.0, 0.5])
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final t = (_pulse.value + phase) % 1.0;
                    return Container(
                      width: size + t * 76,
                      height: size + t * 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.35 * (1 - t)),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
            if (widget.progress != null && widget.isRecording)
              SizedBox(
                width: size + 14,
                height: size + 14,
                child: CircularProgressIndicator(
                  value: widget.progress,
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.isBusy
                    ? CupertinoIcons.arrow_2_circlepath
                    : (widget.isRecording
                        ? CupertinoIcons.stop_fill
                        : CupertinoIcons.mic_fill),
                color: AppColors.ink1,
                size: size * 0.34,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
