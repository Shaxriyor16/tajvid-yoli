import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'islamic_pattern.dart';

/// Kirish / ro'yxatdan o'tish ekranlari uchun brend sarlavha:
/// zumrad gradient, islomiy naqsh, oltin yorug'lik va logotip.
class AuthBrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;
  final bool heroLogo;
  final bool rounded;

  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = false,
    this.heroLogo = false,
    this.rounded = false,
  });

  static const _gold = Color(0xFFE8C77B);

  @override
  Widget build(BuildContext context) {
    final radius = rounded
        ? BorderRadius.circular(36)
        : const BorderRadius.vertical(bottom: Radius.circular(36));
    Widget logo = Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset('assets/logo.png', fit: BoxFit.cover),
      ),
    );
    if (heroLogo) logo = Hero(tag: 'app_logo', child: logo);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [Color(0xFF16604F), Color(0xFF0F4A3D), Color(0xFF0A2E27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4A3D).withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Colors.white, Colors.transparent],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ).createShader(rect),
                child: IslamicPattern(
                  color: _gold.withValues(alpha: 0.14),
                  cell: 52,
                ),
              ),
            ),
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _gold.withValues(alpha: 0.28),
                    _gold.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 56),
                child: Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: showBack
                            ? _BackButton(
                                onTap: () => context.canPop()
                                    ? context.pop()
                                    : context.go('/login'),
                              )
                            : null,
                      ),
                    ),
                    logo,
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTheme.display(size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFCCE1DA), height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: CircleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

/// Auth sahifasi karkasi: fon, brend sarlavha va unga qisman kirib turuvchi
/// forma kartasi. Keng ekranlarda markazga joylashadi.
class AuthPage extends StatelessWidget {
  final AuthBrandHeader Function(bool wide) header;
  final List<Widget> children;

  const AuthPage({super.key, required this.header, required this.children});

  static const _overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 460 : double.infinity),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: wide ? 24 : 0),
              child: Column(
                children: [
                  header(wide),
                  Transform.translate(
                    offset: const Offset(0, -_overlap),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: children),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fokus olganda oltin hoshiya va yorug'lik bilan ajralib turadigan maydon.
class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final Widget? suffix;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.suffix,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: palette.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? palette.accentGold : palette.fieldBorder,
          width: focused ? 1.6 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: palette.accentGold.withValues(alpha: 0.18),
                  blurRadius: 14,
                ),
              ]
            : const [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscureText,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        autofocus: widget.autofocus,
        buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) =>
            null,
        style: TextStyle(color: palette.textHi),
        cursorColor: palette.accentGold,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: palette.textLow.withValues(alpha: 0.55)),
          prefixIcon: Icon(widget.icon,
              color: focused ? palette.accentGold : palette.textLow, size: 22),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    widget.obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: palette.textLow,
                    size: 20,
                  ),
                  onPressed: widget.onToggleVisibility,
                )
              : widget.suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
