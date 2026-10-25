import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

enum AnswerState { idle, correct, wrong, dimmed }

/// Mashq/test javob tugmasi: holatga qarab rangi silliq o'zgaradi va
/// to'g'ri/xato belgisi chiqadi.
class AnswerOption extends StatefulWidget {
  final String label;
  final AnswerState state;
  final VoidCallback? onTap;

  const AnswerOption({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  State<AnswerOption> createState() => _AnswerOptionState();
}

class _AnswerOptionState extends State<AnswerOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    Color bg = palette.fieldFill;
    Color border = palette.fieldBorder;
    Color fg = palette.textHi;
    IconData? icon;
    switch (widget.state) {
      case AnswerState.correct:
        bg = AppColors.success.withValues(alpha: 0.16);
        border = AppColors.success;
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
      case AnswerState.wrong:
        bg = AppColors.danger.withValues(alpha: 0.14);
        border = AppColors.danger;
        fg = AppColors.danger;
        icon = Icons.cancel_rounded;
      case AnswerState.dimmed:
        fg = palette.textLow;
      case AnswerState.idle:
        break;
    }
    return Listener(
      onPointerDown: (_) {
        if (widget.onTap != null) setState(() => _pressed = true);
      },
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: border,
                width: widget.state == AnswerState.idle ||
                        widget.state == AnswerState.dimmed
                    ? 1
                    : 1.6),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      widget.onTap!();
                    },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(widget.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5)),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: 20, color: fg),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
