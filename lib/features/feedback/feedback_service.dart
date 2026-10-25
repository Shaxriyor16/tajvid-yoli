import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Foydalanuvchi mulohazasi. Firestore'dagi `feedback` kolleksiyasiga yoziladi
/// va admin panelda ko'rinadi (qoidalar: firestore.rules).
class FeedbackEntry {
  final String uid;
  final String name;
  final String email;
  final int rating; // 1..5
  final String category; // idea | bug | praise | other
  final String message;
  final String appVersion;
  final String locale;

  const FeedbackEntry({
    required this.uid,
    required this.name,
    required this.email,
    required this.rating,
    required this.category,
    required this.message,
    required this.appVersion,
    required this.locale,
  });

  static const categories = ['idea', 'bug', 'praise', 'other'];
  static const maxMessage = 1000;

  Map<String, Object?> toMap() => {
        'uid': uid,
        'name': name.length > 100 ? name.substring(0, 100) : name,
        'email': email.length > 320 ? '' : email,
        'rating': rating,
        'category': category,
        'message': message,
        'appVersion': appVersion.length > 40 ? appVersion.substring(0, 40) : appVersion,
        'platform': kIsWeb
            ? 'other'
            : Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                    ? 'ios'
                    : 'other',
        'locale': const ['uz', 'en', 'ar'].contains(locale) ? locale : 'uz',
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class FeedbackTooFast implements Exception {
  const FeedbackTooFast();
}

typedef FeedbackSender = Future<void> Function(FeedbackEntry entry);

class FeedbackService {
  static const _lastKey = 'feedback_last_sent_ms';
  static const cooldown = Duration(seconds: 60);

  /// Mulohazani Firestore'ga yuboradi. Juda tez-tez yuborilsa [FeedbackTooFast].
  static Future<void> send(FeedbackEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < cooldown.inMilliseconds) throw const FeedbackTooFast();

    await FirebaseFirestore.instance
        .collection('feedback')
        .add(entry.toMap())
        .timeout(const Duration(seconds: 15));
    await prefs.setInt(_lastKey, now);
  }
}
