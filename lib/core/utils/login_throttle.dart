import 'package:shared_preferences/shared_preferences.dart';

/// Qurilma darajasidagi kirish urinishlarini cheklash (brute-force / credential stuffing).
///
/// Ketma-ket noto'g'ri urinishlardan keyin kirish vaqtincha bloklanadi, har safar
/// blok ikki baravar uzayadi (30 s -> 1 daq -> 2 -> 4 -> 8 -> 15 daq gacha).
/// Bu Firebase Auth'ning server tomonidagi cheklovini (too-many-requests) to'ldiradi,
/// o'rnini bosmaydi. Saqlash xatosi bo'lsa, kirishni to'smaydi (fail-open).
class LoginThrottle {
  static const _failuresKey = 'login_failures';
  static const _lockedUntilKey = 'login_locked_until_ms';
  static const freeAttempts = 5;
  static const _baseLock = Duration(seconds: 30);
  static const _maxLock = Duration(minutes: 15);

  /// Blok tugashigacha qolgan vaqt; bloklanmagan bo'lsa [Duration.zero].
  static Future<Duration> remaining({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final until = prefs.getInt(_lockedUntilKey) ?? 0;
      final ms = until - (now ?? DateTime.now()).millisecondsSinceEpoch;
      return ms > 0 ? Duration(milliseconds: ms) : Duration.zero;
    } catch (_) {
      return Duration.zero;
    }
  }

  /// Noto'g'ri urinishni qayd etadi va kerak bo'lsa bloklaydi.
  static Future<void> recordFailure({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failures = (prefs.getInt(_failuresKey) ?? 0) + 1;
      await prefs.setInt(_failuresKey, failures);
      final lock = lockFor(failures);
      if (lock > Duration.zero) {
        final until = (now ?? DateTime.now()).add(lock).millisecondsSinceEpoch;
        await prefs.setInt(_lockedUntilKey, until);
      }
    } catch (_) {}
  }

  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_failuresKey);
      await prefs.remove(_lockedUntilKey);
    } catch (_) {}
  }

  /// [failures] ta ketma-ket xatodan keyingi blok muddati.
  static Duration lockFor(int failures) {
    if (failures < freeAttempts) return Duration.zero;
    final steps = failures - freeAttempts; // 0 -> 30 s, 1 -> 60 s, ...
    final seconds = _baseLock.inSeconds * (1 << steps.clamp(0, 10));
    final lock = Duration(seconds: seconds);
    return lock > _maxLock ? _maxLock : lock;
  }
}
