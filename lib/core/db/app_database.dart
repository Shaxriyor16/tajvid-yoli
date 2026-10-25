import 'package:drift/drift.dart';
import 'connection/unsupported.dart'
    if (dart.library.html) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart';

part 'app_database.g.dart';

@DataClassName('AppUser')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().unique()();
  TextColumn get name => text()();
  TextColumn get photoUrl => text().nullable()();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastActiveAt => dateTime().nullable()();
}

@DataClassName('LessonProgressRow')
class LessonProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ownerUid => text().nullable()();
  TextColumn get lessonId => text()();
  RealColumn get completion => real().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class QuranBookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ownerUid => text().nullable()();
  IntColumn get surahNumber => integer()();
  IntColumn get ayahNumber => integer()();
  DateTimeColumn get savedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('XpLogEntry')
class XpLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ownerUid => text().nullable()();
  TextColumn get reason => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('QuranSurahCacheRow')
class QuranSurahCache extends Table {
  IntColumn get surahNumber => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {surahNumber};
}

@DriftDatabase(
    tables: [Users, LessonProgress, QuranBookmarks, XpLog, QuranSurahCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(super.executor);

  String? _activeUid;

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _createUniqueIndexes();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Ma'lumotlarni SAQLAB qoladigan migratsiya: drift'ning 12 bosqichli
          // alterTable protsedurasi eski qatorlarni yangi sxemaga ko'chiradi.
          // Avval hech bo'lmagan jadval yangidan yaratiladi.
          for (final table in allTables) {
            final name = table.actualTableName;
            final exists = await customSelect(
              'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
              variables: [
                Variable.withString('table'),
                Variable.withString(name),
              ],
            ).getSingleOrNull();
            if (exists == null) {
              await m.createTable(table);
            } else {
              await m.alterTable(TableMigration(table));
            }
          }
        }
        if (from < 3) {
          // Old releases wrote ISO strings into Drift's integer date columns.
          for (final entry in {
            'lesson_progress': 'updated_at',
            'quran_bookmarks': 'saved_at',
            'xp_log': 'created_at',
            'quran_surah_cache': 'cached_at',
          }.entries) {
            final rows = await customSelect(
              'SELECT rowid AS migration_id, ${entry.value} AS legacy_date '
              'FROM ${entry.key} WHERE typeof(${entry.value}) = \'text\'',
            ).get();
            for (final row in rows) {
              final date = DateTime.tryParse(row.read<String>('legacy_date'));
              if (date == null) continue;
              await customStatement(
                'UPDATE ${entry.key} SET ${entry.value} = ? WHERE rowid = ?',
                [
                  date.millisecondsSinceEpoch ~/ 1000,
                  row.read<int>('migration_id')
                ],
              );
            }
          }
          await customStatement('DELETE FROM lesson_progress WHERE id NOT IN '
              '(SELECT MAX(id) FROM lesson_progress GROUP BY lesson_id)');
          await customStatement('DELETE FROM quran_bookmarks WHERE id NOT IN '
              '(SELECT MAX(id) FROM quran_bookmarks GROUP BY surah_number, ayah_number)');
        }
        if (from >= 2 && from < 4) {
          await m.addColumn(lessonProgress, lessonProgress.ownerUid);
          await m.addColumn(quranBookmarks, quranBookmarks.ownerUid);
          await m.addColumn(xpLog, xpLog.ownerUid);
        }
        await customStatement('DROP INDEX IF EXISTS lesson_progress_identity');
        await customStatement(
            'DROP INDEX IF EXISTS lesson_progress_legacy_identity');
        await customStatement('DROP INDEX IF EXISTS bookmark_identity');
        await customStatement('DROP INDEX IF EXISTS bookmark_legacy_identity');
        await _createUniqueIndexes();
      },
    );
  }

  Future<void> _createUniqueIndexes() async {
    await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS lesson_progress_identity '
        'ON lesson_progress (owner_uid, lesson_id) WHERE owner_uid IS NOT NULL');
    await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS lesson_progress_legacy_identity '
        'ON lesson_progress (lesson_id) WHERE owner_uid IS NULL');
    await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS bookmark_identity '
        'ON quran_bookmarks (owner_uid, surah_number, ayah_number) '
        'WHERE owner_uid IS NOT NULL');
    await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS bookmark_legacy_identity '
        'ON quran_bookmarks (surah_number, ayah_number) '
        'WHERE owner_uid IS NULL');
  }

  /// Activates a local account scope and assigns pre-account learning data to
  /// the first signed-in account once. Subsequent accounts only see their rows.
  Future<void> setActiveUser(String? uid) async {
    if (uid == _activeUid) return;
    if (uid != null) {
      await transaction(() async {
        await (update(lessonProgress)..where((row) => row.ownerUid.isNull()))
            .write(LessonProgressCompanion(ownerUid: Value(uid)));
        await (update(quranBookmarks)..where((row) => row.ownerUid.isNull()))
            .write(QuranBookmarksCompanion(ownerUid: Value(uid)));
        await (update(xpLog)..where((row) => row.ownerUid.isNull()))
            .write(XpLogCompanion(ownerUid: Value(uid)));
      });
    }
    _activeUid = uid;
  }

  // User methods
  Future<void> upsertUser(String uid, String name, String? photoUrl) async {
    final existing = await getUser(uid);
    if (existing != null) {
      await (update(users)..where((t) => t.uid.equals(uid))).write(
        UsersCompanion(
          name: Value(name),
          photoUrl: Value(photoUrl),
        ),
      );
    } else {
      await into(users).insert(
        UsersCompanion.insert(
          uid: uid,
          name: name,
          photoUrl: Value(photoUrl),
        ),
      );
    }
  }

  Future<AppUser?> getUser(String uid) =>
      (select(users)..where((t) => t.uid.equals(uid))).getSingleOrNull();

  /// Permanently removes only the deleted account's local learning data.
  Future<void> deleteUserData(String uid) async {
    await transaction(() async {
      await (delete(lessonProgress)..where((row) => row.ownerUid.equals(uid)))
          .go();
      await (delete(quranBookmarks)..where((row) => row.ownerUid.equals(uid)))
          .go();
      await (delete(xpLog)..where((row) => row.ownerUid.equals(uid))).go();
      await (delete(users)..where((row) => row.uid.equals(uid))).go();
      if (_activeUid == uid) _activeUid = null;
    });
  }

  // Progress & Stats
  Future<int> getCompletedLessonsCount() async {
    final ownerFilter =
        _activeUid == null ? 'owner_uid IS NULL' : 'owner_uid = ?';
    final variables = _activeUid == null
        ? const <Variable>[]
        : [Variable.withString(_activeUid!)];
    final result = await customSelect(
      'SELECT COUNT(*) AS c FROM lesson_progress '
      'WHERE $ownerFilter AND is_completed = 1 '
      "AND substr(lesson_id, 1, 5) != 'plan_'",
      variables: variables,
    ).getSingle();
    return result.read<int>('c');
  }

  Future<double> getAverageAccuracy() async {
    final ownerFilter =
        _activeUid == null ? 'owner_uid IS NULL' : 'owner_uid = ?';
    final variables = _activeUid == null
        ? const <Variable>[]
        : [Variable.withString(_activeUid!)];
    final result = await customSelect(
      'SELECT AVG(completion) AS a FROM lesson_progress '
      'WHERE $ownerFilter AND substr(lesson_id, 1, 5) != \'plan_\'',
      variables: variables,
    ).getSingle();
    return (result.read<double?>('a') ?? 0) * 100;
  }

  Future<LessonProgressRow?> getLatestLessonProgress() async {
    final query = select(lessonProgress)
      ..where((row) =>
          const CustomExpression<bool>("substr(lesson_id, 1, 5) != 'plan_'"))
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);
    _applyLessonOwner(query);
    return query.getSingleOrNull();
  }

  void _applyLessonOwner(
      SimpleSelectStatement<$LessonProgressTable, LessonProgressRow> query) {
    query.where((row) => _activeUid == null
        ? row.ownerUid.isNull()
        : row.ownerUid.equals(_activeUid!));
  }

  Future<void> updateLessonProgress(
      String lessonId, double completion, bool isCompleted) async {
    if (lessonId.isEmpty ||
        !completion.isFinite ||
        completion < 0 ||
        completion > 1) {
      throw ArgumentError('Invalid lesson progress');
    }
    await into(lessonProgress).insert(
      LessonProgressCompanion.insert(
        ownerUid: Value(_activeUid),
        lessonId: lessonId,
        completion: Value(completion),
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Kunlik reja vazifalari `plan_<sana>.<taskId>` ko'rinishida saqlanadi.
  /// Berilgan sana uchun bajarilgan vazifa id-larini qaytaradi.
  Future<Set<String>> getCompletedPlanTaskIds(String date) async {
    final query = select(lessonProgress)
      ..where((row) => row.isCompleted & row.lessonId.like('plan_$date.%'));
    _applyLessonOwner(query);
    return (await query.get()).map((row) => row.lessonId).toSet();
  }

  /// Bugun shu sabab bilan XP berilganmi (qayta berilmasligi uchun).
  Future<bool> hasXpForReasonToday(String reason) async {
    return (await (_todayXpQuery()..where((t) => t.reason.equals(reason)))
            .get())
        .isNotEmpty;
  }

  SimpleSelectStatement<$XpLogTable, XpLogEntry> _todayXpQuery() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    return select(xpLog)
      ..where((t) =>
          t.createdAt.isBiggerOrEqualValue(start) &
          t.createdAt.isSmallerThanValue(end) &
          (_activeUid == null
              ? t.ownerUid.isNull()
              : t.ownerUid.equals(_activeUid!)));
  }

  Future<bool> awardDailyXp({required int amount, required String reason}) =>
      transaction(() async {
        if (await hasXpForReasonToday(reason)) return false;
        await awardXp(amount: amount, reason: reason);
        return true;
      });

  Future<void> updateUserLastActive(String uid) async {
    final user = await getUser(uid);
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newStreak = user.streakDays;

    if (user.lastActiveAt != null) {
      final lastActive = user.lastActiveAt!;
      final lastActiveDay =
          DateTime(lastActive.year, lastActive.month, lastActive.day);
      final diff = today.difference(lastActiveDay).inDays;

      if (diff == 1) {
        newStreak++;
      } else if (diff > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    await (update(users)..where((t) => t.uid.equals(uid))).write(
      UsersCompanion(
        lastActiveAt: Value(now),
        streakDays: Value(newStreak),
      ),
    );
  }

  Future<int> getStreak(String uid) async {
    final user = await getUser(uid);
    if (user == null || user.lastActiveAt == null) return 0;

    final now = DateTime.now();
    final lastActive = user.lastActiveAt!;
    final difference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastActive.year, lastActive.month, lastActive.day))
        .inDays;

    if (difference <= 1) {
      return user.streakDays;
    } else {
      return 0;
    }
  }

  // Bookmarks
  Stream<List<QuranBookmark>> watchBookmarks() {
    final query = select(quranBookmarks)
      ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]);
    _applyBookmarkOwner(query);
    return query.watch();
  }

  void _applyBookmarkOwner(
      SimpleSelectStatement<$QuranBookmarksTable, QuranBookmark> query) {
    query.where((row) => _activeUid == null
        ? row.ownerUid.isNull()
        : row.ownerUid.equals(_activeUid!));
  }

  Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    final query = select(quranBookmarks)
      ..where((t) =>
          t.surahNumber.equals(surahNumber) & t.ayahNumber.equals(ayahNumber));
    _applyBookmarkOwner(query);
    final row = await query.getSingleOrNull();
    return row != null;
  }

  Future<void> addBookmark(int surahNumber, int ayahNumber) async {
    await into(quranBookmarks).insert(
      QuranBookmarksCompanion.insert(
          ownerUid: Value(_activeUid),
          surahNumber: surahNumber,
          ayahNumber: ayahNumber),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final query = delete(quranBookmarks)
      ..where((t) =>
          t.surahNumber.equals(surahNumber) &
          t.ayahNumber.equals(ayahNumber) &
          (_activeUid == null
              ? t.ownerUid.isNull()
              : t.ownerUid.equals(_activeUid!)));
    await query.go();
  }

  // XP
  Future<void> awardXp({required int amount, required String reason}) async {
    if (amount <= 0 || reason.isEmpty) throw ArgumentError('Invalid XP award');
    await into(xpLog).insert(XpLogCompanion.insert(
        ownerUid: Value(_activeUid), reason: reason, amount: amount));
  }

  Future<int> getTotalXp() async {
    final rows = await (select(xpLog)
          ..where((row) => _activeUid == null
              ? row.ownerUid.isNull()
              : row.ownerUid.equals(_activeUid!)))
        .get();
    return rows.fold<int>(0, (total, row) => total + row.amount);
  }

  Future<int> getTodayXp() async {
    final rows = await _todayXpQuery().get();
    return rows.fold<int>(0, (total, row) => total + row.amount);
  }

  // Caching
  Future<void> cacheSurah(int surahNumber, String jsonData) async {
    await into(quranSurahCache).insertOnConflictUpdate(
      QuranSurahCacheCompanion.insert(
          surahNumber: Value(surahNumber),
          jsonData: jsonData,
          cachedAt: Value(DateTime.now())),
    );
  }

  Future<String?> getCachedSurahJson(int surahNumber) async {
    final row = await (select(quranSurahCache)
          ..where((t) => t.surahNumber.equals(surahNumber)))
        .getSingleOrNull();
    return row?.jsonData;
  }
}
