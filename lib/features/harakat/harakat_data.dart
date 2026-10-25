/// Arab harakatlari (unli belgilar) — standart, umumiy tan olingan
/// tizim. Bu yerdagi nomlar va tovush tavsiflari o'zbek tajvid
/// darsliklarida keng qo'llaniladigan atamalar; baribir ilova relizidan
/// oldin tanlagan darslik/qori bilan bir marta solishtirib chiqish
/// tavsiya etiladi (ayrim darsliklar "ustun/zer/pesh" o'rniga to'g'ridan
/// -to'g'ri arabcha "fatha/kasra/damma" atamalarini ishlatadi).
class HarakatInfo {
  final String mark; // Unicode combining diacritic
  final String name;
  final String altName;
  final String sound;

  const HarakatInfo({
    required this.mark,
    required this.name,
    required this.altName,
    required this.sound,
  });

  /// Namuna harf bilan birlashtirilgan ko'rinishi (masalan "بَ").
  String withSample(String baseLetter) => '$baseLetter$mark';
}

const List<HarakatInfo> kHarakatList = [
  HarakatInfo(
      mark: '\u064E',
      name: 'Fatha',
      altName: 'Ustun',
      sound: "Qisqa 'a' tovushi"),
  HarakatInfo(
      mark: '\u0650',
      name: 'Kasra',
      altName: 'Zer',
      sound: "Qisqa 'i' tovushi"),
  HarakatInfo(
      mark: '\u064F',
      name: 'Damma',
      altName: 'Pesh',
      sound: "Qisqa 'u' tovushi"),
  HarakatInfo(
      mark: '\u0652',
      name: 'Sukun',
      altName: 'Jazm',
      sound: "Unlisiz — harf to'xtab o'qiladi"),
  HarakatInfo(
      mark: '\u0651',
      name: 'Shadda',
      altName: 'Tashdid',
      sound: 'Harfni ikkilantirib, qattiqroq talaffuz qilish'),
  HarakatInfo(
      mark: '\u064B',
      name: 'Tanvin fatha',
      altName: 'Do\'l fatha',
      sound: "So'z oxirida '-an' tovushi"),
  HarakatInfo(
      mark: '\u064D',
      name: 'Tanvin kasra',
      altName: 'Do\'l kasra',
      sound: "So'z oxirida '-in' tovushi"),
  HarakatInfo(
      mark: '\u064C',
      name: 'Tanvin damma',
      altName: 'Do\'l damma',
      sound: "So'z oxirida '-un' tovushi"),
];

/// Bo'g'in mashqi va so'z o'qish uchun asosiy 3 unli — fatha/kasra/damma
/// bilan sodda bo'g'inlar hosil qilishda ishlatiladi.
const List<HarakatInfo> kBasicVowels = [
  HarakatInfo(mark: '\u064E', name: 'Fatha', altName: 'Ustun', sound: 'a'),
  HarakatInfo(mark: '\u0650', name: 'Kasra', altName: 'Zer', sound: 'i'),
  HarakatInfo(mark: '\u064F', name: 'Damma', altName: 'Pesh', sound: 'u'),
];
