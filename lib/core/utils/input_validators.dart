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

  /// Eng ko'p ishlatiladigan parollar (credential stuffing hujumlarida birinchi sinaladi).
  static const _commonPasswords = {
    '12345678', '123456789', '1234567890', 'password', 'password1', 'qwerty123',
    'qwertyui', 'iloveyou', '11111111', '00000000', '12341234', 'abc12345',
    'admin123', 'letmein1', 'welcome1', 'tajvid123', 'qur12345', 'allah123',
    'bismillah', 'muhammad1', 'abcd1234', '1q2w3e4r', 'q1w2e3r4', 'asdf1234',
  };

  /// Kamida 8 belgi, harf va raqam birga, va keng tarqalgan parol emas.
  static bool isValidPassword(String password) =>
      password.length >= passwordMinLength &&
      RegExp(r'\p{L}', unicode: true).hasMatch(password) &&
      RegExp(r'\d').hasMatch(password) &&
      !_commonPasswords.contains(password.toLowerCase());

  static bool isValidName(String name) {
    final value = name.trim();
    return value.isNotEmpty && value.length <= nameMaxLength;
  }
}
