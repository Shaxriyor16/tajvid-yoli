import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/motion.dart';
import 'auth_bloc.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go('/home');
        if (state is AuthNeedsProfileCompletion) {
          context.go('/complete-profile');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final email = state is AuthNeedsEmailVerification ? state.email : '';
          final emailSent =
              state is AuthNeedsEmailVerification && state.emailSent;
          final busy = state is AuthLoading;

          return AuthPage(
            header: (wide) => AuthBrandHeader(
              title: l10n.get('email_verification_title'),
              subtitle: l10n
                  .get('email_verification_message')
                  .replaceAll('{email}', email),
              rounded: wide,
            ),
            children: [
              FadeSlideIn(
                child: GlassCard(
                  radius: 28,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              palette.accentGold.withValues(alpha: 0.3),
                              palette.accentGold.withValues(alpha: 0.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: palette.accentGold.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.mark_email_unread_outlined,
                            size: 30, color: palette.accentGold),
                      ),
                      if (emailSent) ...[
                        const SizedBox(height: 16),
                        GlassChip(
                          label: l10n.get('email_verification_sent'),
                          color: AppColors.success,
                        ),
                      ],
                      const SizedBox(height: 24),
                      GradientButton(
                        label: l10n.get('email_verification_check'),
                        icon: Icons.verified_outlined,
                        onTap: busy
                            ? null
                            : () => context.read<AuthBloc>().add(
                                  AuthEmailVerificationCheckRequested(),
                                ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => context.read<AuthBloc>().add(
                                  AuthEmailVerificationResendRequested(),
                                ),
                        child: Text(l10n.get('email_verification_resend'),
                            style: TextStyle(
                                color: palette.accentGold,
                                fontWeight: FontWeight.w700)),
                      ),
                      TextButton.icon(
                        onPressed: busy
                            ? null
                            : () => context
                                .read<AuthBloc>()
                                .add(AuthSignOutRequested()),
                        icon: Icon(Icons.logout,
                            size: 18, color: palette.textMid),
                        label: Text(l10n.get('logout'),
                            style: TextStyle(color: palette.textMid)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
