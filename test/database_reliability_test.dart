import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tajvid_yoli/core/db/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('updating a lesson replaces progress and dates remain readable',
      () async {
    await db.updateLessonProgress('alifbo', 1, true);
    await db.updateLessonProgress('alifbo', .5, false);
    expect(await db.getCompletedLessonsCount(), 0);
    final latest = await db.getLatestLessonProgress();
    expect(latest!.completion, .5);
    expect(latest.updatedAt.year, DateTime.now().year);
    expect(await db.select(db.lessonProgress).get(), hasLength(1));
  });

  test('duplicate bookmarks are harmless and observable', () async {
    final changes = db.watchBookmarks();
    expect(await changes.first, isEmpty);
    await Future.wait([db.addBookmark(1, 1), db.addBookmark(1, 1)]);
    expect(await db.isBookmarked(1, 1), isTrue);
    expect(await changes.first, hasLength(1));
    await db.removeBookmark(1, 1);
    expect(await changes.first, isEmpty);
  });

  test('learning records stay scoped to their account across logout', () async {
    await db.setActiveUser('account-a');
    await db.updateLessonProgress('lesson-a', 1, true);
    await db.addBookmark(1, 1);
    await db.awardXp(amount: 25, reason: 'practice');
    expect(await db.getCompletedLessonsCount(), 1);
    expect(await db.getTotalXp(), 25);

    await db.setActiveUser(null);
    expect(await db.getCompletedLessonsCount(), 0);
    expect(await db.getTotalXp(), 0);
    expect(await db.watchBookmarks().first, isEmpty);

    await db.setActiveUser('account-b');
    expect(await db.getCompletedLessonsCount(), 0);
    expect(await db.getTotalXp(), 0);
    expect(await db.watchBookmarks().first, isEmpty);
    await db.addBookmark(1, 1);
    expect(await db.watchBookmarks().first, hasLength(1));

    await db.setActiveUser('account-a');
    expect(await db.getCompletedLessonsCount(), 1);
    expect(await db.getTotalXp(), 25);
    expect(await db.watchBookmarks().first, hasLength(1));
  });

  test('first account adopts legacy local learning records once', () async {
    await db.updateLessonProgress('legacy-lesson', 1, true);
    await db.addBookmark(2, 3);
    await db.awardXp(amount: 10, reason: 'legacy');

    await db.setActiveUser('first-account');
    expect(await db.getCompletedLessonsCount(), 1);
    expect(await db.getTotalXp(), 10);
    expect(await db.watchBookmarks().first, hasLength(1));

    await db.setActiveUser('second-account');
    expect(await db.getCompletedLessonsCount(), 0);
    expect(await db.getTotalXp(), 0);
    expect(await db.watchBookmarks().first, isEmpty);
  });

  test('concurrent daily awards grant XP exactly once', () async {
    final awarded = await Future.wait(List.generate(
        5, (_) => db.awardDailyXp(amount: 50, reason: 'daily_plan_complete')));
    expect(awarded.where((value) => value), hasLength(1));
    expect(await db.getTodayXp(), 50);
    expect(await db.getTotalXp(), 50);
  });

  test('today XP excludes yesterday and tomorrow', () async {
    final now = DateTime.now();
    for (final offset in [-1, 1]) {
      await db.into(db.xpLog).insert(XpLogCompanion.insert(
          reason: 'other',
          amount: 100,
          createdAt: Value(DateTime(now.year, now.month, now.day + offset))));
    }
    await db.awardXp(amount: 25, reason: 'quiz');
    expect(await db.getTodayXp(), 25);
    expect(await db.hasXpForReasonToday('other'), isFalse);
  });

  test('cached surah timestamps can be decoded', () async {
    await db.cacheSurah(1, '{}');
    expect((await db.select(db.quranSurahCache).getSingle()).cachedAt.year,
        DateTime.now().year);
  });

  test('daily plan checkboxes do not inflate lesson statistics', () async {
    await db.updateLessonProgress('lesson', .5, false);
    await db.updateLessonProgress('plan_2026-09-08.quiz', 1, true);
    expect(await db.getCompletedLessonsCount(), 0);
    expect(await db.getAverageAccuracy(), 50);
    expect((await db.getLatestLessonProgress())!.lessonId, 'lesson');
  });

  test('version 2 migration preserves data and removes duplicate identities',
      () async {
    await db.close();
    final legacy =
        db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('PRAGMA user_version = 2');
      raw.execute(
          'CREATE TABLE lesson_progress (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'lesson_id TEXT NOT NULL, completion REAL NOT NULL DEFAULT 0, '
          'is_completed INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL)');
      raw.execute(
          'CREATE TABLE quran_bookmarks (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'surah_number INTEGER NOT NULL, ayah_number INTEGER NOT NULL, saved_at INTEGER NOT NULL)');
      raw.execute('CREATE TABLE xp_log (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'reason TEXT NOT NULL, amount INTEGER NOT NULL, created_at INTEGER NOT NULL)');
      raw.execute(
          'CREATE TABLE quran_surah_cache (surah_number INTEGER PRIMARY KEY, '
          'json_data TEXT NOT NULL, cached_at INTEGER NOT NULL)');
      final date = DateTime.now().toIso8601String();
      raw.execute(
          'INSERT INTO lesson_progress VALUES (1, ?, 1, 1, ?), (2, ?, 0.5, 0, ?)',
          ['lesson', date, 'lesson', date]);
      raw.execute(
          'INSERT INTO quran_bookmarks VALUES (1, 1, 1, ?), (2, 1, 1, ?)',
          [date, date]);
      raw.execute('INSERT INTO xp_log VALUES (1, ?, 50, ?)', ['daily', date]);
      raw.execute(
          'INSERT INTO quran_surah_cache VALUES (1, ?, ?)', ['{}', date]);
    }));
    expect((await legacy.getLatestLessonProgress())!.completion, .5);
    expect(await legacy.getTodayXp(), 50);
    expect(await legacy.isBookmarked(1, 1), isTrue);
    expect(await legacy.getCachedSurahJson(1), '{}');
    await legacy.addBookmark(1, 1);
    expect(await legacy.watchBookmarks().first, hasLength(1));
  });
}
