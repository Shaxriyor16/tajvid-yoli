/// Avtomatik bildirishnomalar matnlari (uz / en / ar).
///
/// Matnlar har kuni aylanib turadi, shunda foydalanuvchi har safar bir xil
/// xabarni ko'rmaydi. `{n}` — seriya kunlari soni.
class NotificationMessages {
  const NotificationMessages._();

  static String _lang(String code) =>
      (code == 'en' || code == 'ar') ? code : 'uz';

  /// Kunlik dars eslatmasi: (sarlavha, matn).
  static (String, String) daily(String lang, int index) {
    final list = _daily[_lang(lang)]!;
    return list[index % list.length];
  }

  /// Ertalabki foydali maslahat (tajvid / Qur'on odobi).
  static (String, String) tip(String lang, int index) {
    final list = _tips[_lang(lang)]!;
    return list[index % list.length];
  }

  static (String, String) friday(String lang) => _friday[_lang(lang)]!;

  static (String, String) streakRisk(String lang, int days) {
    final m = _streak[_lang(lang)]!;
    return (m.$1.replaceAll('{n}', '$days'), m.$2.replaceAll('{n}', '$days'));
  }

  /// Uzoq kirmagan foydalanuvchiga qaytish xabari. [step]: 0, 1, 2.
  static (String, String) comeback(String lang, int step) {
    final list = _comeback[_lang(lang)]!;
    return list[step.clamp(0, list.length - 1)];
  }

  static const _daily = <String, List<(String, String)>>{
    'uz': [
      ('Bugungi darsni unutmang 🌙', "Bir necha daqiqa — va seriyangiz davom etadi."),
      ('Qur‘on bilan bir lahza ✨', "Bugun yangi bir tajvid qoidasini o‘rganing."),
      ('Mashq vaqti keldi', "Qisqa test bilan o‘rganganlaringizni mustahkamlang."),
      ('Har kuni ozdan — katta natija', "Bugungi 5 daqiqalik darsingiz sizni kutmoqda."),
      ('Harflarni takrorlaymizmi?', "Makhraj mashqi talaffuzingizni silliqlaydi."),
      ('Seriyangizni saqlang 🔥', "Bugun kamida bitta dars o‘ting."),
      ('Tilovat vaqti 📖', "Bir oyat o‘qing, ovozingizni AI tekshirib beradi."),
    ],
    'en': [
      ("Don't forget today's lesson 🌙", 'A few minutes keeps your streak going.'),
      ('A moment with the Qur’an ✨', "Learn a new tajweed rule today."),
      ('Practice time', 'Lock in what you learned with a quick quiz.'),
      ('A little every day goes far', 'Your 5-minute lesson is waiting.'),
      ('Review the letters?', 'A makhraj drill will polish your pronunciation.'),
      ('Protect your streak 🔥', 'Complete at least one lesson today.'),
      ('Recitation time 📖', 'Recite an ayah and let AI check your voice.'),
    ],
    'ar': [
      ('لا تنسَ درس اليوم 🌙', 'بضع دقائق تحافظ على تسلسلك.'),
      ('لحظة مع القرآن ✨', 'تعلّم حكمًا جديدًا من أحكام التجويد اليوم.'),
      ('وقت التدريب', 'ثبّت ما تعلمته باختبار قصير.'),
      ('القليل كل يوم يصنع فرقًا', 'درسك اليومي ينتظرك.'),
      ('نراجع الحروف؟', 'تمرين المخارج يحسّن نطقك.'),
      ('حافظ على تسلسلك 🔥', 'أكمل درسًا واحدًا على الأقل اليوم.'),
      ('وقت التلاوة 📖', 'اقرأ آية ودع الذكاء الاصطناعي يفحص صوتك.'),
    ],
  };

