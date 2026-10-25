import 'package:flutter_test/flutter_test.dart';
import 'package:tajvid_yoli/core/utils/user_level.dart';

void main() {
  group('UserLevel', () {
    test('returns correct title for XP thresholds', () {
      expect(UserLevel.titleForXp(0), 'Boshlang\'ich');
      expect(UserLevel.titleForXp(99), 'Boshlang\'ich');
      expect(UserLevel.titleForXp(100), 'Tolib darajasi');
      expect(UserLevel.titleForXp(599), "O'rta daraja");
      expect(UserLevel.titleForXp(600), 'Yuqori daraja');
    });

    test('builds initials from name', () {
      expect(UserLevel.initialsForName('Aziz Karimov'), 'AK');
      expect(UserLevel.initialsForName('Mehmon'), 'M');
      expect(UserLevel.initialsForName(''), '?');
    });
  });
}
