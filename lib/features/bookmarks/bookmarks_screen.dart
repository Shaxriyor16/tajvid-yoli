import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/ornaments.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/db/app_database.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l10n.get('bookmarks')),
            Expanded(
              child: StreamBuilder<List<QuranBookmark>>(
                stream: db.watchBookmarks(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                        child: CupertinoActivityIndicator(
                            color: palette.accentGold, radius: 14));
                  }

                  final bookmarks = snapshot.data!;

                  if (bookmarks.isEmpty) {
                    return FadeSlideIn(child: _EmptyState(l10n: l10n));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: bookmarks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final b = bookmarks[i];
                      return Dismissible(
                        key: ValueKey('${b.surahNumber}:${b.ayahNumber}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          db.removeBookmark(b.surahNumber, b.ayahNumber);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(CupertinoIcons.trash,
                              color: AppColors.danger),
                        ),
                        child: GlassCard(
                          radius: 22,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          onTap: () => context.push(
                              '/quran/${b.surahNumber}?ayah=${b.ayahNumber}'),
                          child: Row(
                            children: [
                              StarBadge(
                                size: 48,
                                child: Text('${b.surahNumber}',
                                    style: TextStyle(
                                        color: palette.accentGold,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  l10n
                                      .get('bookmark_ref')
                                      .replaceAll('{s}', '${b.surahNumber}')
                                      .replaceAll('{a}', '${b.ayahNumber}'),
                                  style: TextStyle(
                                      color: palette.textHi,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                              ),
                              Material(
                                color: AppColors.danger.withValues(alpha: 0.10),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    db.removeBookmark(
                                        b.surahNumber, b.ayahNumber);
                                  },
                                  child: const SizedBox(
                                    width: 38,
                                    height: 38,
                                    child: Icon(CupertinoIcons.trash,
                                        size: 17, color: AppColors.danger),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        palette.accentGold.withValues(alpha: 0.25),
                        palette.accentGold.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                  StarBadge(
                    size: 96,
                    child: Icon(CupertinoIcons.bookmark,
                        size: 34, color: palette.accentGold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.get('bookmarks_empty'),
                textAlign: TextAlign.center,
                style: AppTheme.display(size: 18, color: palette.textHi)),
            const SizedBox(height: 8),
            Text(l10n.get('bookmarks_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: palette.textLow, fontSize: 13.5, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
