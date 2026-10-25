import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_messages.dart';

/// Ilova ichidagi barcha bildirishnoma mantiqi shu yerda markazlashgan.
///
/// Hammasi mahalliy (lokal) bildirishnomalar — internet va server shart emas.
/// Ilova har ochilganda keyingi 7 kunlik jadval qayta tuziladi: kunlik dars
/// eslatmasi (matnlar aylanib turadi), ertalabki maslahat, juma xabari,
/// seriya xavfi va uzoq kirmaganlarga qaytish xabarlari.
class NotificationService {
  static const String _reminderEnabledKey = 'daily_reminder_enabled';
  static const String _reminderHourKey = 'daily_reminder_hour';
  static const String _reminderMinuteKey = 'daily_reminder_minute';
  static const String _tipsEnabledKey = 'tips_enabled';
  static const String _langKey = 'notif_lang';
  static const String _streakKey = 'notif_streak';
  static const String _activeDayKey = 'notif_active_day';
  static const int _streakRiskId = 1002;
  static const int _comebackBaseId = 1010;
  static const int _dailyBaseId = 2000;
  static const int _tipBaseId = 3000;
  static const int _fridayBaseId = 4000;

  /// Necha kun oldinga rejalashtiriladi (ilova ochilganda har safar yangilanadi).
  static const int _horizonDays = 7;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Oxirgi muvaffaqiyatsiz rejalashtirish sababi (sozlamalarda ko'rsatiladi).
  String? lastError;
  bool _timezoneReady = false;

  Future<void> init() async {
    if (_initialized ||
        kIsWeb ||
        !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }

    const androidInit = AndroidInitializationSettings('ic_stat_notify');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const macInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidInit, iOS: iosInit, macOS: macInit),
    );
    _initialized = true;

