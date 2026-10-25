import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import 'glass_widgets.dart';
import 'motion.dart';
import 'ornaments.dart';
import '../l10n/app_localizations.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _notifGranted = false;
  bool _micGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notif = await Permission.notification.status;
    final mic = await Permission.microphone.status;
    if (mounted) {
      setState(() {
        _notifGranted = notif.isGranted;
        _micGranted = mic.isGranted;
      });
    }
  }

  Future<void> _requestNotif() async {
    final status = await Permission.notification.request();
    if (!mounted) return;
    setState(() => _notifGranted = status.isGranted);
  }

  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    setState(() => _micGranted = status.isGranted);
  }

  void _showLimitWarning() {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.get('perm_limit_warning'),
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: palette.sheetFill,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        duration: const Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.go('/login');
    });
  }

  void _continue() {
    if (_notifGranted && _micGranted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _notifGranted && _micGranted;
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeSlideIn(
                      child: SizedBox(
                        width: 170,
                        height: 170,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  palette.accentGold.withValues(alpha: 0.28),
                                  palette.accentGold.withValues(alpha: 0),
                                ]),
                              ),
                            ),
                            StarBadge(
                              size: 112,
                              child: Icon(Icons.shield_outlined,
                                  size: 44, color: palette.accentGold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.get('perm_title'),
                        style:
                            AppTheme.display(size: 26, color: palette.textHi)),
                    const SizedBox(height: 12),
                    Text(
                      l10n.get('perm_intro'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.textMid, height: 1.5),
                    ),
                    const SizedBox(height: 36),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: _PermissionTile(
                        icon: Icons.notifications_active_rounded,
                        accent: const Color(0xFFD9772B),
                        title: l10n.get('perm_notif_title'),
                        description: l10n.get('perm_notif_desc'),
                        isGranted: _notifGranted,
                        grantedLabel: l10n.get('perm_granted'),
                        onTap: _requestNotif,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: _PermissionTile(
                        icon: Icons.mic_rounded,
                        accent: const Color(0xFF7B63C7),
                        title: l10n.get('perm_mic_title'),
                        description: l10n.get('perm_mic_desc'),
                        isGranted: _micGranted,
                        grantedLabel: l10n.get('perm_granted'),
                        onTap: _requestMic,
                      ),
                    ),
                    const Spacer(),
                    GradientButton(
                      label: l10n.get('perm_continue'),
                      enabled: allGranted,
                      onTap: _continue,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _showLimitWarning,
                      child: Text(
                        l10n.get('perm_skip'),
                        style: TextStyle(color: palette.textMid),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final bool isGranted;
  final String grantedLabel;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.grantedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = isGranted ? AppColors.success : accent;
    return GlassCard(
      onTap: isGranted ? null : onTap,
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.28),
                  color.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(isGranted ? Icons.check_rounded : icon,
                color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: palette.textHi,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(
                        color: palette.textLow, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isGranted)
            GlassChip(label: grantedLabel, color: AppColors.success)
          else
            Icon(Icons.chevron_right_rounded, color: palette.textLow),
        ],
      ),
    );
  }
}
