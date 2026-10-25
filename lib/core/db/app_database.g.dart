// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, AppUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
      'xp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _streakDaysMeta =
      const VerificationMeta('streakDays');
  @override
  late final GeneratedColumn<int> streakDays = GeneratedColumn<int>(
      'streak_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastActiveAtMeta =
      const VerificationMeta('lastActiveAt');
  @override
  late final GeneratedColumn<DateTime> lastActiveAt = GeneratedColumn<DateTime>(
      'last_active_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, uid, name, photoUrl, xp, streakDays, lastActiveAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<AppUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    if (data.containsKey('streak_days')) {
      context.handle(
          _streakDaysMeta,
          streakDays.isAcceptableOrUnknown(
              data['streak_days']!, _streakDaysMeta));
    }
    if (data.containsKey('last_active_at')) {
      context.handle(
          _lastActiveAtMeta,
          lastActiveAt.isAcceptableOrUnknown(
              data['last_active_at']!, _lastActiveAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppUser(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
      xp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp'])!,
      streakDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}streak_days'])!,
      lastActiveAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_active_at']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class AppUser extends DataClass implements Insertable<AppUser> {
  final int id;
  final String uid;
  final String name;
  final String? photoUrl;
  final int xp;
  final int streakDays;
  final DateTime? lastActiveAt;
  const AppUser(
      {required this.id,
      required this.uid,
      required this.name,
      this.photoUrl,
      required this.xp,
      required this.streakDays,
      this.lastActiveAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['xp'] = Variable<int>(xp);
    map['streak_days'] = Variable<int>(streakDays);
    if (!nullToAbsent || lastActiveAt != null) {
      map['last_active_at'] = Variable<DateTime>(lastActiveAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      uid: Value(uid),
      name: Value(name),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      xp: Value(xp),
      streakDays: Value(streakDays),
      lastActiveAt: lastActiveAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActiveAt),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppUser(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      xp: serializer.fromJson<int>(json['xp']),
      streakDays: serializer.fromJson<int>(json['streakDays']),
      lastActiveAt: serializer.fromJson<DateTime?>(json['lastActiveAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'xp': serializer.toJson<int>(xp),
      'streakDays': serializer.toJson<int>(streakDays),
      'lastActiveAt': serializer.toJson<DateTime?>(lastActiveAt),
    };
  }

  AppUser copyWith(
          {int? id,
          String? uid,
          String? name,
          Value<String?> photoUrl = const Value.absent(),
          int? xp,
          int? streakDays,
          Value<DateTime?> lastActiveAt = const Value.absent()}) =>
      AppUser(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        name: name ?? this.name,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
        xp: xp ?? this.xp,
        streakDays: streakDays ?? this.streakDays,
        lastActiveAt:
            lastActiveAt.present ? lastActiveAt.value : this.lastActiveAt,
      );
  AppUser copyWithCompanion(UsersCompanion data) {
    return AppUser(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      xp: data.xp.present ? data.xp.value : this.xp,
      streakDays:
          data.streakDays.present ? data.streakDays.value : this.streakDays,
      lastActiveAt: data.lastActiveAt.present
          ? data.lastActiveAt.value
          : this.lastActiveAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppUser(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('xp: $xp, ')
          ..write('streakDays: $streakDays, ')
          ..write('lastActiveAt: $lastActiveAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uid, name, photoUrl, xp, streakDays, lastActiveAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUser &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.photoUrl == this.photoUrl &&
          other.xp == this.xp &&
          other.streakDays == this.streakDays &&
          other.lastActiveAt == this.lastActiveAt);
}

class UsersCompanion extends UpdateCompanion<AppUser> {
  final Value<int> id;
  final Value<String> uid;
  final Value<String> name;
  final Value<String?> photoUrl;
  final Value<int> xp;
  final Value<int> streakDays;
  final Value<DateTime?> lastActiveAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.xp = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.lastActiveAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required String name,
    this.photoUrl = const Value.absent(),
    this.xp = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.lastActiveAt = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name);
  static Insertable<AppUser> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? photoUrl,
    Expression<int>? xp,
    Expression<int>? streakDays,
    Expression<DateTime>? lastActiveAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (xp != null) 'xp': xp,
      if (streakDays != null) 'streak_days': streakDays,
      if (lastActiveAt != null) 'last_active_at': lastActiveAt,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? uid,
      Value<String>? name,
      Value<String?>? photoUrl,
      Value<int>? xp,
      Value<int>? streakDays,
      Value<DateTime?>? lastActiveAt}) {
    return UsersCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (streakDays.present) {
      map['streak_days'] = Variable<int>(streakDays.value);
    }
    if (lastActiveAt.present) {
      map['last_active_at'] = Variable<DateTime>(lastActiveAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('xp: $xp, ')
          ..write('streakDays: $streakDays, ')
          ..write('lastActiveAt: $lastActiveAt')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressTable extends LessonProgress
    with TableInfo<$LessonProgressTable, LessonProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _ownerUidMeta =
      const VerificationMeta('ownerUid');
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
      'owner_uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completionMeta =
      const VerificationMeta('completion');
  @override
  late final GeneratedColumn<double> completion = GeneratedColumn<double>(
      'completion', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, ownerUid, lessonId, completion, isCompleted, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress';
  @override
  VerificationContext validateIntegrity(Insertable<LessonProgressRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_uid')) {
      context.handle(_ownerUidMeta,
          ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta));
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('completion')) {
      context.handle(
          _completionMeta,
          completion.isAcceptableOrUnknown(
              data['completion']!, _completionMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ownerUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_uid']),
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      completion: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}completion'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LessonProgressTable createAlias(String alias) {
    return $LessonProgressTable(attachedDatabase, alias);
  }
}

class LessonProgressRow extends DataClass
    implements Insertable<LessonProgressRow> {
  final int id;
  final String? ownerUid;
  final String lessonId;
  final double completion;
  final bool isCompleted;
  final DateTime updatedAt;
  const LessonProgressRow(
      {required this.id,
      this.ownerUid,
      required this.lessonId,
      required this.completion,
      required this.isCompleted,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || ownerUid != null) {
      map['owner_uid'] = Variable<String>(ownerUid);
    }
    map['lesson_id'] = Variable<String>(lessonId);
    map['completion'] = Variable<double>(completion);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LessonProgressCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressCompanion(
      id: Value(id),
      ownerUid: ownerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUid),
      lessonId: Value(lessonId),
      completion: Value(completion),
      isCompleted: Value(isCompleted),
      updatedAt: Value(updatedAt),
    );
  }

  factory LessonProgressRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressRow(
      id: serializer.fromJson<int>(json['id']),
      ownerUid: serializer.fromJson<String?>(json['ownerUid']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      completion: serializer.fromJson<double>(json['completion']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerUid': serializer.toJson<String?>(ownerUid),
      'lessonId': serializer.toJson<String>(lessonId),
      'completion': serializer.toJson<double>(completion),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LessonProgressRow copyWith(
          {int? id,
          Value<String?> ownerUid = const Value.absent(),
          String? lessonId,
          double? completion,
          bool? isCompleted,
          DateTime? updatedAt}) =>
      LessonProgressRow(
        id: id ?? this.id,
        ownerUid: ownerUid.present ? ownerUid.value : this.ownerUid,
        lessonId: lessonId ?? this.lessonId,
        completion: completion ?? this.completion,
        isCompleted: isCompleted ?? this.isCompleted,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LessonProgressRow copyWithCompanion(LessonProgressCompanion data) {
    return LessonProgressRow(
      id: data.id.present ? data.id.value : this.id,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      completion:
          data.completion.present ? data.completion.value : this.completion,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressRow(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('lessonId: $lessonId, ')
          ..write('completion: $completion, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ownerUid, lessonId, completion, isCompleted, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressRow &&
          other.id == this.id &&
          other.ownerUid == this.ownerUid &&
          other.lessonId == this.lessonId &&
          other.completion == this.completion &&
          other.isCompleted == this.isCompleted &&
          other.updatedAt == this.updatedAt);
}

class LessonProgressCompanion extends UpdateCompanion<LessonProgressRow> {
  final Value<int> id;
  final Value<String?> ownerUid;
  final Value<String> lessonId;
  final Value<double> completion;
  final Value<bool> isCompleted;
  final Value<DateTime> updatedAt;
  const LessonProgressCompanion({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.completion = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LessonProgressCompanion.insert({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    required String lessonId,
    this.completion = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : lessonId = Value(lessonId);
  static Insertable<LessonProgressRow> custom({
    Expression<int>? id,
    Expression<String>? ownerUid,
    Expression<String>? lessonId,
    Expression<double>? completion,
    Expression<bool>? isCompleted,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (lessonId != null) 'lesson_id': lessonId,
      if (completion != null) 'completion': completion,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LessonProgressCompanion copyWith(
      {Value<int>? id,
      Value<String?>? ownerUid,
      Value<String>? lessonId,
      Value<double>? completion,
      Value<bool>? isCompleted,
      Value<DateTime>? updatedAt}) {
    return LessonProgressCompanion(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      lessonId: lessonId ?? this.lessonId,
      completion: completion ?? this.completion,
      isCompleted: isCompleted ?? this.isCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (completion.present) {
      map['completion'] = Variable<double>(completion.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressCompanion(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('lessonId: $lessonId, ')
          ..write('completion: $completion, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $QuranBookmarksTable extends QuranBookmarks
    with TableInfo<$QuranBookmarksTable, QuranBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _ownerUidMeta =
      const VerificationMeta('ownerUid');
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
      'owner_uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _surahNumberMeta =
      const VerificationMeta('surahNumber');
  @override
  late final GeneratedColumn<int> surahNumber = GeneratedColumn<int>(
      'surah_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ayahNumberMeta =
      const VerificationMeta('ayahNumber');
  @override
  late final GeneratedColumn<int> ayahNumber = GeneratedColumn<int>(
      'ayah_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, ownerUid, surahNumber, ayahNumber, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<QuranBookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_uid')) {
      context.handle(_ownerUidMeta,
          ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta));
    }
    if (data.containsKey('surah_number')) {
      context.handle(
          _surahNumberMeta,
          surahNumber.isAcceptableOrUnknown(
              data['surah_number']!, _surahNumberMeta));
    } else if (isInserting) {
      context.missing(_surahNumberMeta);
    }
    if (data.containsKey('ayah_number')) {
      context.handle(
          _ayahNumberMeta,
          ayahNumber.isAcceptableOrUnknown(
              data['ayah_number']!, _ayahNumberMeta));
    } else if (isInserting) {
      context.missing(_ayahNumberMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta,
          savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuranBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranBookmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ownerUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_uid']),
      surahNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_number'])!,
      ayahNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ayah_number'])!,
      savedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $QuranBookmarksTable createAlias(String alias) {
    return $QuranBookmarksTable(attachedDatabase, alias);
  }
}

class QuranBookmark extends DataClass implements Insertable<QuranBookmark> {
  final int id;
  final String? ownerUid;
  final int surahNumber;
  final int ayahNumber;
  final DateTime savedAt;
  const QuranBookmark(
      {required this.id,
      this.ownerUid,
      required this.surahNumber,
      required this.ayahNumber,
      required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || ownerUid != null) {
      map['owner_uid'] = Variable<String>(ownerUid);
    }
    map['surah_number'] = Variable<int>(surahNumber);
    map['ayah_number'] = Variable<int>(ayahNumber);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  QuranBookmarksCompanion toCompanion(bool nullToAbsent) {
    return QuranBookmarksCompanion(
      id: Value(id),
      ownerUid: ownerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUid),
      surahNumber: Value(surahNumber),
      ayahNumber: Value(ayahNumber),
      savedAt: Value(savedAt),
    );
  }

  factory QuranBookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranBookmark(
      id: serializer.fromJson<int>(json['id']),
      ownerUid: serializer.fromJson<String?>(json['ownerUid']),
      surahNumber: serializer.fromJson<int>(json['surahNumber']),
      ayahNumber: serializer.fromJson<int>(json['ayahNumber']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerUid': serializer.toJson<String?>(ownerUid),
      'surahNumber': serializer.toJson<int>(surahNumber),
      'ayahNumber': serializer.toJson<int>(ayahNumber),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  QuranBookmark copyWith(
          {int? id,
          Value<String?> ownerUid = const Value.absent(),
          int? surahNumber,
          int? ayahNumber,
          DateTime? savedAt}) =>
      QuranBookmark(
        id: id ?? this.id,
        ownerUid: ownerUid.present ? ownerUid.value : this.ownerUid,
        surahNumber: surahNumber ?? this.surahNumber,
        ayahNumber: ayahNumber ?? this.ayahNumber,
        savedAt: savedAt ?? this.savedAt,
      );
  QuranBookmark copyWithCompanion(QuranBookmarksCompanion data) {
    return QuranBookmark(
      id: data.id.present ? data.id.value : this.id,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      surahNumber:
          data.surahNumber.present ? data.surahNumber.value : this.surahNumber,
      ayahNumber:
          data.ayahNumber.present ? data.ayahNumber.value : this.ayahNumber,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranBookmark(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ownerUid, surahNumber, ayahNumber, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranBookmark &&
          other.id == this.id &&
          other.ownerUid == this.ownerUid &&
          other.surahNumber == this.surahNumber &&
          other.ayahNumber == this.ayahNumber &&
          other.savedAt == this.savedAt);
}

class QuranBookmarksCompanion extends UpdateCompanion<QuranBookmark> {
  final Value<int> id;
  final Value<String?> ownerUid;
  final Value<int> surahNumber;
  final Value<int> ayahNumber;
  final Value<DateTime> savedAt;
  const QuranBookmarksCompanion({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.surahNumber = const Value.absent(),
    this.ayahNumber = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  QuranBookmarksCompanion.insert({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    required int surahNumber,
    required int ayahNumber,
    this.savedAt = const Value.absent(),
  })  : surahNumber = Value(surahNumber),
        ayahNumber = Value(ayahNumber);
  static Insertable<QuranBookmark> custom({
    Expression<int>? id,
    Expression<String>? ownerUid,
    Expression<int>? surahNumber,
    Expression<int>? ayahNumber,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (surahNumber != null) 'surah_number': surahNumber,
      if (ayahNumber != null) 'ayah_number': ayahNumber,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  QuranBookmarksCompanion copyWith(
      {Value<int>? id,
      Value<String?>? ownerUid,
      Value<int>? surahNumber,
      Value<int>? ayahNumber,
      Value<DateTime>? savedAt}) {
    return QuranBookmarksCompanion(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (surahNumber.present) {
      map['surah_number'] = Variable<int>(surahNumber.value);
    }
    if (ayahNumber.present) {
      map['ayah_number'] = Variable<int>(ayahNumber.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

class $XpLogTable extends XpLog with TableInfo<$XpLogTable, XpLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $XpLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _ownerUidMeta =
      const VerificationMeta('ownerUid');
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
      'owner_uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, ownerUid, reason, amount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'xp_log';
  @override
  VerificationContext validateIntegrity(Insertable<XpLogEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_uid')) {
      context.handle(_ownerUidMeta,
          ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  XpLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return XpLogEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ownerUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_uid']),
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $XpLogTable createAlias(String alias) {
    return $XpLogTable(attachedDatabase, alias);
  }
}

class XpLogEntry extends DataClass implements Insertable<XpLogEntry> {
  final int id;
  final String? ownerUid;
  final String reason;
  final int amount;
  final DateTime createdAt;
  const XpLogEntry(
      {required this.id,
      this.ownerUid,
      required this.reason,
      required this.amount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || ownerUid != null) {
      map['owner_uid'] = Variable<String>(ownerUid);
    }
    map['reason'] = Variable<String>(reason);
    map['amount'] = Variable<int>(amount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  XpLogCompanion toCompanion(bool nullToAbsent) {
    return XpLogCompanion(
      id: Value(id),
      ownerUid: ownerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUid),
      reason: Value(reason),
      amount: Value(amount),
      createdAt: Value(createdAt),
    );
  }

  factory XpLogEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return XpLogEntry(
      id: serializer.fromJson<int>(json['id']),
      ownerUid: serializer.fromJson<String?>(json['ownerUid']),
      reason: serializer.fromJson<String>(json['reason']),
      amount: serializer.fromJson<int>(json['amount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerUid': serializer.toJson<String?>(ownerUid),
      'reason': serializer.toJson<String>(reason),
      'amount': serializer.toJson<int>(amount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  XpLogEntry copyWith(
          {int? id,
          Value<String?> ownerUid = const Value.absent(),
          String? reason,
          int? amount,
          DateTime? createdAt}) =>
      XpLogEntry(
        id: id ?? this.id,
        ownerUid: ownerUid.present ? ownerUid.value : this.ownerUid,
        reason: reason ?? this.reason,
        amount: amount ?? this.amount,
        createdAt: createdAt ?? this.createdAt,
      );
  XpLogEntry copyWithCompanion(XpLogCompanion data) {
    return XpLogEntry(
      id: data.id.present ? data.id.value : this.id,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      reason: data.reason.present ? data.reason.value : this.reason,
      amount: data.amount.present ? data.amount.value : this.amount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('XpLogEntry(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('reason: $reason, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ownerUid, reason, amount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is XpLogEntry &&
          other.id == this.id &&
          other.ownerUid == this.ownerUid &&
          other.reason == this.reason &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt);
}

class XpLogCompanion extends UpdateCompanion<XpLogEntry> {
  final Value<int> id;
  final Value<String?> ownerUid;
  final Value<String> reason;
  final Value<int> amount;
  final Value<DateTime> createdAt;
  const XpLogCompanion({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.reason = const Value.absent(),
    this.amount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  XpLogCompanion.insert({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    required String reason,
    required int amount,
    this.createdAt = const Value.absent(),
  })  : reason = Value(reason),
        amount = Value(amount);
  static Insertable<XpLogEntry> custom({
    Expression<int>? id,
    Expression<String>? ownerUid,
    Expression<String>? reason,
    Expression<int>? amount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (reason != null) 'reason': reason,
      if (amount != null) 'amount': amount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  XpLogCompanion copyWith(
      {Value<int>? id,
      Value<String?>? ownerUid,
      Value<String>? reason,
      Value<int>? amount,
      Value<DateTime>? createdAt}) {
    return XpLogCompanion(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      reason: reason ?? this.reason,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('XpLogCompanion(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('reason: $reason, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QuranSurahCacheTable extends QuranSurahCache
    with TableInfo<$QuranSurahCacheTable, QuranSurahCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranSurahCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahNumberMeta =
      const VerificationMeta('surahNumber');
  @override
  late final GeneratedColumn<int> surahNumber = GeneratedColumn<int>(
      'surah_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _jsonDataMeta =
      const VerificationMeta('jsonData');
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
      'json_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [surahNumber, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_surah_cache';
  @override
  VerificationContext validateIntegrity(Insertable<QuranSurahCacheRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah_number')) {
      context.handle(
          _surahNumberMeta,
          surahNumber.isAcceptableOrUnknown(
              data['surah_number']!, _surahNumberMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(_jsonDataMeta,
          jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta));
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surahNumber};
  @override
  QuranSurahCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranSurahCacheRow(
      surahNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_number'])!,
      jsonData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json_data'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $QuranSurahCacheTable createAlias(String alias) {
    return $QuranSurahCacheTable(attachedDatabase, alias);
  }
}

class QuranSurahCacheRow extends DataClass
    implements Insertable<QuranSurahCacheRow> {
  final int surahNumber;
  final String jsonData;
  final DateTime cachedAt;
  const QuranSurahCacheRow(
      {required this.surahNumber,
      required this.jsonData,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah_number'] = Variable<int>(surahNumber);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  QuranSurahCacheCompanion toCompanion(bool nullToAbsent) {
    return QuranSurahCacheCompanion(
      surahNumber: Value(surahNumber),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory QuranSurahCacheRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranSurahCacheRow(
      surahNumber: serializer.fromJson<int>(json['surahNumber']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surahNumber': serializer.toJson<int>(surahNumber),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  QuranSurahCacheRow copyWith(
          {int? surahNumber, String? jsonData, DateTime? cachedAt}) =>
      QuranSurahCacheRow(
        surahNumber: surahNumber ?? this.surahNumber,
        jsonData: jsonData ?? this.jsonData,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  QuranSurahCacheRow copyWithCompanion(QuranSurahCacheCompanion data) {
    return QuranSurahCacheRow(
      surahNumber:
          data.surahNumber.present ? data.surahNumber.value : this.surahNumber,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranSurahCacheRow(')
          ..write('surahNumber: $surahNumber, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surahNumber, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranSurahCacheRow &&
          other.surahNumber == this.surahNumber &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class QuranSurahCacheCompanion extends UpdateCompanion<QuranSurahCacheRow> {
  final Value<int> surahNumber;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const QuranSurahCacheCompanion({
    this.surahNumber = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  QuranSurahCacheCompanion.insert({
    this.surahNumber = const Value.absent(),
    required String jsonData,
    this.cachedAt = const Value.absent(),
  }) : jsonData = Value(jsonData);
  static Insertable<QuranSurahCacheRow> custom({
    Expression<int>? surahNumber,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (surahNumber != null) 'surah_number': surahNumber,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  QuranSurahCacheCompanion copyWith(
      {Value<int>? surahNumber,
      Value<String>? jsonData,
      Value<DateTime>? cachedAt}) {
    return QuranSurahCacheCompanion(
      surahNumber: surahNumber ?? this.surahNumber,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surahNumber.present) {
      map['surah_number'] = Variable<int>(surahNumber.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranSurahCacheCompanion(')
          ..write('surahNumber: $surahNumber, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $LessonProgressTable lessonProgress = $LessonProgressTable(this);
  late final $QuranBookmarksTable quranBookmarks = $QuranBookmarksTable(this);
  late final $XpLogTable xpLog = $XpLogTable(this);
  late final $QuranSurahCacheTable quranSurahCache =
      $QuranSurahCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [users, lessonProgress, quranBookmarks, xpLog, quranSurahCache];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String uid,
  required String name,
  Value<String?> photoUrl,
  Value<int> xp,
  Value<int> streakDays,
  Value<DateTime?> lastActiveAt,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> uid,
  Value<String> name,
  Value<String?> photoUrl,
  Value<int> xp,
  Value<int> streakDays,
  Value<DateTime?> lastActiveAt,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xp => $composableBuilder(
      column: $table.xp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get streakDays => $composableBuilder(
      column: $table.streakDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastActiveAt => $composableBuilder(
      column: $table.lastActiveAt, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xp => $composableBuilder(
      column: $table.xp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get streakDays => $composableBuilder(
      column: $table.streakDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastActiveAt => $composableBuilder(
      column: $table.lastActiveAt,
      builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<int> get streakDays => $composableBuilder(
      column: $table.streakDays, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActiveAt => $composableBuilder(
      column: $table.lastActiveAt, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    AppUser,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (AppUser, BaseReferences<_$AppDatabase, $UsersTable, AppUser>),
    AppUser,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<int> xp = const Value.absent(),
            Value<int> streakDays = const Value.absent(),
            Value<DateTime?> lastActiveAt = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            uid: uid,
            name: name,
            photoUrl: photoUrl,
            xp: xp,
            streakDays: streakDays,
            lastActiveAt: lastActiveAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uid,
            required String name,
            Value<String?> photoUrl = const Value.absent(),
            Value<int> xp = const Value.absent(),
            Value<int> streakDays = const Value.absent(),
            Value<DateTime?> lastActiveAt = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            uid: uid,
            name: name,
            photoUrl: photoUrl,
            xp: xp,
            streakDays: streakDays,
            lastActiveAt: lastActiveAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    AppUser,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (AppUser, BaseReferences<_$AppDatabase, $UsersTable, AppUser>),
    AppUser,
    PrefetchHooks Function()>;
typedef $$LessonProgressTableCreateCompanionBuilder = LessonProgressCompanion
    Function({
  Value<int> id,
  Value<String?> ownerUid,
  required String lessonId,
  Value<double> completion,
  Value<bool> isCompleted,
  Value<DateTime> updatedAt,
});
typedef $$LessonProgressTableUpdateCompanionBuilder = LessonProgressCompanion
    Function({
  Value<int> id,
  Value<String?> ownerUid,
  Value<String> lessonId,
  Value<double> completion,
  Value<bool> isCompleted,
  Value<DateTime> updatedAt,
});

class $$LessonProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerUid => $composableBuilder(
      column: $table.ownerUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get completion => $composableBuilder(
      column: $table.completion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LessonProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerUid => $composableBuilder(
      column: $table.ownerUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get completion => $composableBuilder(
      column: $table.completion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LessonProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerUid =>
      $composableBuilder(column: $table.ownerUid, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<double> get completion => $composableBuilder(
      column: $table.completion, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LessonProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonProgressTable,
    LessonProgressRow,
    $$LessonProgressTableFilterComposer,
    $$LessonProgressTableOrderingComposer,
    $$LessonProgressTableAnnotationComposer,
    $$LessonProgressTableCreateCompanionBuilder,
    $$LessonProgressTableUpdateCompanionBuilder,
    (
      LessonProgressRow,
      BaseReferences<_$AppDatabase, $LessonProgressTable, LessonProgressRow>
    ),
    LessonProgressRow,
    PrefetchHooks Function()> {
  $$LessonProgressTableTableManager(
      _$AppDatabase db, $LessonProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> ownerUid = const Value.absent(),
            Value<String> lessonId = const Value.absent(),
            Value<double> completion = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LessonProgressCompanion(
            id: id,
            ownerUid: ownerUid,
            lessonId: lessonId,
            completion: completion,
            isCompleted: isCompleted,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> ownerUid = const Value.absent(),
            required String lessonId,
            Value<double> completion = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LessonProgressCompanion.insert(
            id: id,
            ownerUid: ownerUid,
            lessonId: lessonId,
            completion: completion,
            isCompleted: isCompleted,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LessonProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LessonProgressTable,
    LessonProgressRow,
    $$LessonProgressTableFilterComposer,
    $$LessonProgressTableOrderingComposer,
    $$LessonProgressTableAnnotationComposer,
    $$LessonProgressTableCreateCompanionBuilder,
    $$LessonProgressTableUpdateCompanionBuilder,
    (
      LessonProgressRow,
      BaseReferences<_$AppDatabase, $LessonProgressTable, LessonProgressRow>
    ),
    LessonProgressRow,
    PrefetchHooks Function()>;
typedef $$QuranBookmarksTableCreateCompanionBuilder = QuranBookmarksCompanion
    Function({
  Value<int> id,
  Value<String?> ownerUid,
  required int surahNumber,
  required int ayahNumber,
  Value<DateTime> savedAt,
});
typedef $$QuranBookmarksTableUpdateCompanionBuilder = QuranBookmarksCompanion
    Function({
  Value<int> id,
  Value<String?> ownerUid,
  Value<int> surahNumber,
  Value<int> ayahNumber,
  Value<DateTime> savedAt,
});

class $$QuranBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $QuranBookmarksTable> {
  $$QuranBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerUid => $composableBuilder(
      column: $table.ownerUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayahNumber => $composableBuilder(
      column: $table.ayahNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$QuranBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $QuranBookmarksTable> {
  $$QuranBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerUid => $composableBuilder(
      column: $table.ownerUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayahNumber => $composableBuilder(
      column: $table.ayahNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuranBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuranBookmarksTable> {
  $$QuranBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerUid =>
      $composableBuilder(column: $table.ownerUid, builder: (column) => column);

  GeneratedColumn<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => column);

  GeneratedColumn<int> get ayahNumber => $composableBuilder(
      column: $table.ayahNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$QuranBookmarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuranBookmarksTable,
    QuranBookmark,
    $$QuranBookmarksTableFilterComposer,
    $$QuranBookmarksTableOrderingComposer,
    $$QuranBookmarksTableAnnotationComposer,
    $$QuranBookmarksTableCreateCompanionBuilder,
    $$QuranBookmarksTableUpdateCompanionBuilder,
    (
      QuranBookmark,
      BaseReferences<_$AppDatabase, $QuranBookmarksTable, QuranBookmark>
    ),
    QuranBookmark,
    PrefetchHooks Function()> {
  $$QuranBookmarksTableTableManager(
      _$AppDatabase db, $QuranBookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuranBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranBookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> ownerUid = const Value.absent(),
            Value<int> surahNumber = const Value.absent(),
            Value<int> ayahNumber = const Value.absent(),
            Value<DateTime> savedAt = const Value.absent(),
          }) =>
              QuranBookmarksCompanion(
            id: id,
            ownerUid: ownerUid,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            savedAt: savedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> ownerUid = const Value.absent(),
            required int surahNumber,
            required int ayahNumber,
            Value<DateTime> savedAt = const Value.absent(),
          }) =>
              QuranBookmarksCompanion.insert(
            id: id,
            ownerUid: ownerUid,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            savedAt: savedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuranBookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuranBookmarksTable,
    QuranBookmark,
    $$QuranBookmarksTableFilterComposer,
    $$QuranBookmarksTableOrderingComposer,
    $$QuranBookmarksTableAnnotationComposer,
    $$QuranBookmarksTableCreateCompanionBuilder,
    $$QuranBookmarksTableUpdateCompanionBuilder,
    (
      QuranBookmark,
      BaseReferences<_$AppDatabase, $QuranBookmarksTable, QuranBookmark>
    ),
    QuranBookmark,
    PrefetchHooks Function()>;
typedef $$XpLogTableCreateCompanionBuilder = XpLogCompanion Function({
  Value<int> id,
  Value<String?> ownerUid,
  required String reason,
  required int amount,
  Value<DateTime> createdAt,
});
typedef $$XpLogTableUpdateCompanionBuilder = XpLogCompanion Function({
  Value<int> id,
  Value<String?> ownerUid,
  Value<String> reason,
  Value<int> amount,
  Value<DateTime> createdAt,
});

class $$XpLogTableFilterComposer extends Composer<_$AppDatabase, $XpLogTable> {
  $$XpLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerUid => $composableBuilder(
      column: $table.ownerUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$XpLogTableOrderingComposer
    extends Composer<_$AppDatabase, $XpLogTable> {
  $$XpLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerUid => $composableBuilder(
      column: $table.ownerUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$XpLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $XpLogTable> {
  $$XpLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerUid =>
      $composableBuilder(column: $table.ownerUid, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$XpLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $XpLogTable,
    XpLogEntry,
    $$XpLogTableFilterComposer,
    $$XpLogTableOrderingComposer,
    $$XpLogTableAnnotationComposer,
    $$XpLogTableCreateCompanionBuilder,
    $$XpLogTableUpdateCompanionBuilder,
    (XpLogEntry, BaseReferences<_$AppDatabase, $XpLogTable, XpLogEntry>),
    XpLogEntry,
    PrefetchHooks Function()> {
  $$XpLogTableTableManager(_$AppDatabase db, $XpLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$XpLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$XpLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$XpLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> ownerUid = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              XpLogCompanion(
            id: id,
            ownerUid: ownerUid,
            reason: reason,
            amount: amount,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> ownerUid = const Value.absent(),
            required String reason,
            required int amount,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              XpLogCompanion.insert(
            id: id,
            ownerUid: ownerUid,
            reason: reason,
            amount: amount,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$XpLogTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $XpLogTable,
    XpLogEntry,
    $$XpLogTableFilterComposer,
    $$XpLogTableOrderingComposer,
    $$XpLogTableAnnotationComposer,
    $$XpLogTableCreateCompanionBuilder,
    $$XpLogTableUpdateCompanionBuilder,
    (XpLogEntry, BaseReferences<_$AppDatabase, $XpLogTable, XpLogEntry>),
    XpLogEntry,
    PrefetchHooks Function()>;
typedef $$QuranSurahCacheTableCreateCompanionBuilder = QuranSurahCacheCompanion
    Function({
  Value<int> surahNumber,
  required String jsonData,
  Value<DateTime> cachedAt,
});
typedef $$QuranSurahCacheTableUpdateCompanionBuilder = QuranSurahCacheCompanion
    Function({
  Value<int> surahNumber,
  Value<String> jsonData,
  Value<DateTime> cachedAt,
});

class $$QuranSurahCacheTableFilterComposer
    extends Composer<_$AppDatabase, $QuranSurahCacheTable> {
  $$QuranSurahCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jsonData => $composableBuilder(
      column: $table.jsonData, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$QuranSurahCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $QuranSurahCacheTable> {
  $$QuranSurahCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jsonData => $composableBuilder(
      column: $table.jsonData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuranSurahCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuranSurahCacheTable> {
  $$QuranSurahCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$QuranSurahCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuranSurahCacheTable,
    QuranSurahCacheRow,
    $$QuranSurahCacheTableFilterComposer,
    $$QuranSurahCacheTableOrderingComposer,
    $$QuranSurahCacheTableAnnotationComposer,
    $$QuranSurahCacheTableCreateCompanionBuilder,
    $$QuranSurahCacheTableUpdateCompanionBuilder,
    (
      QuranSurahCacheRow,
      BaseReferences<_$AppDatabase, $QuranSurahCacheTable, QuranSurahCacheRow>
    ),
    QuranSurahCacheRow,
    PrefetchHooks Function()> {
  $$QuranSurahCacheTableTableManager(
      _$AppDatabase db, $QuranSurahCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuranSurahCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranSurahCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranSurahCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> surahNumber = const Value.absent(),
            Value<String> jsonData = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              QuranSurahCacheCompanion(
            surahNumber: surahNumber,
            jsonData: jsonData,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> surahNumber = const Value.absent(),
            required String jsonData,
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              QuranSurahCacheCompanion.insert(
            surahNumber: surahNumber,
            jsonData: jsonData,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuranSurahCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuranSurahCacheTable,
    QuranSurahCacheRow,
    $$QuranSurahCacheTableFilterComposer,
    $$QuranSurahCacheTableOrderingComposer,
    $$QuranSurahCacheTableAnnotationComposer,
    $$QuranSurahCacheTableCreateCompanionBuilder,
    $$QuranSurahCacheTableUpdateCompanionBuilder,
    (
      QuranSurahCacheRow,
      BaseReferences<_$AppDatabase, $QuranSurahCacheTable, QuranSurahCacheRow>
    ),
    QuranSurahCacheRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$LessonProgressTableTableManager get lessonProgress =>
      $$LessonProgressTableTableManager(_db, _db.lessonProgress);
  $$QuranBookmarksTableTableManager get quranBookmarks =>
      $$QuranBookmarksTableTableManager(_db, _db.quranBookmarks);
  $$XpLogTableTableManager get xpLog =>
      $$XpLogTableTableManager(_db, _db.xpLog);
  $$QuranSurahCacheTableTableManager get quranSurahCache =>
      $$QuranSurahCacheTableTableManager(_db, _db.quranSurahCache);
}
