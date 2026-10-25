import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/auth_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/motion.dart';
import 'auth_bloc.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    if (_firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty) {
      context.read<AuthBloc>().add(
            AuthProfileCompleteRequested(
              _firstNameController.text.trim(),
              _lastNameController.text.trim(),
            ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('fill_fields'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthPage(
      header: (wide) => AuthBrandHeader(
        title: l10n.get('complete_profile'),
        subtitle: l10n.get('enter_name_last'),
        rounded: wide,
      ),
      children: [
        FadeSlideIn(
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            radius: 28,
            child: Column(
              children: [
                PremiumTextField(
                  controller: _firstNameController,
                  hint: l10n.get('first_name'),
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: _lastNameController,
                  hint: l10n.get('last_name'),
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.familyName],
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 28),
                GradientButton(label: l10n.get('ready'), onTap: _submit),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
