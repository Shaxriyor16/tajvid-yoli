import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/db/app_database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/adaptive_shell.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/hero_banner.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/screen_header.dart';
import '../auth/auth_bloc.dart';

class _PlanTask {
  final String id;
  final IconData icon;
  bool done = false;
  _PlanTask({
    required this.id,
    required this.icon,
  });
}

class DailyPlanScreen extends StatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  static const _xpReason = 'daily_plan_complete';
  static const _xpAmount = 50;

  final List<_PlanTask> _tasks = [
    _PlanTask(id: 'read_surah', icon: Icons.menu_book_rounded),
    _PlanTask(id: 'repeat_letters', icon: Icons.text_fields_rounded),
    _PlanTask(id: 'quiz', icon: Icons.fact_check_rounded),
    _PlanTask(id: 'ai_check', icon: Icons.mic_rounded),
  ];

  late final int _todayIndex;
  bool _loaded = false;
  bool _saving = false;
  bool _loadFailed = false;
  String? _loadedDay;

  @override
  void initState() {
    super.initState();
    // DateTime.weekday: 1=Dushanba ... 7=Yakshanba.
    _todayIndex = DateTime.now().weekday - 1;
    _loadTodayState();
  }

  String get _todayKey => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _loadTodayState() async {
    setState(() {
      _loadFailed = false;
      _loaded = false;
    });
    final db = context.read<AppDatabase>();
    final dayKey = _todayKey;
    try {
      final doneIds = await db.getCompletedPlanTaskIds(dayKey);
      if (!mounted) return;
      setState(() {
        for (final t in _tasks) {
          t.done = doneIds.contains('plan_$dayKey.${t.id}');
        }
        _loaded = true;
        _loadedDay = dayKey;
      });
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _toggleTask(_PlanTask task) async {
    if (_saving) return;
    if (_loadedDay != _todayKey) {
      await _loadTodayState();
      return;
    }
    final db = context.read<AppDatabase>();
    final wasDone = task.done;
    final dayKey = _todayKey;
    setState(() => _saving = true);
    try {
      await db.updateLessonProgress(
          'plan_$dayKey.${task.id}', wasDone ? 0.0 : 1.0, !wasDone);
      if (!mounted) return;
      setState(() => task.done = !wasDone);
      if (task.done && _tasks.every((t) => t.done)) {
        await _onAllCompleted(db);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context).get('plan_save_failed'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onAllCompleted(AppDatabase db) async {
    final authState = context.read<AuthBloc>().state;
    final awarded = await db.awardDailyXp(amount: _xpAmount, reason: _xpReason);
    if (awarded) {
      if (authState is AuthAuthenticated) {
        await db.updateUserLastActive(authState.user.uid);
      }
      if (mounted) {
        final palette = AppPalette.of(context);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.get('plan_completed')),
            backgroundColor: palette.accentGold,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  static const _accents = {
    'read_surah': Color(0xFF1E9E7F),
    'repeat_letters': Color(0xFF3B82C4),
    'quiz': Color(0xFFC9962F),
    'ai_check': Color(0xFF7B63C7),
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final weekDays = l10n.get('plan_weekdays').split(',');
    final isDesktop = Breakpoints.isDesktop(context);
    final doneCount = _tasks.where((t) => t.done).length;
    final today = DateTime.now();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loadFailed
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l10n.get('plan_load_failed')),
              TextButton(
                  onPressed: _loadTodayState,
                  child: Text(l10n.get('plan_retry'))),
            ]))
          : _loaded
              ? SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(isDesktop ? 40 : 0, 0,
                      isDesktop ? 40 : 0, isDesktop ? 40 : 110),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: isDesktop ? 480 : double.infinity),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScreenHeader(
                            title: l10n.get('plan_title'),
                            subtitle: l10n.get('plan_subtitle'),
                            showBackButton: false,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                FadeSlideIn(
                                  child: HeroBanner(
                                    kicker:
                                        l10n.get('plan_title').toUpperCase(),
                                    title: '$doneCount/${_tasks.length}',
                                    subtitle: l10n.get('plan_streak_hint'),
                                    trailing: SizedBox(
                                      width: 74,
                                      height: 74,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(
                                            begin: 0,
                                            end: doneCount / _tasks.length),
                                        duration:
                                            const Duration(milliseconds: 700),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, v, _) => Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox.expand(
                                              child: CircularProgressIndicator(
                                                value: v,
                                                strokeWidth: 7,
                                                strokeCap: StrokeCap.round,
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.15),
                                                valueColor:
                                                    const AlwaysStoppedAnimation(
                                                        Color(0xFFE8C77B)),
                                              ),
                                            ),
                                            Text('${(v * 100).round()}%',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: List.generate(7, (i) {
                                    final isToday = i == _todayIndex;
                                    final date = today
                                        .add(Duration(days: i - _todayIndex));
                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: isToday
                                              ? AppColors.goldGradient
                                              : null,
                                          color: isToday
                                              ? null
                                              : palette.fieldFill,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: isToday
                                              ? null
                                              : Border.all(
                                                  color: palette.glassBorder),
                                          boxShadow: isToday
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.gold2
                                                        .withValues(
                                                            alpha: 0.35),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              weekDays[i],
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isToday
                                                    ? AppColors.ink1
                                                    : palette.textLow,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${date.day}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: isToday
                                                    ? AppColors.ink1
                                                    : palette.textHi,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 22),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4, bottom: 12),
                                  child: Text(l10n.get('plan_tasks_header'),
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: palette.accentGold)),
                                ),
                                for (var i = 0; i < _tasks.length; i++)
                                  FadeSlideIn(
                                    delay: Duration(milliseconds: 60 * i),
                                    offset: 10,
                                    child: _TaskCard(
                                      task: _tasks[i],
                                      title: l10n.get('plan_${_tasks[i].id}'),
                                      subtitle:
                                          l10n.get('plan_${_tasks[i].id}_sub'),
                                      accent: _accents[_tasks[i].id] ??
                                          palette.accentGold,
                                      onTap: _saving
                                          ? null
                                          : () => _toggleTask(_tasks[i]),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final _PlanTask task;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  const _TaskCard({
    required this.task,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final done = task.done;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: done ? 0.12 : 0.28),
                    accent.withValues(alpha: done ? 0.05 : 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(task.icon,
                  color: accent.withValues(alpha: done ? 0.5 : 1), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: done ? palette.textLow : palette.textHi,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        decoration: done ? TextDecoration.lineThrough : null,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: palette.textLow, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.success : Colors.transparent,
                border: Border.all(
                    color: done ? AppColors.success : palette.textLow,
                    width: 1.8),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: done ? 1 : 0,
                child: const Icon(Icons.check_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
