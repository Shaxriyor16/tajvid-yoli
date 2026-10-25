import 'dart:io';
import '../auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/adaptive_shell.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/islamic_pattern.dart';
import '../../core/widgets/motion.dart';
import '../../core/db/app_database.dart';
import '../auth/auth_bloc.dart';
import 'profile_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        db: context.read<AppDatabase>(),
        authBloc: context.read<AuthBloc>(),
        authService: context.read<AuthService>(),
      )..loadProfile(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => ProfileView(state: state),
      ),
    );
  }
}

/// Profil ekranining ko'rinishi. Holat tashqaridan beriladi, shuning uchun
/// uni ProfileCubit'siz ham chizib tekshirish mumkin.
class ProfileView extends StatelessWidget {
  final ProfileState state;
  const ProfileView({super.key, required this.state});

  static const _overlap = 28.0;

  Future<void> _changePhoto(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ProfileCubit>().updateProfilePicture();
    } catch (_) {
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.get('photo_save_failed'))));
    }
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.get('logout')),
        content: Text(l10n.get('sign_out_confirm')),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.get('cancel')),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.get('logout')),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = Breakpoints.isDesktop(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            isDesktop ? 60 : 0, isDesktop ? 24 : 0, isDesktop ? 60 : 0, 120),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _ProfileHero(
                  state: state,
                  rounded: isDesktop,
                  onPhoto: () => _changePhoto(context),
                ),
                Transform.translate(
                  offset: const Offset(0, -_overlap),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        FadeSlideIn(child: _StatsGrid(state: state)),
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: Column(
                            children: [
                              _ProfileMenuTile(
                                icon: CupertinoIcons.bookmark_fill,
                                accent: const Color(0xFF3B82C4),
                                title: l10n.get('bookmarks'),
                                onTap: () => context.push('/bookmarks'),
                              ),
                              _ProfileMenuTile(
                                icon: CupertinoIcons.rosette,
                                accent: const Color(0xFFC9962F),
                                title: l10n.get('my_certificates'),
                                onTap: () => context.push('/certificate'),
                              ),
                              _ProfileMenuTile(
                                icon: CupertinoIcons.question_circle,
                                accent: const Color(0xFF1E9E7F),
                                title: l10n.get('faq'),
                                onTap: () => context.push('/faq'),
                              ),
                              const SizedBox(height: 8),
                              if (state.user != null)
                                _ProfileMenuTile(
                                  icon: CupertinoIcons.square_arrow_right,
                                  accent: AppColors.danger,
                                  title: l10n.get('logout'),
                                  isDanger: true,
                                  onTap: () => _confirmLogout(context, l10n),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _ProfileHero extends StatelessWidget {
  final ProfileState state;
  final bool rounded;
  final VoidCallback onPhoto;

  const _ProfileHero({
    required this.state,
    required this.rounded,
    required this.onPhoto,
  });

  static const _gold = Color(0xFFE8C77B);

  Widget _avatar() {
    final photo = state.user?.photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    return GestureDetector(
      onTap: onPhoto,
      child: Stack(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.tealGradient,
              border: Border.all(color: _gold.withValues(alpha: 0.8), width: 3),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: hasPhoto
                  ? (photo.startsWith('http')
                      ? Image.network(photo, fit: BoxFit.cover)
                      : Image.file(File(photo), fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        state.user?.initials ?? '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                            color: Colors.white),
                      ),
                    ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F4A3D), width: 2),
              ),
              child: const Icon(CupertinoIcons.camera_fill,
                  size: 14, color: AppColors.ink1),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = rounded
        ? BorderRadius.circular(36)
        : const BorderRadius.vertical(bottom: Radius.circular(36));
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 56),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.get('profile'),
                              style: AppTheme.display(
                                  size: 24, color: Colors.white)),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: CircleBorder(
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.18))),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/settings');
                            },
                            child: const SizedBox(
                              width: 42,
                              height: 42,
                              child: Icon(CupertinoIcons.settings,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _avatar(),
                    const SizedBox(height: 16),
                    Text(
                      state.user?.fullName ?? l10n.get('student'),
                      textAlign: TextAlign.center,
                      style: AppTheme.display(size: 24, color: Colors.white),
                    ),
                    if ((state.user?.email ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(state.user!.email,
                          style: const TextStyle(color: Color(0xFFCCE1DA))),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold2.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(l10n.get('profile_level'),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink1,
                              letterSpacing: 0.8)),
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

class _StatsGrid extends StatelessWidget {
  final ProfileState state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 14.0;
      final width = (constraints.maxWidth - gap) / 2;
      Widget cell(Widget child) => SizedBox(width: width, child: child);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          cell(_StatCard(
            value: state.completedLessons.toDouble(),
            label: l10n.get('total_lessons'),
            icon: CupertinoIcons.book_fill,
            color: const Color(0xFFC9962F),
          )),
          cell(_StatCard(
            value: state.streakDays.toDouble(),
            label: l10n.get('streak_days'),
            icon: CupertinoIcons.flame_fill,
            color: const Color(0xFFE2762B),
          )),
          cell(_StatCard(
            value: state.averageAccuracy,
            suffix: '%',
            label: l10n.get('avg_accuracy'),
            icon: CupertinoIcons.checkmark_seal_fill,
            color: const Color(0xFF1E9E7F),
          )),
          cell(_StatCard(
            value: state.certificateCount.toDouble(),
            label: l10n.get('certificates'),
            icon: CupertinoIcons.doc_text_fill,
            color: const Color(0xFF3B82C4),
          )),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final double value;
  final String suffix;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.28),
                  color.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text('${v.round()}$suffix',
                style: AppTheme.display(size: 26, color: palette.textHi)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: palette.textLow,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final VoidCallback onTap;
  final bool isDanger;

  const _ProfileMenuTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        radius: 20,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.26),
                    accent.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDanger ? accent : palette.textHi,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                color: palette.textLow.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
}
