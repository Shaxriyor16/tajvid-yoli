import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:tajvid_yoli/core/db/app_database.dart';
import 'package:go_router/go_router.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/core/services/audio_player_service.dart';
import 'package:tajvid_yoli/core/l10n/app_localizations.dart';
import 'package:tajvid_yoli/core/services/quran_service.dart';
import 'package:tajvid_yoli/core/widgets/glass_widgets.dart';
import 'package:tajvid_yoli/core/widgets/islamic_pattern.dart';
import 'package:tajvid_yoli/core/widgets/motion.dart';
import 'package:tajvid_yoli/core/widgets/ornaments.dart';
import 'package:tajvid_yoli/core/widgets/screen_header.dart';
import 'ayah_reading.dart';

class QuranReaderScreen extends StatefulWidget {
  final QuranService? quranService;
  final int surahNumber;
  final int? ayahNumber;

  const QuranReaderScreen(
      {super.key,
      required this.surahNumber,
      this.ayahNumber,
      this.quranService});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late final QuranService _quranService;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  late Future<Surah> _surahFuture;
  Surah? _loadedSurah;
  int? _targetAyah;

  @override
  void initState() {
    super.initState();
    _quranService = widget.quranService ?? QuranService();
    _targetAyah = widget.ayahNumber;
    _surahFuture = _quranService.getSurah(widget.surahNumber);
  }

