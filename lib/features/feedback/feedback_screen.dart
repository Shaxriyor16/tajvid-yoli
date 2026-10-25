import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/bloc/app_config_cubit.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/screen_header.dart';
import '../auth/auth_bloc.dart';
import 'feedback_service.dart';

/// Ilova ichida fikr bildirish: yulduz, tur va matn. Admin panelga tushadi.
class FeedbackScreen extends StatefulWidget {
  final FeedbackSender sender;
  const FeedbackScreen({super.key, this.sender = FeedbackService.send});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _text = TextEditingController();
  int _rating = 0;
  String _category = 'idea';
  bool _sending = false;
  bool _done = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) _version = '${i.version}+${i.buildNumber}';
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthBloc>().state;
    final message = _text.text.trim();
    if (_rating == 0) return _snack(l10n.get('fb_need_rating'));
    if (message.length < 3) return _snack(l10n.get('fb_need_text'));
    if (auth is! AuthAuthenticated) return _snack(l10n.get('fb_error'));
    final lang = context.read<AppConfigCubit>().state.locale.languageCode;

    HapticFeedback.mediumImpact();
    setState(() => _sending = true);
    try {
      await widget.sender(FeedbackEntry(
        uid: auth.user.uid,
        name: auth.user.fullName,
        email: auth.user.email,
        rating: _rating,
        category: _category,
        message: message,
        appVersion: _version,
        locale: lang,
      ));
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _done = true;
        _sending = false;
      });
    } on FeedbackTooFast {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack(l10n.get('fb_too_fast'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack(l10n.get('fb_error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                  title: l10n.get('fb_title'),
                  subtitle: l10n.get('fb_subtitle')),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _done
                      ? const _Thanks(key: ValueKey('done'))
                      : ListView(
                          key: const ValueKey('form'),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 22, horizontal: 16),
                              child: Column(
                                children: [
                                  Text(l10n.get('fb_rating_hint'),
                                      style: TextStyle(
                                          color: palette.textMid,
                                          fontSize: 14)),
                                  const SizedBox(height: 14),
                                  _Stars(
                                    value: _rating,
                                    onChanged: (v) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _rating = v);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedOpacity(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    opacity: _rating == 0 ? 0 : 1,
                                    child: Text(
                                      _rating == 0
                                          ? ' '
                                          : l10n.get('fb_r$_rating'),
                                      style: AppTheme.display(
                                          size: 16, color: palette.accentGold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in FeedbackEntry.categories)
                                  _CategoryChip(
                                    label: l10n.get('fb_cat_$c'),
                                    selected: _category == c,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _category = c);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _text,
                              minLines: 5,
                              maxLines: 9,
                              maxLength: FeedbackEntry.maxMessage,
                              textInputAction: TextInputAction.newline,
                              enabled: !_sending,
                              style: TextStyle(
                                  color: palette.textHi, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: l10n.get('fb_hint'),
                                hintStyle: TextStyle(color: palette.textLow),
                                filled: true,
                                fillColor: palette.fieldFill,
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      BorderSide(color: palette.fieldBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      BorderSide(color: palette.fieldBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                      color: palette.accentGold, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GradientButton(
                              label: _sending
                                  ? l10n.get('fb_sending')
                                  : l10n.get('fb_send'),
                              icon: CupertinoIcons.paperplane_fill,
                              enabled: !_sending,
                              onTap: _submit,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stars({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.ltr,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedScale(
                scale: i <= value ? 1.12 : 1,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  i <= value ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  size: 40,
                  color: i <= value ? AppColors.gold2 : palette.textLow,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold2.withValues(alpha: 0.18)
              : palette.fieldFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected
                  ? AppColors.gold2.withValues(alpha: 0.7)
                  : palette.fieldBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? palette.accentGold : palette.textMid)),
      ),
    );
  }
}

class _Thanks extends StatelessWidget {
  const _Thanks({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.tealGradient,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.teal1.withValues(alpha: 0.4),
                      blurRadius: 30)
                ],
              ),
              child: const Icon(CupertinoIcons.checkmark_alt,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(l10n.get('fb_thanks_title'),
                textAlign: TextAlign.center,
                style: AppTheme.display(size: 24, color: palette.textHi)),
            const SizedBox(height: 10),
            Text(l10n.get('fb_thanks_body'),
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textMid, height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: GradientButton(
                label: l10n.get('close'),
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
