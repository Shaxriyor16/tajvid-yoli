import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/adaptive_shell.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import '../../core/widgets/screen_header.dart';
import '../../core/bloc/app_config_cubit.dart';
import '../../core/db/app_database.dart';
import '../../core/l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../auth/auth_bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifLoading = true;
  bool _notifEnabled = false;
  bool _tipsEnabled = true;
  bool _deleting = false;
  String _appVersion = '';


  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // Versiya ko'rsatilmasa ham ekran ishlayveradi.
    }
  }

  Future<void> _deleteAccount() async {
    if (_deleting) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(l10n.get('delete_account')),
              content: Text(l10n.get('delete_account_confirm')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(l10n.get('cancel'))),
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(l10n.get('delete_account'))),
              ],
            ));
    if (confirmed != true || !mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final uid = authState.user.uid;
    final authBloc = context.read<AuthBloc>();
    final authService = context.read<AuthService>();
    final database = context.read<AppDatabase>();
    setState(() => _deleting = true);
    try {
      await authService.deleteAccount();
      await database.deleteUserData(uid);
      authBloc.add(AuthSignOutRequested());
    } catch (e) {
      if (!mounted) return;
      final message =
          e is FirebaseFunctionsException && e.code == 'failed-precondition'
              ? l10n.get('delete_reauth')
              : l10n.get('delete_failed');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadNotificationState();
  }

  Future<void> _loadNotificationState() async {
    final service = context.read<NotificationService>();
    final hasPerm = await service.hasPermission();
    final settings = await service.getReminderSettings();
    final tips = await service.getTipsEnabled();
    if (mounted) {
      setState(() {
        _tipsEnabled = tips;
        _reminderTime = settings.time;
        _notifEnabled = hasPerm && settings.enabled;
        _notifLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final service = context.read<NotificationService>();
    HapticFeedback.lightImpact();
    if (value) {
      final granted = await service.requestPermission();
      if (!mounted) return;
      if (!granted) {
        if (mounted) setState(() => _notifEnabled = false);
        await _showPermissionDenied();
        return;
      }
      final time = await _pickReminderTime();
      if (time == null) {
        if (mounted) setState(() => _notifEnabled = false);
        return;
      }
      final scheduled = await service.enableDailyReminder(time);
      if (mounted) {
        setState(() {
          _notifEnabled = scheduled;
          if (scheduled) _reminderTime = time;
        });
        if (!scheduled) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${l10n.get('notif_failed')}\n${service.lastError ?? ''}'),
            duration: const Duration(seconds: 8),
          ));
        }
      }
    } else {
      await service.disableDailyReminder();
      if (mounted) setState(() => _notifEnabled = false);
    }
  }

  Future<void> _showPermissionDenied() async {
    final l10n = AppLocalizations.of(context);
    final open = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.get('notif_denied_title')),
        content: Text(l10n.get('notif_denied_body')),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.get('cancel')),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.get('open_settings')),
          ),
        ],
      ),
    );
    if (open == true) await openAppSettings();
  }

  Future<void> _toggleTips(bool value) async {
    HapticFeedback.lightImpact();
    setState(() => _tipsEnabled = value);
    await context.read<NotificationService>().setTipsEnabled(value);
  }

  Future<TimeOfDay?> _pickReminderTime() {
    return showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: AppLocalizations.of(context).get('reminder_time_help'),
    );
  }

  Future<void> _changeReminderTime() async {
    final service = context.read<NotificationService>();
    final time = await _pickReminderTime();
    if (time == null) return;
    final scheduled = await service.enableDailyReminder(time);
    if (scheduled && mounted) setState(() => _reminderTime = time);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _pickLanguage(AppConfigCubit cubit, Locale current) async {
    HapticFeedback.mediumImpact();
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => _LanguageSheet(current: current.languageCode),
    );
    if (choice != null && mounted) {
      cubit.setLocale(Locale(choice));
    }
  }

  void _pickTheme(AppConfigCubit cubit, ThemeMode current) async {
    HapticFeedback.mediumImpact();
    final choice = await showCupertinoModalPopup<ThemeMode>(
      context: context,
      builder: (context) => _ThemeSheet(current: current),
    );
    if (choice != null && mounted) {
      cubit.setThemeMode(choice);
    }
  }

  String _getLangName(AppLocalizations l10n, String code) {
    switch (code) {
      case 'uz':
        return l10n.get('uzbek_latin');
      case 'ar':
        return l10n.get('arabic');
      case 'en':
        return l10n.get('english');
      default:
        return l10n.get('uzbek_latin');
    }
  }

  String _getThemeName(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return l10n.get('dark_mode');
      case ThemeMode.light:
        return l10n.get('light_mode');
      case ThemeMode.system:
        return l10n.get('system_mode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final config = context.watch<AppConfigCubit>().state;
    final cubit = context.read<AppConfigCubit>();
    final l10n = AppLocalizations(config.locale);
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            isDesktop ? 60 : 0, 0, isDesktop ? 60 : 0, isDesktop ? 40 : 120),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(title: l10n.get('settings')),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _SettingsGroup(
                        title: l10n.get('general_section'),
                        children: [
                          _SettingsTile(
                            icon: CupertinoIcons.globe,
                            accent: const Color(0xFF1E9E7F),
                            title: l10n.get('language'),
                            trailing: Text(
                                _getLangName(l10n, config.locale.languageCode),
                                style: TextStyle(
                                    color: palette.textLow, fontSize: 13)),
                            onTap: () => _pickLanguage(cubit, config.locale),
                          ),
                          _SettingsTile(
                            icon: config.themeMode == ThemeMode.dark
                                ? CupertinoIcons.moon_fill
                                : CupertinoIcons.sun_max_fill,
                            accent: const Color(0xFF7B63C7),
                            title: l10n.get('theme'),
                            trailing: Text(
                                _getThemeName(l10n, config.themeMode),
                                style: TextStyle(
                                    color: palette.textLow, fontSize: 13)),
                            onTap: () => _pickTheme(cubit, config.themeMode),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SettingsGroup(
                        title: l10n.get('notifications').toUpperCase(),
                        children: [
                          _SettingsTile(
                            icon: CupertinoIcons.bell_fill,
                            accent: const Color(0xFFD9772B),
                            title: l10n.get('notifications'),
                            subtitle: _notifEnabled
                                ? l10n.get('daily_at').replaceAll(
                                    '{time}', _formatTime(_reminderTime))
                                : null,
                            trailing: _notifLoading
                                ? const CupertinoActivityIndicator(radius: 8)
                                : CupertinoSwitch(
                                    value: _notifEnabled,
                                    onChanged: _toggleNotifications,
                                    activeTrackColor: AppColors.teal1,
                                  ),
                            onTap: _notifEnabled ? _changeReminderTime : null,
                          ),
                          if (_notifEnabled)
                            _SettingsTile(
                              icon: CupertinoIcons.lightbulb_fill,
                              accent: const Color(0xFFE8C77B),
                              title: l10n.get('notif_tips'),
                              subtitle: l10n.get('notif_tips_sub'),
                              trailing: CupertinoSwitch(
                                value: _tipsEnabled,
                                onChanged: _toggleTips,
                                activeTrackColor: AppColors.teal1,
                              ),
                              onTap: () => _toggleTips(!_tipsEnabled),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SettingsGroup(
                        title: l10n.get('help_support').toUpperCase(),
                        children: [
                          _SettingsTile(
                            icon: CupertinoIcons.question_circle,
                            accent: const Color(0xFF3B82C4),
                            title: l10n.get('faq'),
                            trailing: Icon(CupertinoIcons.chevron_right,
                                color: palette.textLow, size: 14),
                            onTap: () => context.push('/faq'),
                          ),
                          _SettingsTile(
                            icon: CupertinoIcons.chat_bubble_text,
                            accent: const Color(0xFFC4577A),
                            title: l10n.get('send_feedback'),
                            trailing: Icon(CupertinoIcons.chevron_right,
                                color: palette.textLow, size: 14),
                            onTap: () => context.push('/feedback'),
                          ),
                          _SettingsTile(
                            icon: CupertinoIcons.mail,
                            accent: const Color(0xFF2BA3B8),
                            title: l10n.get('contact_us'),
                            trailing: Icon(CupertinoIcons.chevron_right,
                                color: palette.textLow, size: 14),
                            onTap: () {
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: Text(l10n.get('contact_us')),
                                  content: const Text(
                                      'Email: support@tajvidyoli.uz\nTelegram: @m24_shaxa'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: Text(l10n.get('close')),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          _SettingsTile(
                            icon: CupertinoIcons.shield_lefthalf_fill,
                            accent: const Color(0xFF2F9E5B),
                            title: l10n.get('privacy_policy'),
                            trailing: Icon(CupertinoIcons.chevron_right,
                                color: palette.textLow, size: 14),
                            onTap: () {
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: Text(l10n.get('privacy_policy')),
                                  content: Text(l10n.get('privacy_text')),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: Text(l10n.get('understood')),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SettingsGroup(
                          title: l10n.get('account_section'),
                          children: [
                            _SettingsTile(
                                icon: CupertinoIcons.trash,
                                accent: AppColors.danger,
                                title: _deleting
                                    ? l10n.get('deleting')
                                    : l10n.get('delete_account'),
                                onTap: _deleting ? null : _deleteAccount,
                                trailing: _deleting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(CupertinoIcons.chevron_right,
                                        size: 14)),
                          ]),
                      const SizedBox(height: 40),
                      Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: palette.accentGold
                                      .withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold2.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: Image.asset('assets/logo.png',
                                  fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text("Tajvid yo'li",
                              style: AppTheme.display(
                                  size: 17, color: palette.textHi)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: palette.accentGold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                                '${l10n.get('version')} ${_appVersion.isEmpty ? '1.0.0' : _appVersion}',
                                style: TextStyle(
                                    color: palette.accentGold,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: palette.accentGold)),
        ),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      thickness: 1,
                      indent: 68,
                      endIndent: 16,
                      color: palette.divider),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.26),
                    accent.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: palette.textHi,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(color: palette.textLow, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final String current;
  const _LanguageSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations(Locale(current));
    final palette = AppPalette.of(context);

    final options = [
      {'name': l10n.get('uzbek_latin'), 'code': 'uz'},
      {'name': l10n.get('arabic'), 'code': 'ar'},
      {'name': l10n.get('english'), 'code': 'en'},
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: BoxDecoration(
          color: palette.sheetFill,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: palette.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.get('select_language'),
                style: TextStyle(
                    color: palette.textHi,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options
                    .map((o) => _SheetOption(
                          selected: o['code'] == current,
                          onTap: () => Navigator.pop(context, o['code']),
                          child: Text(o['name']!,
                              style: TextStyle(
                                color: o['code'] == current
                                    ? palette.accentGold
                                    : palette.textMid,
                                fontWeight: o['code'] == current
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  final ThemeMode current;
  const _ThemeSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations(Localizations.localeOf(context));
    final palette = AppPalette.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: BoxDecoration(
          color: palette.sheetFill,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Text(l10n.get('select_theme'),
                style: TextStyle(
                    color: palette.textHi,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildThemeOption(context, l10n.get('light_mode'), ThemeMode.light,
                CupertinoIcons.sun_max, l10n),
            _buildThemeOption(context, l10n.get('dark_mode'), ThemeMode.dark,
                CupertinoIcons.moon, l10n),
            _buildThemeOption(context, l10n.get('system_mode'),
                ThemeMode.system, CupertinoIcons.settings, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String name, ThemeMode mode,
      IconData icon, AppLocalizations l10n) {
    final selected = current == mode;
    final palette = AppPalette.of(context);
    return _SheetOption(
      selected: selected,
      onTap: () => Navigator.pop(context, mode),
      leading: Icon(icon,
          color: selected ? palette.accentGold : palette.textLow, size: 22),
      child: Text(name,
          style: TextStyle(
              color: selected ? palette.accentGold : palette.textMid,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
    );
  }
}

/// Pastki oynadagi tanlov qatori: tanlangani oltin hoshiya bilan ajraladi.
class _SheetOption extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final Widget? leading;

  const _SheetOption({
    required this.selected,
    required this.onTap,
    required this.child,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? palette.accentGold.withValues(alpha: 0.10)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: selected ? palette.accentGold : palette.cardBorder,
              width: selected ? 1.4 : 1),
        ),
        child: InkWell(
          customBorder:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(child: child),
                if (selected)
                  Icon(CupertinoIcons.checkmark_circle_fill,
                      color: palette.accentGold, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
