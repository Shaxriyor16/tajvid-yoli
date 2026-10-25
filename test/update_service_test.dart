import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tajvid_yoli/core/services/update_service.dart';

const _json = {
  'version': '1.2.0',
  'build': 12,
  'minBuild': 10,
  'url': 'https://tajvid-yoli.vercel.app/downloads/tajvid-yoli.apk',
  'sha256': 'abc',
  'sizeBytes': 83886080,
  'notes': {'uz': 'Yangi dizayn', 'en': 'New design'},
};

void main() {
  test('parses a valid version.json and rejects broken ones', () {
    final info = AppVersionInfo.tryParse(_json)!;
    expect(info.version, '1.2.0');
    expect(info.build, 12);
    expect(info.minBuild, 10);
    expect(info.noteFor('en'), 'New design');
    expect(info.noteFor('ar'), 'Yangi dizayn'); // uz zaxira
    expect(AppVersionInfo.tryParse({'version': '1'}), isNull);
    expect(AppVersionInfo.tryParse('x'), isNull);
    expect(AppVersionInfo.tryParse({..._json, 'build': '12'}), isNull);
  });

  test('decides none / optional / required by build number', () {
    final info = AppVersionInfo.tryParse(_json)!;
    expect(UpdateService.decide(info, 12), UpdateKind.none);
    expect(UpdateService.decide(info, 13), UpdateKind.none);
    expect(UpdateService.decide(info, 11), UpdateKind.optional);
    expect(UpdateService.decide(info, 10), UpdateKind.optional);
    expect(UpdateService.decide(info, 9), UpdateKind.required);
  });

  test('download links are trusted only on our own https domain', () {
    expect(
        UpdateService.isTrustedUrl(
            'https://tajvid-yoli.vercel.app/downloads/tajvid-yoli.apk'),
        isTrue);
    expect(UpdateService.isTrustedUrl('http://tajvid-yoli.vercel.app/a.apk'),
        isFalse);
    expect(UpdateService.isTrustedUrl('https://evil.example.com/a.apk'),
        isFalse);
    expect(
        UpdateService.isTrustedUrl(
            'https://tajvid-yoli.vercel.app.evil.com/a.apk'),
        isFalse);
    expect(UpdateService.isTrustedUrl('javascript:alert(1)'), isFalse);
  });

  test('fetch returns info on 200, null on errors or garbage', () async {
    final ok = MockClient((_) async => http.Response(jsonEncode(_json), 200));
    expect((await UpdateService.fetch(client: ok))!.build, 12);
    final notFound = MockClient((_) async => http.Response('nope', 404));
    expect(await UpdateService.fetch(client: notFound), isNull);
    final garbage = MockClient((_) async => http.Response('<html>', 200));
    expect(await UpdateService.fetch(client: garbage), isNull);
    final boom = MockClient((_) async => throw Exception('offline'));
    expect(await UpdateService.fetch(client: boom), isNull);
  });
}
