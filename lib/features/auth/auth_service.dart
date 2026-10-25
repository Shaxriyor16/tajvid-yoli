import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../../core/services/logger_service.dart';
import 'auth_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userKey = 'tajvid_user_data';

  /// Profil rasmi qurilmaning o'zida saqlanadi (bulutga yuklanmaydi).
  static String _photoKeyFor(String uid) => 'tajvid_local_photo_$uid';

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      // XAVFSIZLIK: ro'yxatdan o'tgan email tasdiqlanishi kerak.
      await credential.user!.sendEmailVerification();
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        provider: 'email',
      );
      await _cacheUser(user);
      return user;
    }
    return null;
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      if (!credential.user!.emailVerified) {
        return await _cachedUser(credential.user!.uid) ??
            UserModel(
              uid: credential.user!.uid,
              email: credential.user!.email ?? email,
              firstName: '',
              lastName: '',
              provider: 'email',
            );
      }
      return await _syncUserFromFirestore(credential.user!.uid);
    }
    return null;
  }

  Future<bool> isCurrentEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null || !refreshedUser.emailVerified) return false;
    await refreshedUser.getIdToken(true);
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    await user.sendEmailVerification();
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.i('Google sign-in cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        return await _syncUserFromFirestore(
            userCredential.user!.uid, googleUser);
      }
      return null;
    } catch (e, s) {
      AppLogger.e('Google sign-in exception: $e', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<UserModel?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.tajvidyoli.app.signin',
          redirectUri: Uri.parse(
            'https://tajvi-yo-li.firebaseapp.com/__/auth/handler',
          ),
        ),
        nonce: nonce,
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        return await _syncUserFromFirestore(
            userCredential.user!.uid, null, appleCredential);
      }
      return null;
    } catch (e, s) {
      AppLogger.e('Apple sign-in failed', error: e, stackTrace: s);
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<UserModel?> _syncUserFromFirestore(String uid,
      [GoogleSignInAccount? googleUser,
      AuthorizationCredentialAppleID? appleCredential]) async {
    // Fetch the remote profile and local avatar together so OAuth login does
    // not pay for two sequential waits.
    final profileFuture = _firestore
        .collection('users')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 15));
    final localPhotoFuture = _localPhotoPath(uid);
    final doc = await profileFuture;
    UserModel? user;
    var isNewProfile = false;
    if (doc.exists) {
      user = UserModel.fromJson(doc.data()!);
    } else if (googleUser != null) {
      isNewProfile = true;
      final nameParts = (googleUser.displayName ?? '').split(' ');
      user = UserModel(
        uid: uid,
        email: googleUser.email,
        firstName: nameParts.isNotEmpty ? nameParts.first : '',
        lastName: nameParts.length > 1 ? nameParts.last : '',
        photoUrl: googleUser.photoUrl,
        provider: 'google',
      );
    } else if (appleCredential != null) {
      isNewProfile = true;
      user = UserModel(
        uid: uid,
        email: appleCredential.email ?? '',
        firstName: appleCredential.givenName ?? '',
        lastName: appleCredential.familyName ?? '',
        provider: 'apple',
      );
    } else {
      isNewProfile = true;
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null || firebaseUser.uid != uid) return null;
      user = UserModel(
          uid: uid,
          email: firebaseUser.email ?? '',
          firstName: '',
          lastName: '',
          provider: 'email');
    }

    // Qurilmada saqlangan rasm bulutdan ustuvor — sinxronlash uni o'chirmasin.
    final localPhoto = await localPhotoFuture;
    if (localPhoto != null) {
      user = user.copyWith(photoUrl: localPhoto);
    }

    // Existing profiles are already current in Firestore. Cache them locally
    // without rewriting the same document on every sign-in.
    if (isNewProfile) {
      await saveUser(user);
    } else {
      await _cacheUser(user);
    }
    return user;
  }

  Future<void> saveUser(UserModel user) async {
    if (_auth.currentUser?.uid != user.uid) {
      throw StateError('Profile does not belong to the active session');
    }
    try {
      // Bulutga lokal fayl yo'li yuborilmaydi — faqat https rasm yoki hech narsa.
      final cloudJson = user.toJson();
      final photo = cloudJson['photoUrl'] as String?;
      if (photo != null && !photo.startsWith('https://')) {
        cloudJson.remove('photoUrl');
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(cloudJson)
          .timeout(const Duration(seconds: 15));
      await _cacheUser(user);
    } catch (e, s) {
      AppLogger.e('Failed to save user', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<UserModel?> loadUser() async {
    try {
      final currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_userKey);
        return null;
      }
      final cachedUser = await _cachedUser(currentFirebaseUser.uid);
      if (cachedUser != null) return cachedUser;

      if (currentFirebaseUser.providerData
              .any((provider) => provider.providerId == 'password') &&
          !currentFirebaseUser.emailVerified) {
        return UserModel(
          uid: currentFirebaseUser.uid,
          email: currentFirebaseUser.email ?? '',
          firstName: '',
          lastName: '',
          provider: 'email',
        );
      }

      return await _syncUserFromFirestore(currentFirebaseUser.uid);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> _cachedUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userKey);
    if (jsonString == null) return null;
    final user = UserModel.fromJson(jsonDecode(jsonString));
    if (user.uid == uid) return user;
    await prefs.remove(_userKey);
    return null;
  }

  Future<void> _cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Profil rasmi qurilmaning o'zida saqlanadi (Firebase Storage talab
  /// qilinmaydi). Fayl mavjudligi va hajmi (maks 5 MB) tekshiriladi.
  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  Future<String?> saveProfilePictureLocally(File file, String uid) async {
    try {
      if (!await file.exists()) {
        AppLogger.w('Photo save skipped: file not found');
        return null;
      }
      if (await file.length() > _maxPhotoBytes) {
        AppLogger.w('Photo save rejected: file exceeds 5 MB');
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final target = File(p.join(dir.path, 'profile_$uid.jpg'));
      await file.copy(target.path);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoKeyFor(uid), target.path);
      return target.path;
    } catch (e, s) {
      AppLogger.e('Photo save failed', error: e, stackTrace: s);
      return null;
    }
  }

  /// Agar qurilmada saqlangan profil rasmi bo'lsa, yo'lini qaytaradi.
  Future<String?> _localPhotoPath(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_photoKeyFor(uid));
      if (path != null && await File(path).exists()) return path;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    final currentUser = _auth.currentUser;
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Firebase has already signed out; local cleanup must still run.
    }
    final prefs = await SharedPreferences.getInstance();
    if (currentUser?.emailVerified ?? true) {
      await prefs.remove(_userKey);
    }
  }

  Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }

  Future<void> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in account');
    await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('deleteAccount',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 60)))
        .call<void>({'confirm': true});

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    final photoKey = _photoKeyFor(uid);
    final path = prefs.getString(photoKey);
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        AppLogger.w('Deleted account photo could not be removed locally');
      }
    }
    await prefs.remove(photoKey);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}
