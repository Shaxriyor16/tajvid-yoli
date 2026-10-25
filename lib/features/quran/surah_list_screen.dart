import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/ornaments.dart';
import '../../core/widgets/screen_header.dart';
import 'quran_data.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  late Future<List<Surah>> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = context.read<QuranRepository>().getSurahList();
    _searchController.addListener(() {
      final value = _searchController.text.trim().toLowerCase();
      if (value != _query) setState(() => _query = value);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _future = context.read<QuranRepository>().getSurahList());
  }

  bool _matches(Surah s) {
    if (_query.isEmpty) return true;
    return '${s.number}'.startsWith(_query) ||
        s.englishName.toLowerCase().contains(_query) ||
        s.arabicName.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureBuilder<List<Surah>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _SkeletonList();
            }
            if (snapshot.hasError) {
              return _ErrorView(
                message: l10n.get('err_no_internet'),
                onRetry: _retry,
              );
            }

            final all = snapshot.data ?? const <Surah>[];
            final surahs = all.where(_matches).toList();
            return Column(
              children: [
                ScreenHeader(
                  title: l10n.get('quran'),
                  subtitle: l10n
                      .get('quran_subtitle')
                      .replaceAll('{n}', '${all.length}'),
                  showBackButton: false,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: PremiumTextField(
                    controller: _searchController,
                    hint: l10n.get('search_surah'),
                    icon: CupertinoIcons.search,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                Expanded(
                  child: surahs.isEmpty
                      ? Center(
                          child: Text(l10n.get('no_results'),
                              style: TextStyle(
                                  color: AppPalette.of(context).textLow)),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          itemCount: surahs.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final tile = _SurahTile(surah: surahs[i]);
                            return i < 8
                                ? FadeSlideIn(
                                    delay: Duration(milliseconds: 40 * i),
                                    offset: 12,
                                    child: tile)
                                : tile;
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final Surah surah;
  const _SurahTile({required this.surah});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final meccan = surah.revelationType.toLowerCase().startsWith('mec');
    final medinan = surah.revelationType.toLowerCase().startsWith('med');
    final typeLabel = meccan
        ? l10n.get('meccan')
        : medinan
            ? l10n.get('medinan')
            : surah.revelationType;
    final typeColor = meccan
        ? const Color(0xFF1E9E7F)
        : medinan
            ? const Color(0xFF3B82C4)
            : palette.textLow;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/quran/${surah.number}');
      },
      child: Row(
        children: [
          StarBadge(
            size: 48,
            child: Text(
              '${surah.number}',
              style: TextStyle(
                  color: palette.accentGold,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(surah.englishName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: palette.textHi)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (typeLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(typeLabel,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor)),
                      ),
                    Text(
                        l10n
                            .get('ayahs_n')
                            .replaceAll('{n}', '${surah.totalAyahs}'),
                        style: TextStyle(fontSize: 12, color: palette.textLow)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(surah.arabicName,
              style: AppTheme.arabic(size: 26, color: palette.accentGold)),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Pulse(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 96, 20, 0),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.wifi_slash, color: palette.textLow, size: 54),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textMid)),
            const SizedBox(height: 24),
            SizedBox(
                width: 220,
                child: GradientButton(
                    label: l10n.get('plan_retry'), onTap: onRetry)),
          ],
        ),
      ),
    );
  }
}