  static const _tips = <String, List<(String, String)>>{
    'uz': [
      ('Tajvid maslahati', "Nun sokin va tanvin: izhor, idg‘om, iqlob, ixfo — to‘rtta hukm."),
      ('Bilasizmi?', "Qalqala harflari: qof, ṭo, bo, jim, dol."),
      ('Maslahat', "Madd harflari: alif, vov, yo — cho‘zish miqdorini yodda tuting."),
      ('Qur‘on odobi', "Tilovatdan oldin tahorat qilish va qiblaga yuzlanish mustahab."),
      ('Tajvid maslahati', "Ra harfi ba‘zan yo‘g‘on, ba‘zan ingichka o‘qiladi."),
      ('Bilasizmi?', "Lom jalola faqat «Alloh» lafzida yo‘g‘on o‘qiladi."),
      ('Maslahat', "Sekin va aniq o‘qing — tartil Qur‘onning buyrug‘i."),
    ],
    'en': [
      ('Tajweed tip', 'Noon sakinah & tanween: izhar, idgham, iqlab, ikhfa — four rules.'),
      ('Did you know?', 'The qalqalah letters are qaf, ta, ba, jim, dal.'),
      ('Tip', 'Madd letters: alif, waw, ya — remember the length of each.'),
      ('Qur’an etiquette', 'It is recommended to be in wudu and face the qiblah.'),
      ('Tajweed tip', 'The letter ra is sometimes heavy, sometimes light.'),
      ('Did you know?', 'The lam in “Allah” is heavy only in certain contexts.'),
      ('Tip', 'Recite slowly and clearly — tartil is a Qur’anic command.'),
    ],
    'ar': [
      ('نصيحة تجويدية', 'النون الساكنة والتنوين: إظهار وإدغام وإقلاب وإخفاء.'),
      ('هل تعلم؟', 'حروف القلقلة: قطب جد.'),
      ('نصيحة', 'حروف المد: الألف والواو والياء، فانتبه إلى مقدار المد.'),
      ('أدب القرآن', 'يُستحب الوضوء واستقبال القبلة عند التلاوة.'),
      ('نصيحة تجويدية', 'حرف الراء يُفخَّم أحيانًا ويُرقَّق أحيانًا.'),
      ('هل تعلم؟', 'تُفخَّم اللام في لفظ الجلالة بعد الفتح أو الضم.'),
      ('نصيحة', 'اقرأ بتمهّل ووضوح؛ فالترتيل أمر قرآني.'),
    ],
  };

  static const _friday = <String, (String, String)>{
    'uz': ('Juma muborak! 🌿', "Bugun Kahf surasini o‘qishni unutmang."),
    'en': ('Jumu‘ah Mubarak! 🌿', "Don't forget to read Surah Al-Kahf today."),
    'ar': ('جمعة مباركة! 🌿', 'لا تنسَ قراءة سورة الكهف اليوم.'),
  };

  static const _streak = <String, (String, String)>{
    'uz': ('{n} kunlik seriyangiz xavfda 🔥', "Tun yarmigacha bitta dars o‘tib, uni saqlab qoling."),
    'en': ('Your {n}-day streak is at risk 🔥', 'Finish one lesson before midnight to keep it.'),
    'ar': ('تسلسل {n} أيام في خطر 🔥', 'أكمل درسًا قبل منتصف الليل للحفاظ عليه.'),
  };

  static const _comeback = <String, List<(String, String)>>{
    'uz': [
      ('Sizni sog‘indik 🌙', "Bugun bir qisqa dars bilan qaytib keling."),
      ('Qur‘on sizni kutmoqda', "Boshlagan ishingizni davom ettiring — har bir qadam muhim."),
      ('Qaytib kelishga hech qachon kech emas', "Tajvid yo‘lini birga davom ettiramiz."),
    ],
    'en': [
      ('We miss you 🌙', 'Come back with one short lesson today.'),
      ('The Qur’an is waiting', 'Pick up where you left off — every step counts.'),
      ("It's never too late", "Let's continue the tajweed journey together."),
    ],
    'ar': [
      ('اشتقنا إليك 🌙', 'عُد اليوم بدرس قصير.'),
      ('القرآن ينتظرك', 'أكمل من حيث توقفت؛ كل خطوة مهمة.'),
      ('لم يفت الأوان', 'لنتابع رحلة التجويد معًا.'),
    ],
  };
}
