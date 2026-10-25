import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/input_validators.dart';
import '../../core/widgets/auth_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/motion.dart';
import 'auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.ink1.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    if (context.read<AuthBloc>().state is AuthLoading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(l10n.get('fill_fields'));
      return;
    }
    if (!InputValidators.isValidEmail(email)) {
      _showSnackBar(l10n.get('invalid_email'));
      return;
    }
    context.read<AuthBloc>().add(AuthEmailSignInRequested(email, password));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthNeedsEmailVerification) {
          context.go('/verify-email');
        } else if (state is AuthNeedsProfileCompletion) {
          context.go('/complete-profile');
        } else if (state is AuthError) {
          _showSnackBar(AppLocalizations.of(context).get(state.message));
        }
      },
      child: AuthPage(
        header: (wide) => AuthBrandHeader(
          title: l10n.get('welcome'),
          subtitle: l10n.get('welcome_subtitle'),
          heroLogo: true,
          rounded: wide,
        ),
        children: [
          FadeSlideIn(child: _buildGlassForm(l10n)),
          const SizedBox(height: 24),
          FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _buildDivider(l10n)),
          const SizedBox(height: 24),
          FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: _buildSocialButtons(l10n)),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.get('no_account'),
                  style: TextStyle(color: palette.textMid)),
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text(l10n.get('sign_up'),
                    style: TextStyle(
                        color: palette.accentGold,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDivider(AppLocalizations l10n) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: palette.glassBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.get('or'),
              style: TextStyle(color: palette.textLow.withValues(alpha: 0.7))),
        ),
        Expanded(child: Divider(color: palette.glassBorder)),
      ],
    );
  }

  Widget _buildGlassForm(AppLocalizations l10n) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      radius: 28,
      child: Column(
        children: [
          PremiumTextField(
            controller: _emailController,
            hint: l10n.get('email'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),
          PremiumTextField(
            controller: _passwordController,
            hint: l10n.get('password'),
            icon: Icons.lock_outline,
            isPassword: true,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            onToggleVisibility: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          const SizedBox(height: 24),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => GradientButton(
              label: l10n.get('login'),
              onTap: state is AuthLoading ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButtons(AppLocalizations l10n) {
    final isLoading = context.watch<AuthBloc>().state is AuthLoading;
    return Column(
      children: [
        _SocialButton(
          logo: 'assets/icons/google.png',
          label: l10n.get('google_sign_in'),
          onTap: isLoading
              ? null
              : () => context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
        ),
        const SizedBox(height: 12),
        _SocialButton(
          logo: 'assets/icons/apple.png',
          label: l10n.get('apple_sign_in'),
          onTap: isLoading
              ? null
              : () => context.read<AuthBloc>().add(AuthAppleSignInRequested()),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String logo;
  final String label;
  final VoidCallback? onTap;

  const _SocialButton(
      {required this.logo, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        radius: 18,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(logo, width: 22, height: 22),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: palette.textHi,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
