import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// Foydalanuvchiga ko'rsatiladigan xatolar uchun l10n KALITINI qaytaradi;
/// matn UI'da `AppLocalizations.get` orqali tilga o'giriladi.
class ErrorHandler {
  static String toUserFriendly(dynamic e) {
    final errorStr = e.toString();

    if (e is FirebaseAuthException) {
      return _mapFirebaseError(e.code);
    }

    if (errorStr.contains('SocketException') ||
        errorStr.contains('NetworkImage')) {
      return 'err_no_internet';
    }

    if (e is PlatformException) {
      final details = '${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
      if (e.code == '10' ||
          e.code == '12500' ||
          details.contains('apiexception: 10') ||
          details.contains('apiexception: 12500')) {
        return 'err_google_config';
      }
      if (e.code.toLowerCase().contains('network') ||
          details.contains('network')) {
        return 'err_network_lost';
      }
      if (e.code.toLowerCase().contains('cancel')) {
        return 'err_google_cancelled';
      }
      return 'err_system';
    }

    if (errorStr.contains('SqliteException')) {
      return 'err_database';
    }

    if (errorStr.contains('not found') || errorStr.contains('not supported')) {
      return 'err_ai_busy';
    }

    return 'err_generic';
  }

  static String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'err_email_in_use';
      case 'invalid-email':
        return 'err_invalid_email';
      case 'weak-password':
        return 'err_weak_password';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'err_bad_credentials';
      case 'user-disabled':
        return 'err_user_disabled';
      case 'too-many-requests':
        return 'err_too_many';
      case 'operation-not-allowed':
        return 'err_google_disabled';
      case 'network-request-failed':
        return 'err_network_lost';
      case 'account-exists-with-different-credential':
        return 'err_account_exists_other';
      case 'credential-already-in-use':
        return 'err_credential_in_use';
      default:
        return 'err_sign_in';
    }
  }
}