    await _ensureTimezone();
  }

  /// Qurilma vaqt mintaqasini aniqlab, timezone kutubxonasiga o'rnatadi.
  Future<void> _ensureTimezone() async {
    if (_timezoneReady) return;
    try {
      tz_data.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
      _timezoneReady = true;
    } catch (_) {
      // Vaqt mintaqasi aniqlanmasa UTC bilan davom etamiz.
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
        _timezoneReady = true;
      } catch (_) {
        _timezoneReady = false;
      }
    }
  }

  /// Foydalanuvchidan bildirishnoma ruxsatini so'raydi.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (Platform.isMacOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }

    if (Platform.isAndroid) {
      // Android 13+ da POST_NOTIFICATIONS manifestda e'lon qilingan bo'lishi shart.
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == true) return true;
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return false;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled != null) return enabled;
      return await Permission.notification.isGranted;
    }
    if (Platform.isIOS) {
      final permissions = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    if (Platform.isMacOS) {
      final permissions = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    return false;
  }

  Future<void> showNow(
      {required int id, required String title, required String body}) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'general',
      'Umumiy bildirishnomalar',
      channelDescription: 'Dars, streak va yangiliklar haqida xabarlar',
      icon: 'ic_stat_notify',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails());
    await _plugin.show(id, title, body, details);
  }

  // ---------------------------------------------------------------------------
  // Avtomatik bildirishnomalar
  // ---------------------------------------------------------------------------

  /// Saqlangan eslatma sozlamalarini o'qiydi.
  Future<({bool enabled, TimeOfDay time})> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_reminderEnabledKey) ?? false;
    final hour = (prefs.getInt(_reminderHourKey) ?? 20).clamp(0, 23);
    final minute = (prefs.getInt(_reminderMinuteKey) ?? 0).clamp(0, 59);
    return (enabled: enabled, time: TimeOfDay(hour: hour, minute: minute));
  }

  Future<bool> getTipsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tipsEnabledKey) ?? true;
  }

  Future<void> setTipsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tipsEnabledKey, value);
    await syncSchedule();
  }

  /// Bildirishnomalarni yoqadi va butun rejani tuzadi.
  Future<bool> enableDailyReminder(TimeOfDay time) async {
    if (kIsWeb) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderEnabledKey, true);
      await prefs.setInt(_reminderHourKey, time.hour);
      await prefs.setInt(_reminderMinuteKey, time.minute);
      return await syncSchedule();
    } catch (e) {
      lastError = '$e';
      return false;
    }
  }

  /// Hamma rejalashtirilgan bildirishnomalarni bekor qiladi.
  Future<void> disableDailyReminder() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, false);
    if (_initialized) await _plugin.cancelAll();
  }

  /// Ilova ochilganda / davom etganda chaqiriladi: til va seriya holatini
  /// yangilab, kelgusi bildirishnomalarni qayta tuzadi.
  Future<void> updateContext({
    required String lang,
    required int streak,
    required bool activeToday,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
    await prefs.setInt(_streakKey, streak);
    if (activeToday) {
      final t = DateTime.now();
      await prefs.setString(_activeDayKey, '${t.year}-${t.month}-${t.day}');
    }
    await syncSchedule();
  }

  /// Ruxsat va sozlamaga qarab jadvalni qayta tuzadi. Muvaffaqiyatli bo'lsa true.
  Future<bool> syncSchedule() async {
    lastError = null;
    if (kIsWeb) return false;
    if (!_initialized) {
      // Ishga tushish tugamagan bo'lishi mumkin — qayta urinib ko'ramiz.
      try {
        await init();
      } catch (e) {
        lastError = 'init: $e';
        return false;
      }
      if (!_initialized) {
        lastError = 'init: not initialized';
        return false;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_reminderEnabledKey) ?? false)) return false;
    if (!await hasPermission()) {
      lastError = 'permission';
      return false;
    }
    await _ensureTimezone();
    if (!_timezoneReady) {
      lastError = 'timezone';
      return false;
    }

    final lang = prefs.getString(_langKey) ?? 'uz';
    final streak = prefs.getInt(_streakKey) ?? 0;
    final time = TimeOfDay(
      hour: (prefs.getInt(_reminderHourKey) ?? 20).clamp(0, 23),
      minute: (prefs.getInt(_reminderMinuteKey) ?? 0).clamp(0, 59),
    );
    final tipsOn = prefs.getBool(_tipsEnabledKey) ?? true;

    final now = tz.TZDateTime.now(tz.local);
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final activeToday = prefs.getString(_activeDayKey) == todayKey;

    try {
      await _plugin.cancelAll();

      tz.TZDateTime at(int dayOffset, int hour, int minute) => tz.TZDateTime(
          tz.local, now.year, now.month, now.day + dayOffset, hour, minute);

      final epochDay = now.difference(tz.TZDateTime(tz.local, 2024)).inDays;
      final reminderMinutes = time.hour * 60 + time.minute;

      for (var d = 0; d < _horizonDays; d++) {
        final isFriday = at(d, 12, 0).weekday == DateTime.friday;

        // 1) Kunlik dars eslatmasi (bugun o'qigan bo'lsa, bugungisi o'tkaziladi).
        final lesson = at(d, time.hour, time.minute);
        if (lesson.isAfter(now) && !(d == 0 && activeToday)) {
          final m = NotificationMessages.daily(lang, epochDay + d);
          await _schedule(_dailyBaseId + d, lesson, m.$1, m.$2,
              channel: _Channel.daily, lang: lang);
        }

        // 2) Ertalabki maslahat yoki juma xabari (eslatmaga yaqin bo'lsa o'tkaziladi).
        if (tipsOn) {
          final hour = isFriday ? 11 : 9;
          final slot = at(d, hour, 0);
          if (slot.isAfter(now) && (hour * 60 - reminderMinutes).abs() >= 60) {
            final m = isFriday
                ? NotificationMessages.friday(lang)
                : NotificationMessages.tip(lang, epochDay + d);
            await _schedule(
                (isFriday ? _fridayBaseId : _tipBaseId) + d, slot, m.$1, m.$2,
                channel: _Channel.tips, lang: lang);
          }
        }
      }

      // 3) Seriya xavfi: bugun hali o'qimagan bo'lsa, kechqurun ogohlantirish.
      final risk = at(0, 21, 30);
      if (streak >= 2 &&
          !activeToday &&
          risk.isAfter(now) &&
          reminderMinutes < 21 * 60) {
        final m = NotificationMessages.streakRisk(lang, streak);
        await _schedule(_streakRiskId, risk, m.$1, m.$2,
            channel: _Channel.streak, lang: lang);
      }

      // 4) Qaytish xabarlari: ilova ochilmasa 9, 16 va 30-kuni (har ochilganda siljiydi).
      const comebackDays = [9, 16, 30];
      for (var i = 0; i < comebackDays.length; i++) {
        final m = NotificationMessages.comeback(lang, i);
        await _schedule(
            _comebackBaseId + i, at(comebackDays[i], 19, 0), m.$1, m.$2,
            channel: _Channel.comeback, lang: lang);
      }
      return true;
    } catch (e) {
      lastError = '$e';
      return false;
    }
  }

  Future<void> _schedule(
    int id,
    tz.TZDateTime when,
    String title,
    String body, {
    required _Channel channel,
    required String lang,
  }) {
    final c = channel.info(lang);
    final android = AndroidNotificationDetails(
      c.id,
      c.name,
      channelDescription: c.description,
      icon: 'ic_stat_notify',
      color: const Color(0xFF16604F),
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );
    const darwin = DarwinNotificationDetails();
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      NotificationDetails(android: android, iOS: darwin, macOS: darwin),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

enum _Channel {
  daily,
  tips,
  streak,
  comeback;

  ({String id, String name, String description}) info(String lang) {
    final l = (lang == 'en' || lang == 'ar') ? lang : 'uz';
    const names = <String, Map<String, String>>{
      'daily': {'uz': 'Kunlik eslatma', 'en': 'Daily reminder', 'ar': 'تذكير يومي'},
      'tips': {'uz': 'Maslahatlar', 'en': 'Tips', 'ar': 'نصائح'},
      'streak': {
        'uz': 'Seriya himoyasi',
        'en': 'Streak protection',
        'ar': 'حماية التسلسل'
      },
      'comeback': {
        'uz': 'Eslatmalar',
        'en': 'Gentle nudges',
        'ar': 'تنبيهات لطيفة'
      },
    };
    return (
      id: 'ch_$name',
      name: names[name]![l]!,
      description: names[name]![l]!,
    );
  }
}
