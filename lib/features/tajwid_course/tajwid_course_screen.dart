import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/db/app_database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/hero_banner.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/ornaments.dart';
import '../../core/widgets/screen_header.dart';

/// Bitta tajvid qoidasi: kategoriya, qisqa va batafsil izoh, arabcha misollar.
class _TajwidRule {
  final String title;
  final String category;
  final String summary;
  final String detail;
  final List<_Example> examples;

  const _TajwidRule({
    required this.title,
    required this.category,
    required this.summary,
    required this.detail,
    this.examples = const [],
  });
}

class _Example {
  final String arabic;
  final String note;
  const _Example(this.arabic, this.note);
}

const List<_TajwidRule> _rules = [
  _TajwidRule(
    title: 'Izhor (aniq o\'qish)',
    category: 'Nun saakinah va tanvin',
    summary:
        'Nun saakinah yoki tanvindan keyin halq harflari kelsa, nun aniq talaffuz qilinadi.',
    detail:
        'Izhor — "aniq, ravshan qilish" degani. Nun saakinah (sakinali nun) yoki tanvin ortidan oltita halq harflaridan biri (ء ه ع ح غ خ) kelsa, nun g\'unna (burun tovushi) siz, aniq va qisqa o\'qiladi. Bu harflar "Izhor harflari" deyiladi.',
    examples: [
      _Example('مِنْ خَوْفٍ', 'min khawf — ن dan keyin خ'),
      _Example('يَنْهَى', 'yanhaa — ن dan keyin ه'),
      _Example('مِنْ عِلْمٍ', "min 'ilm — ن dan keyin ع"),
    ],
  ),
  _TajwidRule(
    title: 'Idg\'om (qo\'shib o\'qish)',
    category: 'Nun saakinah va tanvin',
    summary:
        'Nun saakinah/tanvin ye, nun, mim, vov, lam yoki ro harflariga qo\'shilib o\'qiladi.',
    detail:
        "Idg'om — \"bir harfni ikkinchisiga qo'shib o'qish\". Nun saakinah yoki tanvin (ي ن م و) harflaridan biri bilan kelsa, g'unna bilan (Idg'om bi-g'unna), (ل ر) bilan kelsa g'unnasiz (Idg'om bila-g'unna) o'qiladi. Bu harflar bir joyga to'plangan: يرملون.",
    examples: [
      _Example('مَنْ يَقُولُ', "man yaquul — g'unna bilan"),
      _Example('مِنْ وَلِيٍّ', "min waliyy — g'unna bilan"),
      _Example('مِنْ رَبِّهِمْ', "mir-rabbihim — g'unnasiz (ر)"),
      _Example('مِنْ لَدُنْهُ', 'mil-ladunhu — g\'unnasiz (ل)'),
    ],
  ),
  _TajwidRule(
    title: 'Iqlab (almashtirish)',
    category: 'Nun saakinah va tanvin',
    summary:
        'Nun saakinah/tanvin dan keyin "ba" (ب) kelsa, nun "mim" tovushiga aylanadi.',
    detail:
        'Iqlab — "o\'zgartirish, almashtirish" degani. Nun saakinah yoki tanvin ortidan faqat ب (ba) harfi kelsa, nun mim tovushiga aylantirilib, ikki lab biroz yopiq holda g\'unna bilan o\'qiladi.',
    examples: [
      _Example('مِنْ بَعْدِ', 'mim ba\'di — ن → م'),
      _Example('سَمِيعٌ بَصِيرٌ', 'sami\'um basiir — tanvin + ب'),
    ],
  ),
  _TajwidRule(
    title: 'Ikhfa (yashirin o\'qish)',
    category: 'Nun saakinah va tanvin',
    summary:
        'Nun saakinah/tanvin qolgan 15 harf oldida yashirin (g\'unna bilan) o\'qiladi.',
    detail:
        "Ikhfa — \"yashirish\" degani. Nun saakinah yoki tanvin Izhor, Idg'om va Iqlab harflaridan boshqa 15 ta harf oldida kelsa, na aniq, na to'liq qo'shib — o'rtacha, g'unna bilan o'qiladi. Bu eng ko'p uchraydigan hukmdir.",
    examples: [
      _Example('مِنْ قَبْلُ', 'min qablu — ن dan keyin ق'),
      _Example('مَنْصُورًا', 'mansuuran — ن dan keyin ص'),
      _Example('أَنْتَ', 'anta — ن dan keyin ت'),
    ],
  ),
  _TajwidRule(
    title: 'Ikhfa Shafawi (lab ikhfa)',
    category: 'Mim saakinah',
    summary:
        'Mim saakinah dan keyin "ba" (ب) kelsa, mim yashirin g\'unna bilan o\'qiladi.',
    detail:
        "Mim saakinah (sakinali mim) ortidan ب harfi kelsa, mim ikhfa qilinadi — lablar biroz yopiq, g'unna bilan. Bu \"Ikhfa Shafawi\" deyiladi.",
    examples: [
      _Example('تَرْمِيهِمْ بِحِجَارَةٍ', 'tarmiihim bi-hijaarah'),
      _Example('وَهُمْ بِالْآخِرَةِ', 'wa-hum bil-aakhirah'),
    ],
  ),
  _TajwidRule(
    title: 'Idg\'om Shafawi (lab idg\'omi)',
    category: 'Mim saakinah',
    summary:
        'Mim saakinah dan keyin yana bir mim kelsa, ikkinchiga qo\'shilib g\'unna bilan o\'qiladi.',
    detail:
        'Mim saakinah ortidan yana bir mim kelsa, birinchi mim ikkinchisiga qo\'shilib, g\'unna bilan cho\'ziqroq o\'qiladi. Bu "Idg\'om Shafawi" yoki "Idg\'om Mimi" deyiladi.',
    examples: [
      _Example('لَهُمْ مَا يَشَاءُونَ', 'lahum maa yashaa\'uun'),
      _Example('هُمْ مُؤْمِنُونَ', 'hum mu\'minuun'),
    ],
  ),
  _TajwidRule(
    title: 'Izhor Shafawi (lab izhori)',
    category: 'Mim saakinah',
    summary:
        'Mim saakinah "ba" va "mim" dan boshqa harflar oldida aniq o\'qiladi.',
    detail:
        "Mim saakinah ortidan ب va م dan boshqa istalgan harf kelsa, mim aniq va qisqa o'qiladi. Ayniqsa (و) va (ف) harflarida ehtiyot bo'lish kerak — labni to'liq yopmaslik lozim.",
    examples: [
      _Example('هُمْ فِيهَا', 'hum fiihaa — م dan keyin ف'),
      _Example('أَلَمْ تَرَ', 'alam tara — م dan keyin ت'),
    ],
  ),
  _TajwidRule(
    title: 'Madd Tabii\'iy (tabiiy cho\'zish)',
    category: 'Madd qoidalari',
    summary: 'Tabiiy cho\'ziq unlilar 2 harakat (harf) miqdorida cho\'ziladi.',
    detail:
        "Madd — \"cho'zish\" degani. Alif (ا), vov (و) va ye (ي) tabiiy madd harflaridir. Ulardan oldin mos harakat bo'lsa, 2 harakat miqdorida cho'ziladi. Bu asosiy, majburiy cho'zishdir.",
    examples: [
      _Example('قَالَ', 'qaala — alif 2 harakat'),
      _Example('يَقُولُ', 'yaquulu — vov 2 harakat'),
      _Example('قِيلَ', 'qiila — ye 2 harakat'),
    ],
  ),
  _TajwidRule(
    title: 'Madd Voajib Muttasil',
    category: 'Madd qoidalari',
    summary:
        'Madd harfi va hamza bir so\'zda bo\'lsa, 4-5 harakat cho\'ziladi.',
    detail:
        'Madd harfi va hamza (ء) bir so\'z ichida ketma-ket kelsa, bu "Madd Voajib Muttasil" bo\'lib, 4 yoki 5 harakat miqdorida cho\'ziladi. Masalan, "samo", "ja\'a".',
    examples: [
      _Example('السَّمَاءِ', 'as-samaa\'i — 4-5 harakat'),
      _Example('جَاءَ', 'jaa\'a — 4-5 harakat'),
    ],
  ),
  _TajwidRule(
    title: 'Madd Laazim (majburiy cho\'zish)',
    category: 'Madd qoidalari',
    summary:
        'Madd harfidan keyin sakin yoki shadda kelsa, 6 harakat cho\'ziladi.',
    detail:
        "Madd harfidan keyin bir so'z ichida sakin (sukun) yoki shadda kelsa, \"Madd Laazim\" bo'lib, 6 harakat miqdorida cho'ziladi. Bu eng uzun cho'zishdir.",
    examples: [
      _Example('الضَّالِّينَ', 'ad-daalliin — 6 harakat'),
      _Example('الْحَاقَّةُ', 'al-haaqqah — 6 harakat'),
    ],
  ),
  _TajwidRule(
    title: 'Qalqala (tebranish)',
    category: 'Boshqa qoidalar',
    summary:
        'Qof, to, ba, jim, dal harflari saakin holatda tebranish bilan o\'qiladi.',
    detail:
        "Qalqala — \"tebranish, silkinish\" degani. (ق ط ب ج د) harflari saakin (sukunli) holatda kelganda, tovushga yengil tebranish (aks-sado) beriladi. Bu beshta harf \"قطب جد\" iborasida jamlangan. Kuchlilik darajasiga ko'ra qalqala kubro (to'xtashda) va sug'ro (so'z o'rtasida) bo'ladi.",
    examples: [
      _Example('خَلَقَ', 'khalaqa — so\'z o\'rtasida (sug\'ro)'),
      _Example('الْفَلَقْ', 'al-falaq — to\'xtashda (kubro)'),
      _Example('أَحَدٌ', 'ahad — dal bilan'),
    ],
  ),
  _TajwidRule(
    title: 'G\'unna (burun tovushi)',
    category: 'Boshqa qoidalar',
    summary: 'Shaddali nun (نّ) va mim (مّ) 2 harakat g\'unna bilan o\'qiladi.',
    detail:
        "G'unna — burun bo'shlig'idan chiqadigan yoqimli tovush. Shaddali nun (نّ) va shaddali mim (مّ) 2 harakat miqdorida g'unna bilan cho'zilib o'qiladi.",
    examples: [
      _Example('إِنَّ', 'inna — shaddali nun'),
      _Example('ثُمَّ', 'thumma — shaddali mim'),
    ],
  ),
  _TajwidRule(
    title: 'Lam Ta\'rifi (Shamsiya va Qamariya)',
    category: 'Boshqa qoidalar',
    summary:
        '"Al-" (ال) artiklidagi lam quyosh harflarida o\'qilmaydi, oy harflarida o\'qiladi.',
    detail:
        "So'z boshidagi (ال) artiklidagi lam: quyosh harflari (harakatlanmaydigan 14 harf) oldida o'qilmaydi va keyingi harf shaddalanadi (Lam Shamsiya). Oy harflari oldida esa lam aniq o'qiladi (Lam Qamariya).",
    examples: [
      _Example('الشَّمْسُ', 'ash-shams — lam o\'qilmaydi (Shamsiya)'),
      _Example('الرَّحْمَنُ', 'ar-rahmaan — lam o\'qilmaydi (Shamsiya)'),
      _Example('الْقَمَرُ', 'al-qamar — lam o\'qiladi (Qamariya)'),
    ],
  ),
];

