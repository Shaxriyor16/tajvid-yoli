import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/adaptive_shell.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/db/app_database.dart';
import '../../core/widgets/islamic_pattern.dart';
import '../../core/widgets/motion.dart';
import '../auth/auth_bloc.dart';
import 'home_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        db: context.read<AppDatabase>(),
        authBloc: context.read<AuthBloc>(),
      )..fetchData(),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final isDesktop = Breakpoints.isDesktop(context);
          final palette = AppPalette.of(context);
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: RefreshIndicator.adaptive(
              onRefresh: () => context.read<HomeCubit>().fetchData(),
              color: palette.accentGold,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: isDesktop
                            ? _DesktopHome(state: state)
                            : _MobileHome(state: state),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PracticeHero extends StatelessWidget {
  const _PracticeHero();

  static const _gold = Color(0xFFE8C77B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF16604F), Color(0xFF0F4A3D), Color(0xFF0A2E27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4A3D).withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.35, 1],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(rect),
                child: IslamicPattern(
                  color: _gold.withValues(alpha: 0.11),
                  cell: 52,
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _gold.withValues(alpha: 0.28),
                    _gold.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
            Positioned(
              right: 22,
              top: 20,
              child: IgnorePointer(
                child: Text('بِسْمِ اللَّهِ',
                    style: AppTheme.arabic(
                        size: 26, color: _gold.withValues(alpha: 0.55))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(CupertinoIcons.waveform, color: _gold, size: 20),
                    SizedBox(width: 10),
                    Text('TAJVID • AI MASHQ',
                        style: TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                  ]),
                  const SizedBox(height: 20),
                  Text(l10n.get('hero_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          height: 1.25)),
                  const SizedBox(height: 10),
                  Text(l10n.get('hero_subtitle'),
                      style: const TextStyle(
                          color: Color(0xFFCCE1DA), height: 1.5)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold2.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                          child: Text(l10n.get('start_practice'),
                              style: const TextStyle(
                                  color: Color(0xFF183C32),
                                  fontWeight: FontWeight.w700))),
                      const SizedBox(width: 12),
                      const Icon(CupertinoIcons.arrow_right,
                          size: 18, color: Color(0xFF183C32)),
                    ]),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/ai-check');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileHome extends StatelessWidget {
  final HomeState state;
  const _MobileHome({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GreetRow(state: state),
        const SizedBox(height: 14),
        FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: _StreakChip(days: state.streakDays)),
        const SizedBox(height: 16),
        const FadeSlideIn(
            delay: Duration(milliseconds: 120), child: _PracticeHero()),
        const SizedBox(height: 16),
        FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: _GoalCard(state: state)),
        const SizedBox(height: 16),
        FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: _ContinueCard(state: state)),
        const SizedBox(height: 24),
        _SectionLabel(l10n.get('sections')),
        const SizedBox(height: 10),
        const FadeSlideIn(
            delay: Duration(milliseconds: 300), child: _TopicRow()),
      ],
    );
  }
}

class _DesktopHome extends StatelessWidget {
  final HomeState state;
  const _DesktopHome({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GreetRow(state: state),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StreakChip(days: state.streakDays),
                  const SizedBox(height: 16),
                  _ContinueCard(state: state),
                  const SizedBox(height: 24),
                  _SectionLabel(l10n.get('sections')),
                  const SizedBox(height: 10),
                  const _PracticeHero(),
                  const SizedBox(height: 16),
                  const _TopicRow(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _GoalCard(state: state)),
          ],
        ),
      ],
    );
  }
}

class _GreetRow extends StatelessWidget {
  final HomeState state;
  const _GreetRow({required this.state});

