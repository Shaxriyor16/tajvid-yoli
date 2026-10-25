import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import 'book_pager.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/islamic_pattern.dart';
import '../../core/widgets/ornaments.dart';
import 'quran_data.dart';
import 'quran_reader_cubit.dart';
import 'ayah_reading.dart';

/// "Kitob rejimi" — Qur'onni Madani mushaf sahifa chegaralariga moslab o'qish.
/// AlQuran Cloud oyatlarning sahifa raqamini beradi. Faqat ochilgan sura
/// yuklangani uchun suraning boshidagi yoki oxiridagi sahifa qo'shni sura
/// oyatlarini o'z ichiga olmaydi.
class BookReaderScreen extends StatelessWidget {
  final int surahNumber;
  const BookReaderScreen({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          QuranReaderCubit(repository: context.read<QuranRepository>())
            ..loadSurah(surahNumber),
      child: const _BookReaderView(),
    );
  }
}

class _BookReaderView extends StatelessWidget {
  const _BookReaderView();

  static const int _fallbackAyahsPerPage = 6;

  static List<_BookPageContent> _groupAyahs(List<Ayah> ayahs) {
    if (ayahs.isNotEmpty && ayahs.every((a) => a.mushafPageNumber != null)) {
      final pages = <_BookPageContent>[];
      var currentPageNumber = ayahs.first.mushafPageNumber;
      var currentAyahs = <Ayah>[];
      for (final ayah in ayahs) {
        if (currentAyahs.isNotEmpty &&
            ayah.mushafPageNumber != currentPageNumber) {
          pages.add(_BookPageContent(
              ayahs: currentAyahs, mushafPageNumber: currentPageNumber));
          currentAyahs = <Ayah>[];
          currentPageNumber = ayah.mushafPageNumber;
        }
        currentAyahs.add(ayah);
      }
      if (currentAyahs.isNotEmpty) {
        pages.add(_BookPageContent(
            ayahs: currentAyahs, mushafPageNumber: currentPageNumber));
      }
      return pages;
    }

    return [
      for (var i = 0; i < ayahs.length; i += _fallbackAyahsPerPage)
        _BookPageContent(
          ayahs: ayahs.sublist(
            i,
            i + _fallbackAyahsPerPage > ayahs.length
                ? ayahs.length
                : i + _fallbackAyahsPerPage,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: BlocBuilder<QuranReaderCubit, QuranReaderState>(
          builder: (context, state) {
            if (state is QuranReaderLoading) {
              return const Pulse(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 72, 14, 40),
                  child: SkeletonCard(height: double.infinity, radius: 12),
                ),
              );
            }
            if (state is QuranReaderError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 48, color: palette.textLow),
                      const SizedBox(height: 14),
                      Text(state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.textMid)),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child:
                            Icon(Icons.close_rounded, color: palette.textMid),
                      ),
                    ],
                  ),
                ),
              );
            }

            final surah = (state as QuranReaderLoaded).surah;
            final pages = _groupAyahs(surah.ayahs);
            if (pages.isEmpty) pages.add(const _BookPageContent(ayahs: []));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      Material(
                        color: palette.accentGold.withValues(alpha: 0.12),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.close_rounded,
                                size: 20, color: palette.accentGold),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              surah.englishName,
                              textAlign: TextAlign.center,
                              style: AppTheme.display(
                                  size: 15, color: palette.textHi),
                            ),
                            Text(
                              l10n.get('book_mode'),
                              style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1,
                                  color: palette.accentGold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: BookPager(
                      key: ValueKey(surah.number),
                      title: surah.arabicName,
                      pages: [
                        for (var i = 0; i < pages.length; i++)
                          _MushafPage(
                            surahArabicName: surah.arabicName,
                            surahEnglishName: surah.englishName,
                            showHeader: i == 0,
                            ayahs: pages[i].ayahs,
                            mushafPageNumber: pages[i].mushafPageNumber,
                            pageIndex: i + 1,
                            totalPages: pages.length,
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe_rounded,
                          size: 14, color: palette.textLow),
                      const SizedBox(width: 6),
                      Text(
                        l10n.get('book_swipe_hint'),
                        style: TextStyle(color: palette.textLow, fontSize: 11),
                      ),
                    ],
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

class _BookPageContent {
  final List<Ayah> ayahs;
  final int? mushafPageNumber;

  const _BookPageContent({required this.ayahs, this.mushafPageNumber});
}

class _MushafPage extends StatelessWidget {
  final String surahArabicName;
  final String surahEnglishName;
  final bool showHeader;
  final List<Ayah> ayahs;
  final int? mushafPageNumber;
  final int pageIndex;
  final int totalPages;

  const _MushafPage({
    required this.surahArabicName,
    required this.surahEnglishName,
    required this.showHeader,
    required this.ayahs,
    required this.mushafPageNumber,
    required this.pageIndex,
    required this.totalPages,
  });

  static const _inkColor = Color(0xFF4A3B1E);
  static const _goldLine = Color(0xFFB08D3E);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF6E8), Color(0xFFF1E7C8)],
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: _goldLine, width: 1.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            border: Border.all(color: _goldLine.withValues(alpha: 0.55)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const RadialGradient(
                    colors: [Colors.transparent, Colors.white],
                    radius: 1.0,
                  ).createShader(rect),
                  child: IslamicPattern(
                    color: _goldLine.withValues(alpha: 0.07),
                    cell: 44,
                  ),
                ),
              ),
              Column(
                children: [
                  if (showHeader) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _goldLine.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: _goldLine.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Text(surahArabicName,
                              style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 28,
                                  color: _inkColor,
                                  fontWeight: FontWeight.bold)),
                          Text(surahEnglishName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _goldLine,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                for (final a in ayahs) ...[
                                  TextSpan(
                                    text: '${a.arabicText} ',
                                    style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 22,
                                        color: _inkColor,
                                        height: 2.2),
                                  ),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: _AyahMarker(number: a.numberInSurah),
                                  ),
                                  const TextSpan(text: '   '),
                                ],
                              ],
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: _goldLine),
                          for (final ayah in ayahs)
                            AyahReading(
                              text: ayah.transliteration == null
                                  ? null
                                  : '${ayah.numberInSurah}. ${ayah.transliteration}',
                              color: _inkColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                      mushafPageNumber == null
                          ? '$pageIndex / $totalPages'
                          : l10n
                              .get('mushaf_page')
                              .replaceAll('{m}', '$mushafPageNumber')
                              .replaceAll('{i}', '$pageIndex')
                              .replaceAll('{t}', '$totalPages'),
                      style: TextStyle(
                          fontSize: 10.5,
                          color: _goldLine.withValues(alpha: 0.9))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AyahMarker extends StatelessWidget {
  final int number;
  const _AyahMarker({required this.number});

  @override
  Widget build(BuildContext context) {
    return StarBadge(
      size: 28,
      color: const Color(0xFFB08D3E),
      child: Text(
        '$number',
        style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B4E1E)),
      ),
    );
  }
}
