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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (!InputValidators.isValidName(firstName) ||
        !InputValidators.isValidName(lastName)) {
      _showSnackBar(l10n.get('fill_fields'));
      return;
    }
    if (!InputValidators.isValidEmail(email)) {
      _showSnackBar(l10n.get('invalid_email'));
      return;
    }
    if (!InputValidators.isValidPassword(password)) {
      _showSnackBar(l10n.get('weak_password'));
      return;
    }
    context.read<AuthBloc>().add(
          AuthEmailSignUpRequested(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthNeedsEmailVerification) {
          context.go('/verify-email');
        } else if (state is AuthError) {
          _showSnackBar(AppLocalizations.of(context).get(state.message));
        }
      },
      child: AuthPage(
        header: (wide) => AuthBrandHeader(
          title: l10n.get('register'),
          subtitle: l10n.get('register_subtitle'),
          showBack: true,
          rounded: wide,
        ),
        children: [
          FadeSlideIn(child: _buildForm(l10n)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      radius: 28,
      child: Column(
        children: [
          PremiumTextField(
            controller: _firstNameController,
            hint: l10n.get('first_name'),
            icon: Icons.person_outline,
            maxLength: InputValidators.nameMaxLength,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
          ),
          const SizedBox(height: 16),
          PremiumTextField(
            controller: _lastNameController,
            hint: l10n.get('last_name'),
            icon: Icons.person_outline,
            maxLength: InputValidators.nameMaxLength,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.familyName],
          ),
          const SizedBox(height: 16),
          PremiumTextField(
            controller: _emailController,
            hint: l10n.get('email'),
            icon: Icons.email_outlined,
            maxLength: InputValidators.emailMaxLength,
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
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submit(),
            onToggleVisibility: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          const SizedBox(height: 28),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => GradientButton(
              label: l10n.get('register'),
              onTap: state is AuthLoading ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
