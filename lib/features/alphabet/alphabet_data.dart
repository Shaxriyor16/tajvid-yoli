/// Arab alifbosi — 28 harf, standart tartibda.
///
/// Harflarning o'zi va tartibi umumiy tilshunoslik fakti (bahsli emas).
/// `articulationGroup` maydoni esa SODDALASHTIRILGAN guruhlash — klassik
/// tajvid ilmida maxraj nuqtalari 17 ta aniq o'ringa (Jawf, Halq, Lisan,
/// Shafatan, Khayshum ostida) bo'linadi. Bu yerdagi bir so'zli guruhlar
/// faqat UI uchun (masalan filtr/belgi sifatida) — darslik matniga
/// aylantirishdan oldin buni "Tuhfat al-Atfal" yoki jamoangiz tanlagan
/// boshqa manba bilan qori/ustoz tekshiruvidan o'tkazing (hujjatingizdagi
/// §3 va Content QA talabiga muvofiq).
///
/// `connectsForward` — bu harf o'zidan keyingi harfga yozuvda ulanadimi
/// (ya'ni to'liq 4 shaklga — yakka/boshida/o'rtada/oxirida — egami).
/// 6 ta harf (ا د ذ ر ز و) faqat OLDINGI harfga ulanadi, keyingisiga
/// hech qachon ulanmaydi — bu arab imlosining standart, bahssiz qoidasi.
class ArabicLetter {
  final String letter;
  final String uzbekName;
  final String articulationGroup;
  final bool connectsForward;

  const ArabicLetter({
    required this.letter,
    required this.uzbekName,
    required this.articulationGroup,
    this.connectsForward = true,
  });

  /// Yakka holat — harfning o'zi.
  String get isolatedForm => letter;

  /// So'z boshida (keyingisiga ulanadigan bo'lsa, tatvil chizig'i bilan
  /// ko'rsatiladi — bu Arab yozuv darsliklarida ulanish yo'nalishini
  /// ko'rsatish uchun ishlatiladigan standart usul).
  String get initialForm => connectsForward ? '$letter\u0640' : letter;

  /// So'z o'rtasida.
  String get medialForm =>
      connectsForward ? '\u0640$letter\u0640' : '\u0640$letter';

  /// So'z oxirida.
  String get finalForm => '\u0640$letter';
}

const List<ArabicLetter> kArabicAlphabet = [
  ArabicLetter(
      letter: 'ا',
      uzbekName: 'Alif',
      articulationGroup: 'Tomoq',
      connectsForward: false),
  ArabicLetter(letter: 'ب', uzbekName: 'Bo', articulationGroup: 'Lab'),
  ArabicLetter(letter: 'ت', uzbekName: 'To', articulationGroup: 'Til uchi'),
  ArabicLetter(letter: 'ث', uzbekName: 'So', articulationGroup: 'Til uchi'),
  ArabicLetter(letter: 'ج', uzbekName: 'Jim', articulationGroup: "O'rta til"),
  ArabicLetter(
      letter: 'ح', uzbekName: 'Ha (og\'ir)', articulationGroup: 'Tomoq'),
  ArabicLetter(letter: 'خ', uzbekName: 'Xo', articulationGroup: 'Tomoq'),
  ArabicLetter(
      letter: 'د',
      uzbekName: 'Dol',
      articulationGroup: 'Til uchi',
      connectsForward: false),
  ArabicLetter(
      letter: 'ذ',
      uzbekName: 'Zol',
      articulationGroup: 'Til uchi',
      connectsForward: false),
  ArabicLetter(
      letter: 'ر',
      uzbekName: 'Ro',
      articulationGroup: 'Til uchi',
      connectsForward: false),
  ArabicLetter(
      letter: 'ز',
      uzbekName: 'Zay',
      articulationGroup: 'Til uchi',
      connectsForward: false),
  ArabicLetter(letter: 'س', uzbekName: 'Sin', articulationGroup: 'Til uchi'),
  ArabicLetter(letter: 'ش', uzbekName: 'Shin', articulationGroup: "O'rta til"),
  ArabicLetter(letter: 'ص', uzbekName: 'Sod', articulationGroup: 'Til uchi'),
  ArabicLetter(
      letter: 'ض', uzbekName: 'Dod', articulationGroup: 'Til yon tomoni'),
  ArabicLetter(
      letter: 'ط', uzbekName: "To' (qalin)", articulationGroup: 'Til uchi'),
  ArabicLetter(
      letter: 'ظ', uzbekName: "Zo' (qalin)", articulationGroup: 'Til uchi'),
  ArabicLetter(letter: 'ع', uzbekName: 'Ayn', articulationGroup: 'Tomoq'),
  ArabicLetter(letter: 'غ', uzbekName: "G'ayn", articulationGroup: 'Tomoq'),
  ArabicLetter(letter: 'ف', uzbekName: 'Fo', articulationGroup: 'Lab'),
  ArabicLetter(letter: 'ق', uzbekName: 'Qof', articulationGroup: 'Til orqasi'),
  ArabicLetter(letter: 'ك', uzbekName: 'Kof', articulationGroup: 'Til orqasi'),
  ArabicLetter(letter: 'ل', uzbekName: 'Lom', articulationGroup: 'Til uchi'),
  ArabicLetter(letter: 'م', uzbekName: 'Mim', articulationGroup: 'Lab'),
  ArabicLetter(letter: 'ن', uzbekName: 'Nun', articulationGroup: 'Til uchi'),
  ArabicLetter(
      letter: 'ه', uzbekName: 'Ha (yengil)', articulationGroup: 'Tomoq'),
  ArabicLetter(
      letter: 'و',
      uzbekName: 'Vov',
      articulationGroup: 'Lab',
      connectsForward: false),
  ArabicLetter(letter: 'ي', uzbekName: 'Yo', articulationGroup: "O'rta til"),
];