  Widget _initial() => Center(
        child: Text(
          state.userName.isNotEmpty
              ? state.userName.substring(0, 1).toUpperCase()
              : '?',
          style:
              const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      );

  /// Profil rasmi (internetdagi yoki qurilmadagi); bo'lmasa ism bosh harfi.
  Widget _avatar() {
    final url = state.photoUrl;
    if (url == null || url.isEmpty) return _initial();
    final fallback = (BuildContext _, Object __, StackTrace? ___) => _initial();
    return url.startsWith('http')
        ? Image.network(url,
            fit: BoxFit.cover,
            width: 44,
            height: 44,
            cacheWidth: 132,
            errorBuilder: fallback)
        : Image.file(File(url),
            fit: BoxFit.cover,
            width: 44,
            height: 44,
            cacheWidth: 132,
            errorBuilder: fallback);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold2.withValues(alpha: 0.2),
                blurRadius: 16,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset('assets/logo.png', fit: BoxFit.cover),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.get('greeting'),
                  style: TextStyle(color: palette.textMid, fontSize: 13)),
              Text(
                  state.userName.isEmpty ? l10n.get('student') : state.userName,
                  style: AppTheme.display(size: 20, color: palette.textHi)),
            ],
          ),
        ),
        _IconButton(
          icon: CupertinoIcons.search,
          onTap: () => context.push('/search'),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/profile');
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.tealGradient,
              border: Border.all(
                  color: AppColors.gold1.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppColors.teal1.withValues(alpha: 0.3),
                    blurRadius: 12)
              ],
            ),
            child: ClipOval(child: _avatar()),
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.fieldBorder),
        ),
        child: Icon(icon, color: palette.textHi, size: 20),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int days;
  const _StreakChip({required this.days});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold2.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.flame_fill, size: 16, color: palette.accentGold),
          const SizedBox(width: 6),
          Text('$days ${l10n.get('streak')}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: palette.accentGold,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final HomeState state;
  const _GoalCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: state.goalRatio),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: palette.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.gold2),
                    ),
                  ),
                ),
                Text('${(state.goalRatio * 100).round()}%',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: palette.textHi)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.get('daily_goal'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: palette.textHi)),
                const SizedBox(height: 4),
                Text('${state.xpToday} / ${state.xpGoal} XP',
                    style: TextStyle(fontSize: 12, color: palette.textMid)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final HomeState state;
  const _ContinueCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GlassCard(
      onTap: () => context.go('/quran'),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: Text('ب',
                    style: AppTheme.arabic(size: 22, color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.currentLessonTitle,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: palette.textHi)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: state.currentLessonProgress,
                    minHeight: 5,
                    backgroundColor: palette.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.teal1),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: palette.accentGold),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppPalette.of(context).accentGold),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topics = [
      _Topic(
          icon: CupertinoIcons.textformat,
          title: l10n.get('alphabet'),
          count: '28 ${l10n.get('lessons_count')}',
          route: '/alphabet',
          accent: const Color(0xFF1E9E7F)),
      _Topic(
          icon: CupertinoIcons.link,
          title: l10n.get('connections'),
          count: '28 ${l10n.get('lessons_count')}',
          route: '/letter-connections',
          accent: const Color(0xFF3B82C4)),
      _Topic(
          icon: CupertinoIcons.pencil_outline,
          title: l10n.get('harakats'),
          count: '8 ${l10n.get('lessons_count')}',
          route: '/harakat',
          accent: const Color(0xFFC9962F)),
      _Topic(
          icon: CupertinoIcons.text_quote,
          title: l10n.get('reading'),
          count: '8 ${l10n.get('words_count')}',
          route: '/word-reading',
          accent: const Color(0xFFC4577A)),
      _Topic(
          icon: CupertinoIcons.sparkles,
          title: l10n.get('tajvid_rules'),
          count: '6 ${l10n.get('rules_count')}',
          route: '/tajwid-course',
          accent: const Color(0xFF7B63C7)),
      _Topic(
          icon: CupertinoIcons.checkmark_circle,
          title: l10n.get('practice'),
          count: '40 ${l10n.get('lessons_count')}',
          route: '/quiz',
          accent: const Color(0xFFD9772B)),
      _Topic(
          icon: CupertinoIcons.calendar_today,
          title: l10n.get('daily_plan'),
          count: '4 ${l10n.get('tasks_count')}',
          route: '/daily-plan',
          accent: const Color(0xFF2BA3B8)),
      _Topic(
          icon: CupertinoIcons.waveform,
          title: l10n.get('recitation_finder'),
          count: 'AI',
          route: '/recitation-finder',
          accent: const Color(0xFFB65BC4)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600
            ? 3
            : constraints.maxWidth < 300
                ? 1
                : 2;
        final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: topics
              .map((topic) => SizedBox(
                    width: width,
                    child: _TopicCard(topic: topic),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _TopicCard extends StatelessWidget {
  final _Topic topic;
  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        if (topic.route != null) {
          context.push(topic.route!);
        }
      },
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  topic.accent.withValues(alpha: 0.26),
                  topic.accent.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: topic.accent.withValues(alpha: 0.25)),
            ),
            child: Icon(topic.icon, color: topic.accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(topic.title,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: palette.textHi)),
          const SizedBox(height: 4),
          Text(topic.count,
              style: TextStyle(fontSize: 12, color: palette.textLow)),
        ],
      ),
    );
  }
}

class _Topic {
  final IconData icon;
  final String title;
  final String count;
  final String? route;
  final Color accent;
  const _Topic(
      {required this.icon,
      required this.title,
      required this.count,
      required this.route,
      required this.accent});
}