const List<Color> _categoryColors = [
  Color(0xFF1E9E7F),
  Color(0xFF3B82C4),
  Color(0xFFC9962F),
  Color(0xFF7B63C7),
];

Color _colorFor(String category) {
  final index =
      _rules.map((r) => r.category).toSet().toList().indexOf(category);
  return _categoryColors[(index < 0 ? 0 : index) % _categoryColors.length];
}

class TajwidCourseScreen extends StatelessWidget {
  const TajwidCourseScreen({super.key});

  List<String> get _categories =>
      _rules.map((r) => r.category).toSet().toList();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final categories = _categories;
    var number = 0;
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l10n.get('tajwid_title')),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: FadeSlideIn(
                          child: HeroBanner(
                            kicker: l10n.get('tajwid_hero_kicker'),
                            title: l10n
                                .get('tajwid_rules_n')
                                .replaceAll('{n}', '${_rules.length}'),
                            subtitle: l10n.get('tajwid_hero_sub'),
                            trailing: PaddedShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (b) =>
                                  AppColors.goldGradient.createShader(b),
                              child: Text('تجويد',
                                  style: AppTheme.arabic(
                                      size: 36, color: Colors.white)),
                            ),
                          ),
                        ),
                      );
                    }
                    final category = categories[i - 1];
                    final color = _colorFor(category);
                    final items =
                        _rules.where((r) => r.category == category).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (i > 1) const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.toUpperCase(),
                                  style: TextStyle(
                                    color: palette.accentGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...items.map((rule) {
                          number++;
                          return _RuleCard(
                              rule: rule, number: number, color: color);
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final _TajwidRule rule;
  final int number;
  final Color color;
  const _RuleCard(
      {required this.rule, required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.all(16),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => _RuleDetailScreen(rule: rule, color: color)),
          );
        },
        child: Row(
          children: [
            StarBadge(
              size: 46,
              color: color,
              child: Text('$number',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.title,
                      style: TextStyle(
                          color: palette.textHi,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(rule.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: palette.textMid, fontSize: 12.5, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: palette.textLow, size: 22),
          ],
        ),
      ),
    );
  }
}

class _RuleDetailScreen extends StatefulWidget {
  final _TajwidRule rule;
  final Color color;
  const _RuleDetailScreen({required this.rule, required this.color});

  @override
  State<_RuleDetailScreen> createState() => _RuleDetailScreenState();
}

class _RuleDetailScreenState extends State<_RuleDetailScreen> {
  _TajwidRule get rule => widget.rule;

  @override
  void initState() {
    super.initState();
    // Qoidani o'qish dars sifatida hisoblanadi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<AppDatabase>()
          .updateLessonProgress('tajwid_rule_${rule.title}', 1.0, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final color = widget.color;
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: rule.title),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassChip(label: rule.category, color: color),
                      const SizedBox(height: 16),
                      GlassCard(
                        radius: 22,
                        padding: const EdgeInsets.all(18),
                        child: Text(rule.detail,
                            style: TextStyle(
                                color: palette.textHi,
                                fontSize: 15,
                                height: 1.7)),
                      ),
                      if (rule.examples.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        Text(l10n.get('tajwid_examples'),
                            style: TextStyle(
                                color: palette.accentGold,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        for (var i = 0; i < rule.examples.length; i++)
                          FadeSlideIn(
                            delay: Duration(milliseconds: 70 * i),
                            offset: 10,
                            child: _ExampleCard(
                                example: rule.examples[i], color: color),
                          ),
                      ],
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

class _ExampleCard extends StatelessWidget {
  final _Example example;
  final Color color;
  const _ExampleCard({required this.example, required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(example.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTheme.arabic(size: 28, color: palette.textHi)
                  .copyWith(height: 1.8)),
          const SizedBox(height: 8),
          Text(example.note,
              style: TextStyle(color: palette.textMid, fontSize: 12.5)),
        ],
      ),
    );
  }
}
