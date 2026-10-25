import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tajvid_yoli/core/utils/input_validators.dart';
import 'package:tajvid_yoli/core/utils/login_throttle.dart';

void main() {
  group('password policy', () {
    test('rejects short, letter-only, digit-only and common passwords', () {
      expect(InputValidators.isValidPassword('abc123'), isFalse); // qisqa
      expect(InputValidators.isValidPassword('abcdefgh'), isFalse); // raqamsiz
      expect(InputValidators.isValidPassword('12345678'), isFalse); // harfsiz
      expect(InputValidators.isValidPassword('Password1'), isFalse); // keng tarqalgan
      expect(InputValidators.isValidPassword('QWERTY123'), isFalse);
    });
    test('accepts a reasonable password', () {
      expect(InputValidators.isValidPassword('tajvid-2026-ok'), isTrue);
      expect(InputValidators.isValidPassword('Yo1liTajvid'), isTrue);
    });
  });

  group('login throttle', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('lock durations grow exponentially and cap at 15 minutes', () {
      expect(LoginThrottle.lockFor(4), Duration.zero);
      expect(LoginThrottle.lockFor(5), const Duration(seconds: 30));
      expect(LoginThrottle.lockFor(6), const Duration(seconds: 60));
      expect(LoginThrottle.lockFor(7), const Duration(seconds: 120));
      expect(LoginThrottle.lockFor(50), const Duration(minutes: 15));
    });

    test('five failures lock sign-in, success resets', () async {
      final t0 = DateTime(2026, 10, 25, 12);
      for (var i = 0; i < 4; i++) {
        await LoginThrottle.recordFailure(now: t0);
      }
      expect(await LoginThrottle.remaining(now: t0), Duration.zero);
      await LoginThrottle.recordFailure(now: t0);
      final wait = await LoginThrottle.remaining(now: t0);
      expect(wait, const Duration(seconds: 30));
      // vaqt o'tgach blok tugaydi
      expect(
          await LoginThrottle.remaining(
              now: t0.add(const Duration(seconds: 31))),
          Duration.zero);
      await LoginThrottle.reset();
      expect(await LoginThrottle.remaining(now: t0), Duration.zero);
      await LoginThrottle.recordFailure(now: t0); // hisob noldan boshlanadi
      expect(await LoginThrottle.remaining(now: t0), Duration.zero);
    });
  });
}
