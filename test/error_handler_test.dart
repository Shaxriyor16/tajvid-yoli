import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tajvid_yoli/core/l10n/app_localizations.dart';
import 'package:tajvid_yoli/core/utils/error_handler.dart';

void main() {
  test('every user-facing error key is translated in all languages', () {
    final errors = <dynamic>[
      'SocketException',
      PlatformException(code: '10'),
      PlatformException(code: 'network_error'),
      PlatformException(code: 'sign_in_canceled'),
      PlatformException(code: 'other'),
      'SqliteException',
      'not found',
      'unknown',
      for (final code in [
        'email-already-in-use',
        'invalid-email',
        'weak-password',
        'wrong-password',
        'user-disabled',
        'too-many-requests',
        'operation-not-allowed',
        'network-request-failed',
        'account-exists-with-different-credential',
        'credential-already-in-use',
        'something-else',
      ])
        FirebaseAuthException(code: code),
    ];
    final keys = {
      ...errors.map(ErrorHandler.toUserFriendly),
      'err_signup_failed',
      'err_bad_login',
    };
    for (final lang in ['uz', 'en', 'ar']) {
      final l10n = AppLocalizations(Locale(lang));
      for (final key in keys) {
        expect(l10n.get(key), isNot(key), reason: '$key missing in $lang');
      }
    }
  });
}