  @override
  void didUpdateWidget(QuranReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) {
      _loadedSurah = null;
      _ayahKeys.clear();
      _surahFuture = _quranService.getSurah(widget.surahNumber);
    }
    if (widget.ayahNumber != null &&
        widget.ayahNumber != oldWidget.ayahNumber) {
      _targetAyah = widget.ayahNumber;
      if (_loadedSurah != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _consumeTargetAyah();
        });
      }
    }
  }

  void _showGoToAyahDialog() {
    showDialog(
      context: context,
      builder: (context) => _GoToAyahDialog(
        currentSurahNumber: widget.surahNumber,
        maxAyahInCurrentSurah: _loadedSurah?.ayahs.length,
        onGo: (surah, ayah) {
          if (surah == widget.surahNumber) {
            if (ayah != null) {
              _targetAyah = ayah;
              _consumeTargetAyah();
            }
          } else {
            context.go('/quran/$surah${ayah != null ? '?ayah=$ayah' : ''}');
          }
        },
      ),
    );
  }

  /// Yuklangan surada maqsad oyat bo'lsa, o'sha joyga silliq scroll qiladi.
  void _consumeTargetAyah() {
    final target = _targetAyah;
    if (target == null || _loadedSurah == null) return;
    _targetAyah = null;

    final surah = _loadedSurah!;
    final index = surah.ayahs.indexWhere((a) => a.numberInSurah == target);
    if (index < 0) return;

    final key = _ayahKeys.putIfAbsent(target, () => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.12,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final audioPlayerService = context.read<AudioPlayerService>();
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: FutureBuilder<Surah>(
            future: _surahFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Pulse(
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 96, 16, 0),
                    children: const [
                      SkeletonCard(height: 150, radius: 26),
                      SizedBox(height: 16),
                      SkeletonCard(height: 190, radius: 22),
                      SizedBox(height: 14),
                      SkeletonCard(height: 190, radius: 22),
                    ],
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                final l10n = AppLocalizations.of(context);
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.wifi_slash,
                            color: palette.textLow, size: 54),
                        const SizedBox(height: 16),
                        Text(
                          l10n.get('quran_load_error'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.textMid),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 220,
                          child: GradientButton(
                            label: l10n.get('reader_retry'),
                            onTap: () => setState(() => _surahFuture =
                                _quranService.getSurah(widget.surahNumber)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final surah = snapshot.data!;
              if (!identical(_loadedSurah, surah)) {
                _loadedSurah = surah;
                // Maqsad oyat bo'lsa, birinchi frame'dan keyin scroll qilamiz.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _consumeTargetAyah();
                });
              }

              return Column(
                children: [
                  ScreenHeader(
                    title:
                        '${AppLocalizations.of(context).get('quran')} · ${surah.number}',
                    actions: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.book, size: 20),
                        onPressed: () =>
                            context.push('/book/${widget.surahNumber}'),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.search, size: 20),
                        onPressed: _showGoToAyahDialog,
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      children: [
                        FadeSlideIn(child: _SurahBanner(surah: surah)),
                        for (final ayah in surah.ayahs)
                          _AyahTile(
                            key: _ayahKeys.putIfAbsent(
                                ayah.numberInSurah, () => GlobalKey()),
                            surahNumber: surah.number,
                            ayah: ayah,
                            audioPlayerService: audioPlayerService,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GoToAyahDialog extends StatefulWidget {
  final int currentSurahNumber;
  final int? maxAyahInCurrentSurah;
  final Function(int surah, int? ayah) onGo;

  const _GoToAyahDialog({
    required this.currentSurahNumber,
    required this.onGo,
    this.maxAyahInCurrentSurah,
  });

  @override
  State<_GoToAyahDialog> createState() => _GoToAyahDialogState();
}

class _GoToAyahDialogState extends State<_GoToAyahDialog> {
  late final TextEditingController _surahController;
  late final TextEditingController _ayahController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _surahController =
        TextEditingController(text: widget.currentSurahNumber.toString());
    _ayahController = TextEditingController();
  }

  @override
  void dispose() {
    _surahController.dispose();
    _ayahController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final surah = int.parse(_surahController.text);
      final ayah = _ayahController.text.isNotEmpty
          ? int.parse(_ayahController.text)
          : null;
      Navigator.of(context).pop();
      widget.onGo(surah, ayah);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: palette.sheetFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(l10n.get('goto_ayah'),
          style: TextStyle(color: palette.textHi, fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _surahController,
              style: TextStyle(color: palette.textHi),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(l10n.get('surah_number'), palette),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.get('enter_surah_number');
                }
                final num = int.tryParse(value);
                if (num == null || num < 1 || num > 114) {
                  return l10n.get('range_1_114');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ayahController,
              style: TextStyle(color: palette.textHi),
              keyboardType: TextInputType.number,
              decoration:
                  _inputDecoration(l10n.get('ayah_number_optional'), palette),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = int.tryParse(value);
                  if (num == null || num < 1) {
                    return l10n.get('enter_positive');
                  }
                  final surahNum = int.tryParse(_surahController.text);
                  if (surahNum == widget.currentSurahNumber &&
                      widget.maxAyahInCurrentSurah != null &&
                      num > widget.maxAyahInCurrentSurah!) {
                    return l10n
                        .get('surah_has_ayahs')
                        .replaceAll('{n}', '${widget.maxAyahInCurrentSurah}');
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.get('cancel'),
              style: TextStyle(color: palette.textMid)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.accentGold,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(l10n.get('goto_go')),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, AppPalette palette) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: palette.textLow),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.accentGold, width: 1.6),
      ),
    );
  }
}

class _AyahTile extends StatefulWidget {
  final int surahNumber;
  final Ayah ayah;
  final AudioPlayerService audioPlayerService;

  const _AyahTile({
    super.key,
    required this.surahNumber,
    required this.ayah,
    required this.audioPlayerService,
  });

  @override
  State<_AyahTile> createState() => _AyahTileState();
}

class _AyahTileState extends State<_AyahTile> {
  bool _isExpanded = false;
  bool _isBookmarked = false;
  bool _bookmarkBusy = false;

  @override
  void initState() {
    super.initState();
    // Vidjet qurilgandan so'ng xatcho'p holatini tekshirish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<AppDatabase>()
            .isBookmarked(widget.surahNumber, widget.ayah.numberInSurah)
            .then((value) {
          if (mounted) setState(() => _isBookmarked = value);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final surface = Theme.of(context).colorScheme.surface;
    return StreamBuilder<String?>(
      stream: widget.audioPlayerService.currentlyPlayingUrlStream,
      builder: (context, playing) {
        final active =
            widget.ayah.audio.isNotEmpty && playing.data == widget.ayah.audio;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: palette.cardShadow,
          ),
          child: Material(
            color: Color.alphaBlend(
                active
                    ? palette.accentGold.withValues(alpha: 0.08)
                    : palette.cardFill,
                surface),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: active ? palette.accentGold : palette.cardBorder,
                width: active ? 1.4 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Oyat raqami, audio tugmasi va xatcho'p
                    Row(
                      children: [
                        StarBadge(
                          size: 40,
                          child: Text(
                            '${widget.ayah.numberInSurah}',
                            style: TextStyle(
                              color: palette.accentGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _AudioPlayerButton(
                          audioUrl: widget.ayah.audio,
                          audioPlayerService: widget.audioPlayerService,
                        ),
                        const SizedBox(width: 8),
                        _buildBookmarkButton(palette),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Oyat matni
                    Text(
                      widget.ayah.text,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTheme.arabic(size: 28, color: palette.textHi)
                          .copyWith(height: 1.9),
                    ),
                    AyahReading(
                        text: widget.ayah.transliteration,
                        color: palette.textMid),
                    // Tarjima va tafsir uchun ochiladigan qism
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _isExpanded
                          ? _buildTranslationAndTafsir(palette)
                          : const SizedBox(width: double.infinity),
                    ),
                    Center(
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(CupertinoIcons.chevron_down,
                            size: 16, color: palette.textLow),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarkButton(AppPalette palette) {
    return _bookmarkBusy
        ? const _CircleAction(
            busy: true,
            icon: CupertinoIcons.bookmark,
            onTap: null,
          )
        : _CircleAction(
            active: _isBookmarked,
            icon: _isBookmarked
                ? CupertinoIcons.bookmark_fill
                : CupertinoIcons.bookmark,
            onTap: _toggleBookmark,
          );
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkBusy) return;
    HapticFeedback.lightImpact();
    setState(() => _bookmarkBusy = true);

    final db = context.read<AppDatabase>();
    try {
      if (_isBookmarked) {
        await db.removeBookmark(widget.surahNumber, widget.ayah.numberInSurah);
      } else {
        await db.addBookmark(widget.surahNumber, widget.ayah.numberInSurah);
      }
      if (mounted) {
        setState(() => _isBookmarked = !_isBookmarked);
      }
    } finally {
      if (mounted) {
        setState(() => _bookmarkBusy = false);
      }
    }
  }

  Widget _buildTranslationAndTafsir(AppPalette palette) {
    final translation = widget.ayah.translation;
    final tafsir = widget.ayah.tafsir;

    if (translation == null && tafsir == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.accentGold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.accentGold.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (translation != null)
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Text(
                  translation,
                  style: TextStyle(
                    color: palette.textMid,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
            if (tafsir != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).get('tafsir_label'),
                      style: TextStyle(
                        color: palette.accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tafsir,
                      style: TextStyle(
                        color: palette.textMid,
                        fontSize: 14,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayerButton extends StatelessWidget {
  // ... (bu vidjetda o'zgarish yo'q)
  final String audioUrl;
  final AudioPlayerService audioPlayerService;

  const _AudioPlayerButton({
    required this.audioUrl,
    required this.audioPlayerService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: audioPlayerService.currentlyPlayingUrlStream,
      builder: (context, currentlyPlayingSnapshot) {
        final isThisAyahPlaying = currentlyPlayingSnapshot.data == audioUrl;

        return StreamBuilder<PlayerState>(
          stream: audioPlayerService.playerStateStream,
          builder: (context, playerStateSnapshot) {
            final processingState = playerStateSnapshot.data?.processingState;
            final isPlaying = (playerStateSnapshot.data?.playing ?? false) &&
                processingState != ProcessingState.completed;

            IconData icon;
            if (isThisAyahPlaying) {
              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                return const _CircleAction(
                    busy: true, icon: CupertinoIcons.play_fill, onTap: null);
              } else if (isPlaying) {
                icon = CupertinoIcons.pause_fill;
              } else {
                // Tayyor, lekin pauzada
                icon = CupertinoIcons.play_fill;
              }
            } else {
              // Boshqa oyat ijro etilmoqda yoki hech nima ijro etilmayapti
              icon = CupertinoIcons.play_fill;
            }

            return _CircleAction(
              icon: icon,
              active: isThisAyahPlaying && isPlaying,
              onTap: () async {
                if (isThisAyahPlaying && isPlaying) {
                  audioPlayerService.pause();
                } else {
                  final played = await audioPlayerService.play(audioUrl);
                  if (!played && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.of(context)
                          .get('quran_audio_failed')),
                    ));
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Yumaloq, oltin rangli kichik amal tugmasi (audio, xatcho'p).
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final bool busy;

  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.accentGold.withValues(alpha: active ? 0.24 : 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: palette.accentGold),
                  )
                : Icon(icon, size: 18, color: palette.accentGold),
          ),
        ),
      ),
    );
  }
}

/// Sura boshidagi bezakli sarlavha: raqam, arabcha nom, oyatlar soni va
/// (9-sura va Fotihadan tashqari) Basmala.
class _SurahBanner extends StatelessWidget {
  final Surah surah;
  const _SurahBanner({required this.surah});

  static const _gold = Color(0xFFE8C77B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showBasmala = surah.number != 1 && surah.number != 9;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF16604F), Color(0xFF0F4A3D), Color(0xFF0A2E27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4A3D).withValues(alpha: 0.3),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const RadialGradient(
                  colors: [Colors.white, Colors.transparent],
                  radius: 0.9,
                ).createShader(rect),
                child: IslamicPattern(
                  color: _gold.withValues(alpha: 0.13),
                  cell: 48,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      l10n
                          .get('surah_kicker')
                          .replaceAll('{n}', '${surah.number}'),
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6),
                    ),
                    const SizedBox(height: 8),
                    PaddedShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          AppColors.goldGradient.createShader(bounds),
                      child: Text(surah.name,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style:
                              AppTheme.arabic(size: 36, color: Colors.white)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n
                          .get('ayahs_n')
                          .replaceAll('{n}', '${surah.ayahs.length}'),
                      style: const TextStyle(
                          color: Color(0xFFCCE1DA), fontSize: 13),
                    ),
                    if (showBasmala) ...[
                      const SizedBox(height: 14),
                      Container(
                          height: 1,
                          width: 70,
                          color: _gold.withValues(alpha: 0.4)),
                      const SizedBox(height: 14),
                      Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                          textDirection: TextDirection.rtl,
                          style: AppTheme.arabic(
                              size: 24,
                              color: Colors.white.withValues(alpha: 0.9))),
                    ],
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
