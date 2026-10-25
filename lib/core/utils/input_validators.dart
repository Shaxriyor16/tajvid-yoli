/// Foydalanuvchi kiritgan ma'lumotlarni serverga yuborishdan OLDIN
/// tekshirish uchun markaziy validatsiya qoidalari.
///
/// Bu qoidalar mijoz tomonida qulaylik uchun; asl himoya Firebase
/// security rules va server qoidalarida (firestore.rules) bo'ladi.
class InputValidators {
  InputValidators._();

  /// Ism/familiya uchun maksimal uzunlik (Firestore rules bilan mos).
  static const int nameMaxLength = 100;

  /// Parol uchun minimal uzunlik. Firebase o'zi min 6 talab qiladi,
  /// biz xavfsizlik uchun 8 ni tavsiya etamiz.
  static const int passwordMinLength = 8;

  /// Email uchun maksimal uzunlik (RFC 5321 chegarasi).
  static const int emailMaxLength = 320;

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static bool isValidEmail(String email) {
    final value = email.trim();
    return value.isNotEmpty &&
        value.length <= emailMaxLength &&
        _emailRegExp.hasMatch(value);
  }

  static bool isValidPassword(String password) =>
      password.length >= passwordMinLength;

  static bool isValidName(String name) {
    final value = name.trim();
    return value.isNotEmpty && value.length <= nameMaxLength;
  }
}
