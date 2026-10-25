import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Bitta arxitektura uchun APK (arm64-v8a, armeabi-v7a, ...).
class ApkAsset {
  final String url;
  final String sha256;
  final int sizeBytes;
  const ApkAsset({required this.url, this.sha256 = '', this.sizeBytes = 0});

  static ApkAsset? tryParse(Object? json) {
    if (json is! Map || json['url'] is! String) return null;
    return ApkAsset(
      url: json['url'] as String,
      sha256: json['sha256'] is String ? json['sha256'] as String : '',
      sizeBytes: json['sizeBytes'] is int ? json['sizeBytes'] as int : 0,
    );
  }
}

/// `version.json` (saytda) mazmuni. `deploy/release.py` har release'da yangilaydi.
class AppVersionInfo {
  final String version;
  final int build;
  final int minBuild;
  final String url;
  final String sha256;
  final int sizeBytes;
  final Map<String, String> notes;
  final Map<String, ApkAsset> apks;

  const AppVersionInfo({
    required this.version,
    required this.build,
    required this.minBuild,
    required this.url,
    this.sha256 = '',
    this.sizeBytes = 0,
    this.notes = const {},
    this.apks = const {},
  });

  static AppVersionInfo? tryParse(Object? json) {
    if (json is! Map) return null;
    final build = json['build'];
    final version = json['version'];
    final url = json['url'];
    if (build is! int || version is! String || url is! String) return null;
    final minBuild = json['minBuild'];
    final notes = json['notes'];
    final apks = json['apks'];
    return AppVersionInfo(
      version: version,
      build: build,
      minBuild: minBuild is int ? minBuild : 0,
      url: url,
      sha256: json['sha256'] is String ? json['sha256'] as String : '',
      sizeBytes: json['sizeBytes'] is int ? json['sizeBytes'] as int : 0,
      notes: notes is Map
          ? {
              for (final e in notes.entries)
                if (e.key is String && e.value is String)
                  e.key as String: e.value as String
            }
          : const {},
      apks: apks is Map
          ? {
              for (final e in apks.entries)
                if (e.key is String && ApkAsset.tryParse(e.value) != null)
                  e.key as String: ApkAsset.tryParse(e.value)!
            }
          : const {},
    );
  }

  /// Qurilma qo'llaydigan arxitekturalar (afzallik tartibida) bo'yicha eng mos APK;
  /// topilmasa umumiy `url` ga qaytadi.
  ApkAsset assetFor(List<String> supportedAbis) {
    for (final abi in supportedAbis) {
      final a = apks[abi];
      if (a != null) return a;
    }
    return ApkAsset(url: url, sha256: sha256, sizeBytes: sizeBytes);
  }

  String noteFor(String lang) => notes[lang] ?? notes['uz'] ?? '';
}

enum UpdateKind { none, optional, required }

/// Ilovani yangilash tekshiruvi: Google Play'siz tarqatish uchun.
///
/// Ilova saytdagi `version.json` ni o'qiydi. Yangi versiya bo'lsa, foydalanuvchiga
/// yuklab olish havolasi taklif qilinadi (o'rnatishni Android o'zi tasdiqlatadi).
/// Havola faqat o'zimizning domenga (HTTPS) olib borsa ochiladi.
class UpdateService {
  /// Domen olingach `python deploy/set_domain.py` shu yerni ham yangilaydi.
  static const siteUrl = 'https://tajvid-yoli.vercel.app';
  static const _lastPromptKey = 'update_prompt_ms';
  static const _optionalEvery = Duration(hours: 24);
  static bool _checkedThisLaunch = false;

  static Future<AppVersionInfo?> fetch({http.Client? client}) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse('$siteUrl/version.json'),
              headers: const {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return AppVersionInfo.tryParse(jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (_) {
      return null; // tarmoq yo'q yoki fayl buzuq: ilova ishlashda davom etadi
    } finally {
      if (client == null) c.close();
    }
  }

  static UpdateKind decide(AppVersionInfo info, int currentBuild) {
    if (info.build <= currentBuild) return UpdateKind.none;
    if (currentBuild < info.minBuild) return UpdateKind.required;
    return UpdateKind.optional;
  }

  /// Yuklab olish havolasi faqat o'zimizning domenda va HTTPS bo'lsagina ishonchli.
  static bool isTrustedUrl(String url) {
    final u = Uri.tryParse(url);
    final site = Uri.parse(siteUrl);
    return u != null && u.scheme == 'https' && u.host == site.host;
  }

  /// Ilova ochilganda bir marta chaqiriladi. Faqat Android (iOS do'kondan yangilanadi).
  static Future<void> checkAndPrompt(BuildContext context) async {
    if (_checkedThisLaunch || !Platform.isAndroid) return;
    _checkedThisLaunch = true;
    final info = await fetch();
    if (info == null) return;
    List<String> abis = const [];
    try {
      abis = (await DeviceInfoPlugin().androidInfo).supportedAbis;
    } catch (_) {}
    final asset = info.assetFor(abis);
    if (!isTrustedUrl(asset.url)) return;
    final current =
        int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
    final kind = decide(info, current);
    if (kind == UpdateKind.none) return;

    final prefs = await SharedPreferences.getInstance();
    if (kind == UpdateKind.optional) {
      final last = prefs.getInt(_lastPromptKey) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - last <
          _optionalEvery.inMilliseconds) {
        return;
      }
    }
    await prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
    if (!context.mounted) return;
    await _showDialog(context, info, asset, kind == UpdateKind.required);
  }

  static Future<void> _showDialog(BuildContext context, AppVersionInfo info,
      ApkAsset asset, bool required) {
    final l10n = AppLocalizations.of(context);
    final note = info.noteFor(l10n.locale.languageCode);
    final mb = asset.sizeBytes > 0
        ? ' (${(asset.sizeBytes / 1048576).round()} MB)'
        : '';
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: !required,
      builder: (ctx) => PopScope(
        canPop: !required,
        child: CupertinoAlertDialog(
          title: Text(l10n
              .get(required ? 'upd_required_title' : 'upd_title')),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${l10n.get('upd_body').replaceAll('{v}', info.version)}$mb'
              '${note.isEmpty ? '' : '\n\n$note'}',
            ),
          ),
          actions: [
            if (!required)
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.get('upd_later')),
              ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                await launchUrl(Uri.parse(asset.url),
                    mode: LaunchMode.externalApplication);
                if (!required && ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(l10n.get('upd_now')),
            ),
          ],
        ),
      ),
    );
  }
}
