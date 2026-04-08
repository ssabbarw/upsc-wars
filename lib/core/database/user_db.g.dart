// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_db.dart';

// ignore_for_file: type=lint
mixin _$SessionsDaoMixin on DatabaseAccessor<UserDatabase> {
  $SessionsTable get sessions => attachedDatabase.sessions;
  SessionsDaoManager get managers => SessionsDaoManager(this);
}

class SessionsDaoManager {
  final _$SessionsDaoMixin _db;
  SessionsDaoManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
}

mixin _$SessionQuestionsDaoMixin on DatabaseAccessor<UserDatabase> {
  $SessionsTable get sessions => attachedDatabase.sessions;
  $SessionQuestionsTable get sessionQuestions =>
      attachedDatabase.sessionQuestions;
  SessionQuestionsDaoManager get managers => SessionQuestionsDaoManager(this);
}

class SessionQuestionsDaoManager {
  final _$SessionQuestionsDaoMixin _db;
  SessionQuestionsDaoManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$SessionQuestionsTableTableManager get sessionQuestions =>
      $$SessionQuestionsTableTableManager(
        _db.attachedDatabase,
        _db.sessionQuestions,
      );
}

mixin _$BookmarksDaoMixin on DatabaseAccessor<UserDatabase> {
  $BookmarksTable get bookmarks => attachedDatabase.bookmarks;
  BookmarksDaoManager get managers => BookmarksDaoManager(this);
}

class BookmarksDaoManager {
  final _$BookmarksDaoMixin _db;
  BookmarksDaoManager(this._db);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db.attachedDatabase, _db.bookmarks);
}

mixin _$RevisionQueueDaoMixin on DatabaseAccessor<UserDatabase> {
  $RevisionQueueTable get revisionQueue => attachedDatabase.revisionQueue;
  RevisionQueueDaoManager get managers => RevisionQueueDaoManager(this);
}

class RevisionQueueDaoManager {
  final _$RevisionQueueDaoMixin _db;
  RevisionQueueDaoManager(this._db);
  $$RevisionQueueTableTableManager get revisionQueue =>
      $$RevisionQueueTableTableManager(_db.attachedDatabase, _db.revisionQueue);
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectSlugMeta = const VerificationMeta(
    'subjectSlug',
  );
  @override
  late final GeneratedColumn<String> subjectSlug = GeneratedColumn<String>(
    'subject_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicSlugMeta = const VerificationMeta(
    'topicSlug',
  );
  @override
  late final GeneratedColumn<String> topicSlug = GeneratedColumn<String>(
    'topic_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subTopicSlugMeta = const VerificationMeta(
    'subTopicSlug',
  );
  @override
  late final GeneratedColumn<String> subTopicSlug = GeneratedColumn<String>(
    'sub_topic_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionCountMeta = const VerificationMeta(
    'questionCount',
  );
  @override
  late final GeneratedColumn<int> questionCount = GeneratedColumn<int>(
    'question_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTimedMeta = const VerificationMeta(
    'isTimed',
  );
  @override
  late final GeneratedColumn<bool> isTimed = GeneratedColumn<bool>(
    'is_timed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_timed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _timeLimitSecsMeta = const VerificationMeta(
    'timeLimitSecs',
  );
  @override
  late final GeneratedColumn<int> timeLimitSecs = GeneratedColumn<int>(
    'time_limit_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _examRemainingSecsMeta = const VerificationMeta(
    'examRemainingSecs',
  );
  @override
  late final GeneratedColumn<int> examRemainingSecs = GeneratedColumn<int>(
    'exam_remaining_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    completedAt,
    subjectSlug,
    topicSlug,
    subTopicSlug,
    mode,
    status,
    questionCount,
    isTimed,
    timeLimitSecs,
    examRemainingSecs,
    language,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('subject_slug')) {
      context.handle(
        _subjectSlugMeta,
        subjectSlug.isAcceptableOrUnknown(
          data['subject_slug']!,
          _subjectSlugMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectSlugMeta);
    }
    if (data.containsKey('topic_slug')) {
      context.handle(
        _topicSlugMeta,
        topicSlug.isAcceptableOrUnknown(data['topic_slug']!, _topicSlugMeta),
      );
    }
    if (data.containsKey('sub_topic_slug')) {
      context.handle(
        _subTopicSlugMeta,
        subTopicSlug.isAcceptableOrUnknown(
          data['sub_topic_slug']!,
          _subTopicSlugMeta,
        ),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('question_count')) {
      context.handle(
        _questionCountMeta,
        questionCount.isAcceptableOrUnknown(
          data['question_count']!,
          _questionCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionCountMeta);
    }
    if (data.containsKey('is_timed')) {
      context.handle(
        _isTimedMeta,
        isTimed.isAcceptableOrUnknown(data['is_timed']!, _isTimedMeta),
      );
    } else if (isInserting) {
      context.missing(_isTimedMeta);
    }
    if (data.containsKey('time_limit_secs')) {
      context.handle(
        _timeLimitSecsMeta,
        timeLimitSecs.isAcceptableOrUnknown(
          data['time_limit_secs']!,
          _timeLimitSecsMeta,
        ),
      );
    }
    if (data.containsKey('exam_remaining_secs')) {
      context.handle(
        _examRemainingSecsMeta,
        examRemainingSecs.isAcceptableOrUnknown(
          data['exam_remaining_secs']!,
          _examRemainingSecsMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      subjectSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_slug'],
      )!,
      topicSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_slug'],
      ),
      subTopicSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_topic_slug'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      questionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_count'],
      )!,
      isTimed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_timed'],
      )!,
      timeLimitSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_limit_secs'],
      ),
      examRemainingSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exam_remaining_secs'],
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String subjectSlug;
  final String? topicSlug;
  final String? subTopicSlug;
  final String mode;
  final String status;
  final int questionCount;
  final bool isTimed;
  final int? timeLimitSecs;

  /// Last saved remaining seconds for timed exam (approximate resume).
  final int? examRemainingSecs;
  final String language;
  const Session({
    required this.id,
    required this.createdAt,
    this.completedAt,
    required this.subjectSlug,
    this.topicSlug,
    this.subTopicSlug,
    required this.mode,
    required this.status,
    required this.questionCount,
    required this.isTimed,
    this.timeLimitSecs,
    this.examRemainingSecs,
    required this.language,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['subject_slug'] = Variable<String>(subjectSlug);
    if (!nullToAbsent || topicSlug != null) {
      map['topic_slug'] = Variable<String>(topicSlug);
    }
    if (!nullToAbsent || subTopicSlug != null) {
      map['sub_topic_slug'] = Variable<String>(subTopicSlug);
    }
    map['mode'] = Variable<String>(mode);
    map['status'] = Variable<String>(status);
    map['question_count'] = Variable<int>(questionCount);
    map['is_timed'] = Variable<bool>(isTimed);
    if (!nullToAbsent || timeLimitSecs != null) {
      map['time_limit_secs'] = Variable<int>(timeLimitSecs);
    }
    if (!nullToAbsent || examRemainingSecs != null) {
      map['exam_remaining_secs'] = Variable<int>(examRemainingSecs);
    }
    map['language'] = Variable<String>(language);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      subjectSlug: Value(subjectSlug),
      topicSlug: topicSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(topicSlug),
      subTopicSlug: subTopicSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(subTopicSlug),
      mode: Value(mode),
      status: Value(status),
      questionCount: Value(questionCount),
      isTimed: Value(isTimed),
      timeLimitSecs: timeLimitSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(timeLimitSecs),
      examRemainingSecs: examRemainingSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(examRemainingSecs),
      language: Value(language),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      subjectSlug: serializer.fromJson<String>(json['subjectSlug']),
      topicSlug: serializer.fromJson<String?>(json['topicSlug']),
      subTopicSlug: serializer.fromJson<String?>(json['subTopicSlug']),
      mode: serializer.fromJson<String>(json['mode']),
      status: serializer.fromJson<String>(json['status']),
      questionCount: serializer.fromJson<int>(json['questionCount']),
      isTimed: serializer.fromJson<bool>(json['isTimed']),
      timeLimitSecs: serializer.fromJson<int?>(json['timeLimitSecs']),
      examRemainingSecs: serializer.fromJson<int?>(json['examRemainingSecs']),
      language: serializer.fromJson<String>(json['language']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'subjectSlug': serializer.toJson<String>(subjectSlug),
      'topicSlug': serializer.toJson<String?>(topicSlug),
      'subTopicSlug': serializer.toJson<String?>(subTopicSlug),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(status),
      'questionCount': serializer.toJson<int>(questionCount),
      'isTimed': serializer.toJson<bool>(isTimed),
      'timeLimitSecs': serializer.toJson<int?>(timeLimitSecs),
      'examRemainingSecs': serializer.toJson<int?>(examRemainingSecs),
      'language': serializer.toJson<String>(language),
    };
  }

  Session copyWith({
    String? id,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    String? subjectSlug,
    Value<String?> topicSlug = const Value.absent(),
    Value<String?> subTopicSlug = const Value.absent(),
    String? mode,
    String? status,
    int? questionCount,
    bool? isTimed,
    Value<int?> timeLimitSecs = const Value.absent(),
    Value<int?> examRemainingSecs = const Value.absent(),
    String? language,
  }) => Session(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    subjectSlug: subjectSlug ?? this.subjectSlug,
    topicSlug: topicSlug.present ? topicSlug.value : this.topicSlug,
    subTopicSlug: subTopicSlug.present ? subTopicSlug.value : this.subTopicSlug,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    questionCount: questionCount ?? this.questionCount,
    isTimed: isTimed ?? this.isTimed,
    timeLimitSecs: timeLimitSecs.present
        ? timeLimitSecs.value
        : this.timeLimitSecs,
    examRemainingSecs: examRemainingSecs.present
        ? examRemainingSecs.value
        : this.examRemainingSecs,
    language: language ?? this.language,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      subjectSlug: data.subjectSlug.present
          ? data.subjectSlug.value
          : this.subjectSlug,
      topicSlug: data.topicSlug.present ? data.topicSlug.value : this.topicSlug,
      subTopicSlug: data.subTopicSlug.present
          ? data.subTopicSlug.value
          : this.subTopicSlug,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      questionCount: data.questionCount.present
          ? data.questionCount.value
          : this.questionCount,
      isTimed: data.isTimed.present ? data.isTimed.value : this.isTimed,
      timeLimitSecs: data.timeLimitSecs.present
          ? data.timeLimitSecs.value
          : this.timeLimitSecs,
      examRemainingSecs: data.examRemainingSecs.present
          ? data.examRemainingSecs.value
          : this.examRemainingSecs,
      language: data.language.present ? data.language.value : this.language,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('subjectSlug: $subjectSlug, ')
          ..write('topicSlug: $topicSlug, ')
          ..write('subTopicSlug: $subTopicSlug, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('questionCount: $questionCount, ')
          ..write('isTimed: $isTimed, ')
          ..write('timeLimitSecs: $timeLimitSecs, ')
          ..write('examRemainingSecs: $examRemainingSecs, ')
          ..write('language: $language')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    completedAt,
    subjectSlug,
    topicSlug,
    subTopicSlug,
    mode,
    status,
    questionCount,
    isTimed,
    timeLimitSecs,
    examRemainingSecs,
    language,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.subjectSlug == this.subjectSlug &&
          other.topicSlug == this.topicSlug &&
          other.subTopicSlug == this.subTopicSlug &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.questionCount == this.questionCount &&
          other.isTimed == this.isTimed &&
          other.timeLimitSecs == this.timeLimitSecs &&
          other.examRemainingSecs == this.examRemainingSecs &&
          other.language == this.language);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<String> subjectSlug;
  final Value<String?> topicSlug;
  final Value<String?> subTopicSlug;
  final Value<String> mode;
  final Value<String> status;
  final Value<int> questionCount;
  final Value<bool> isTimed;
  final Value<int?> timeLimitSecs;
  final Value<int?> examRemainingSecs;
  final Value<String> language;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.subjectSlug = const Value.absent(),
    this.topicSlug = const Value.absent(),
    this.subTopicSlug = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.questionCount = const Value.absent(),
    this.isTimed = const Value.absent(),
    this.timeLimitSecs = const Value.absent(),
    this.examRemainingSecs = const Value.absent(),
    this.language = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    required String subjectSlug,
    this.topicSlug = const Value.absent(),
    this.subTopicSlug = const Value.absent(),
    required String mode,
    required String status,
    required int questionCount,
    required bool isTimed,
    this.timeLimitSecs = const Value.absent(),
    this.examRemainingSecs = const Value.absent(),
    this.language = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       subjectSlug = Value(subjectSlug),
       mode = Value(mode),
       status = Value(status),
       questionCount = Value(questionCount),
       isTimed = Value(isTimed);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<String>? subjectSlug,
    Expression<String>? topicSlug,
    Expression<String>? subTopicSlug,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<int>? questionCount,
    Expression<bool>? isTimed,
    Expression<int>? timeLimitSecs,
    Expression<int>? examRemainingSecs,
    Expression<String>? language,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (subjectSlug != null) 'subject_slug': subjectSlug,
      if (topicSlug != null) 'topic_slug': topicSlug,
      if (subTopicSlug != null) 'sub_topic_slug': subTopicSlug,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (questionCount != null) 'question_count': questionCount,
      if (isTimed != null) 'is_timed': isTimed,
      if (timeLimitSecs != null) 'time_limit_secs': timeLimitSecs,
      if (examRemainingSecs != null) 'exam_remaining_secs': examRemainingSecs,
      if (language != null) 'language': language,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<String>? subjectSlug,
    Value<String?>? topicSlug,
    Value<String?>? subTopicSlug,
    Value<String>? mode,
    Value<String>? status,
    Value<int>? questionCount,
    Value<bool>? isTimed,
    Value<int?>? timeLimitSecs,
    Value<int?>? examRemainingSecs,
    Value<String>? language,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      subjectSlug: subjectSlug ?? this.subjectSlug,
      topicSlug: topicSlug ?? this.topicSlug,
      subTopicSlug: subTopicSlug ?? this.subTopicSlug,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      isTimed: isTimed ?? this.isTimed,
      timeLimitSecs: timeLimitSecs ?? this.timeLimitSecs,
      examRemainingSecs: examRemainingSecs ?? this.examRemainingSecs,
      language: language ?? this.language,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (subjectSlug.present) {
      map['subject_slug'] = Variable<String>(subjectSlug.value);
    }
    if (topicSlug.present) {
      map['topic_slug'] = Variable<String>(topicSlug.value);
    }
    if (subTopicSlug.present) {
      map['sub_topic_slug'] = Variable<String>(subTopicSlug.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (questionCount.present) {
      map['question_count'] = Variable<int>(questionCount.value);
    }
    if (isTimed.present) {
      map['is_timed'] = Variable<bool>(isTimed.value);
    }
    if (timeLimitSecs.present) {
      map['time_limit_secs'] = Variable<int>(timeLimitSecs.value);
    }
    if (examRemainingSecs.present) {
      map['exam_remaining_secs'] = Variable<int>(examRemainingSecs.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('subjectSlug: $subjectSlug, ')
          ..write('topicSlug: $topicSlug, ')
          ..write('subTopicSlug: $subTopicSlug, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('questionCount: $questionCount, ')
          ..write('isTimed: $isTimed, ')
          ..write('timeLimitSecs: $timeLimitSecs, ')
          ..write('examRemainingSecs: $examRemainingSecs, ')
          ..write('language: $language, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionQuestionsTable extends SessionQuestions
    with TableInfo<$SessionQuestionsTable, SessionQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _questionUuidMeta = const VerificationMeta(
    'questionUuid',
  );
  @override
  late final GeneratedColumn<String> questionUuid = GeneratedColumn<String>(
    'question_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedOptionMeta = const VerificationMeta(
    'selectedOption',
  );
  @override
  late final GeneratedColumn<String> selectedOption = GeneratedColumn<String>(
    'selected_option',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unattempted'),
  );
  static const VerificationMeta _timeSpentSecsMeta = const VerificationMeta(
    'timeSpentSecs',
  );
  @override
  late final GeneratedColumn<int> timeSpentSecs = GeneratedColumn<int>(
    'time_spent_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flaggedMeta = const VerificationMeta(
    'flagged',
  );
  @override
  late final GeneratedColumn<bool> flagged = GeneratedColumn<bool>(
    'flagged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("flagged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    questionUuid,
    position,
    selectedOption,
    isCorrect,
    status,
    timeSpentSecs,
    flagged,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionQuestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('question_uuid')) {
      context.handle(
        _questionUuidMeta,
        questionUuid.isAcceptableOrUnknown(
          data['question_uuid']!,
          _questionUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionUuidMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('selected_option')) {
      context.handle(
        _selectedOptionMeta,
        selectedOption.isAcceptableOrUnknown(
          data['selected_option']!,
          _selectedOptionMeta,
        ),
      );
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('time_spent_secs')) {
      context.handle(
        _timeSpentSecsMeta,
        timeSpentSecs.isAcceptableOrUnknown(
          data['time_spent_secs']!,
          _timeSpentSecsMeta,
        ),
      );
    }
    if (data.containsKey('flagged')) {
      context.handle(
        _flaggedMeta,
        flagged.isAcceptableOrUnknown(data['flagged']!, _flaggedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionQuestion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      questionUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_uuid'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      selectedOption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_option'],
      ),
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      timeSpentSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_spent_secs'],
      ),
      flagged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}flagged'],
      )!,
    );
  }

  @override
  $SessionQuestionsTable createAlias(String alias) {
    return $SessionQuestionsTable(attachedDatabase, alias);
  }
}

class SessionQuestion extends DataClass implements Insertable<SessionQuestion> {
  final String id;
  final String sessionId;
  final String questionUuid;
  final int position;
  final String? selectedOption;
  final bool? isCorrect;
  final String status;
  final int? timeSpentSecs;
  final bool flagged;
  const SessionQuestion({
    required this.id,
    required this.sessionId,
    required this.questionUuid,
    required this.position,
    this.selectedOption,
    this.isCorrect,
    required this.status,
    this.timeSpentSecs,
    required this.flagged,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['question_uuid'] = Variable<String>(questionUuid);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || selectedOption != null) {
      map['selected_option'] = Variable<String>(selectedOption);
    }
    if (!nullToAbsent || isCorrect != null) {
      map['is_correct'] = Variable<bool>(isCorrect);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || timeSpentSecs != null) {
      map['time_spent_secs'] = Variable<int>(timeSpentSecs);
    }
    map['flagged'] = Variable<bool>(flagged);
    return map;
  }

  SessionQuestionsCompanion toCompanion(bool nullToAbsent) {
    return SessionQuestionsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      questionUuid: Value(questionUuid),
      position: Value(position),
      selectedOption: selectedOption == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedOption),
      isCorrect: isCorrect == null && nullToAbsent
          ? const Value.absent()
          : Value(isCorrect),
      status: Value(status),
      timeSpentSecs: timeSpentSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(timeSpentSecs),
      flagged: Value(flagged),
    );
  }

  factory SessionQuestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionQuestion(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      questionUuid: serializer.fromJson<String>(json['questionUuid']),
      position: serializer.fromJson<int>(json['position']),
      selectedOption: serializer.fromJson<String?>(json['selectedOption']),
      isCorrect: serializer.fromJson<bool?>(json['isCorrect']),
      status: serializer.fromJson<String>(json['status']),
      timeSpentSecs: serializer.fromJson<int?>(json['timeSpentSecs']),
      flagged: serializer.fromJson<bool>(json['flagged']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'questionUuid': serializer.toJson<String>(questionUuid),
      'position': serializer.toJson<int>(position),
      'selectedOption': serializer.toJson<String?>(selectedOption),
      'isCorrect': serializer.toJson<bool?>(isCorrect),
      'status': serializer.toJson<String>(status),
      'timeSpentSecs': serializer.toJson<int?>(timeSpentSecs),
      'flagged': serializer.toJson<bool>(flagged),
    };
  }

  SessionQuestion copyWith({
    String? id,
    String? sessionId,
    String? questionUuid,
    int? position,
    Value<String?> selectedOption = const Value.absent(),
    Value<bool?> isCorrect = const Value.absent(),
    String? status,
    Value<int?> timeSpentSecs = const Value.absent(),
    bool? flagged,
  }) => SessionQuestion(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    questionUuid: questionUuid ?? this.questionUuid,
    position: position ?? this.position,
    selectedOption: selectedOption.present
        ? selectedOption.value
        : this.selectedOption,
    isCorrect: isCorrect.present ? isCorrect.value : this.isCorrect,
    status: status ?? this.status,
    timeSpentSecs: timeSpentSecs.present
        ? timeSpentSecs.value
        : this.timeSpentSecs,
    flagged: flagged ?? this.flagged,
  );
  SessionQuestion copyWithCompanion(SessionQuestionsCompanion data) {
    return SessionQuestion(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      questionUuid: data.questionUuid.present
          ? data.questionUuid.value
          : this.questionUuid,
      position: data.position.present ? data.position.value : this.position,
      selectedOption: data.selectedOption.present
          ? data.selectedOption.value
          : this.selectedOption,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      status: data.status.present ? data.status.value : this.status,
      timeSpentSecs: data.timeSpentSecs.present
          ? data.timeSpentSecs.value
          : this.timeSpentSecs,
      flagged: data.flagged.present ? data.flagged.value : this.flagged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionQuestion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('position: $position, ')
          ..write('selectedOption: $selectedOption, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('status: $status, ')
          ..write('timeSpentSecs: $timeSpentSecs, ')
          ..write('flagged: $flagged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    questionUuid,
    position,
    selectedOption,
    isCorrect,
    status,
    timeSpentSecs,
    flagged,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionQuestion &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.questionUuid == this.questionUuid &&
          other.position == this.position &&
          other.selectedOption == this.selectedOption &&
          other.isCorrect == this.isCorrect &&
          other.status == this.status &&
          other.timeSpentSecs == this.timeSpentSecs &&
          other.flagged == this.flagged);
}

class SessionQuestionsCompanion extends UpdateCompanion<SessionQuestion> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> questionUuid;
  final Value<int> position;
  final Value<String?> selectedOption;
  final Value<bool?> isCorrect;
  final Value<String> status;
  final Value<int?> timeSpentSecs;
  final Value<bool> flagged;
  final Value<int> rowid;
  const SessionQuestionsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.questionUuid = const Value.absent(),
    this.position = const Value.absent(),
    this.selectedOption = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.status = const Value.absent(),
    this.timeSpentSecs = const Value.absent(),
    this.flagged = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionQuestionsCompanion.insert({
    required String id,
    required String sessionId,
    required String questionUuid,
    required int position,
    this.selectedOption = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.status = const Value.absent(),
    this.timeSpentSecs = const Value.absent(),
    this.flagged = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       questionUuid = Value(questionUuid),
       position = Value(position);
  static Insertable<SessionQuestion> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? questionUuid,
    Expression<int>? position,
    Expression<String>? selectedOption,
    Expression<bool>? isCorrect,
    Expression<String>? status,
    Expression<int>? timeSpentSecs,
    Expression<bool>? flagged,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (questionUuid != null) 'question_uuid': questionUuid,
      if (position != null) 'position': position,
      if (selectedOption != null) 'selected_option': selectedOption,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (status != null) 'status': status,
      if (timeSpentSecs != null) 'time_spent_secs': timeSpentSecs,
      if (flagged != null) 'flagged': flagged,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionQuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? questionUuid,
    Value<int>? position,
    Value<String?>? selectedOption,
    Value<bool?>? isCorrect,
    Value<String>? status,
    Value<int?>? timeSpentSecs,
    Value<bool>? flagged,
    Value<int>? rowid,
  }) {
    return SessionQuestionsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      questionUuid: questionUuid ?? this.questionUuid,
      position: position ?? this.position,
      selectedOption: selectedOption ?? this.selectedOption,
      isCorrect: isCorrect ?? this.isCorrect,
      status: status ?? this.status,
      timeSpentSecs: timeSpentSecs ?? this.timeSpentSecs,
      flagged: flagged ?? this.flagged,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (questionUuid.present) {
      map['question_uuid'] = Variable<String>(questionUuid.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (selectedOption.present) {
      map['selected_option'] = Variable<String>(selectedOption.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (timeSpentSecs.present) {
      map['time_spent_secs'] = Variable<int>(timeSpentSecs.value);
    }
    if (flagged.present) {
      map['flagged'] = Variable<bool>(flagged.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('position: $position, ')
          ..write('selectedOption: $selectedOption, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('status: $status, ')
          ..write('timeSpentSecs: $timeSpentSecs, ')
          ..write('flagged: $flagged, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionUuidMeta = const VerificationMeta(
    'questionUuid',
  );
  @override
  late final GeneratedColumn<String> questionUuid = GeneratedColumn<String>(
    'question_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, questionUuid, createdAt, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_uuid')) {
      context.handle(
        _questionUuidMeta,
        questionUuid.isAcceptableOrUnknown(
          data['question_uuid']!,
          _questionUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionUuidMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      questionUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_uuid'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String id;
  final String questionUuid;
  final DateTime createdAt;
  final String? note;
  const Bookmark({
    required this.id,
    required this.questionUuid,
    required this.createdAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_uuid'] = Variable<String>(questionUuid);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      questionUuid: Value(questionUuid),
      createdAt: Value(createdAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<String>(json['id']),
      questionUuid: serializer.fromJson<String>(json['questionUuid']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionUuid': serializer.toJson<String>(questionUuid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  Bookmark copyWith({
    String? id,
    String? questionUuid,
    DateTime? createdAt,
    Value<String?> note = const Value.absent(),
  }) => Bookmark(
    id: id ?? this.id,
    questionUuid: questionUuid ?? this.questionUuid,
    createdAt: createdAt ?? this.createdAt,
    note: note.present ? note.value : this.note,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      questionUuid: data.questionUuid.present
          ? data.questionUuid.value
          : this.questionUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionUuid, createdAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.questionUuid == this.questionUuid &&
          other.createdAt == this.createdAt &&
          other.note == this.note);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<String> questionUuid;
  final Value<DateTime> createdAt;
  final Value<String?> note;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.questionUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String questionUuid,
    required DateTime createdAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       questionUuid = Value(questionUuid),
       createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<String>? questionUuid,
    Expression<DateTime>? createdAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionUuid != null) 'question_uuid': questionUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? questionUuid,
    Value<DateTime>? createdAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      questionUuid: questionUuid ?? this.questionUuid,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questionUuid.present) {
      map['question_uuid'] = Variable<String>(questionUuid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RevisionQueueTable extends RevisionQueue
    with TableInfo<$RevisionQueueTable, RevisionQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RevisionQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionUuidMeta = const VerificationMeta(
    'questionUuid',
  );
  @override
  late final GeneratedColumn<String> questionUuid = GeneratedColumn<String>(
    'question_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctStreakMeta = const VerificationMeta(
    'correctStreak',
  );
  @override
  late final GeneratedColumn<int> correctStreak = GeneratedColumn<int>(
    'correct_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCorrectAtMeta = const VerificationMeta(
    'lastCorrectAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCorrectAt =
      GeneratedColumn<DateTime>(
        'last_correct_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionUuid,
    addedAt,
    reason,
    correctStreak,
    lastCorrectAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'revision_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<RevisionQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_uuid')) {
      context.handle(
        _questionUuidMeta,
        questionUuid.isAcceptableOrUnknown(
          data['question_uuid']!,
          _questionUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionUuidMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('correct_streak')) {
      context.handle(
        _correctStreakMeta,
        correctStreak.isAcceptableOrUnknown(
          data['correct_streak']!,
          _correctStreakMeta,
        ),
      );
    }
    if (data.containsKey('last_correct_at')) {
      context.handle(
        _lastCorrectAtMeta,
        lastCorrectAt.isAcceptableOrUnknown(
          data['last_correct_at']!,
          _lastCorrectAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RevisionQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RevisionQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      questionUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_uuid'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      correctStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_streak'],
      )!,
      lastCorrectAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_correct_at'],
      ),
    );
  }

  @override
  $RevisionQueueTable createAlias(String alias) {
    return $RevisionQueueTable(attachedDatabase, alias);
  }
}

class RevisionQueueData extends DataClass
    implements Insertable<RevisionQueueData> {
  final String id;
  final String questionUuid;
  final DateTime addedAt;
  final String reason;
  final int correctStreak;
  final DateTime? lastCorrectAt;
  const RevisionQueueData({
    required this.id,
    required this.questionUuid,
    required this.addedAt,
    required this.reason,
    required this.correctStreak,
    this.lastCorrectAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_uuid'] = Variable<String>(questionUuid);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['reason'] = Variable<String>(reason);
    map['correct_streak'] = Variable<int>(correctStreak);
    if (!nullToAbsent || lastCorrectAt != null) {
      map['last_correct_at'] = Variable<DateTime>(lastCorrectAt);
    }
    return map;
  }

  RevisionQueueCompanion toCompanion(bool nullToAbsent) {
    return RevisionQueueCompanion(
      id: Value(id),
      questionUuid: Value(questionUuid),
      addedAt: Value(addedAt),
      reason: Value(reason),
      correctStreak: Value(correctStreak),
      lastCorrectAt: lastCorrectAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCorrectAt),
    );
  }

  factory RevisionQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RevisionQueueData(
      id: serializer.fromJson<String>(json['id']),
      questionUuid: serializer.fromJson<String>(json['questionUuid']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      reason: serializer.fromJson<String>(json['reason']),
      correctStreak: serializer.fromJson<int>(json['correctStreak']),
      lastCorrectAt: serializer.fromJson<DateTime?>(json['lastCorrectAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionUuid': serializer.toJson<String>(questionUuid),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'reason': serializer.toJson<String>(reason),
      'correctStreak': serializer.toJson<int>(correctStreak),
      'lastCorrectAt': serializer.toJson<DateTime?>(lastCorrectAt),
    };
  }

  RevisionQueueData copyWith({
    String? id,
    String? questionUuid,
    DateTime? addedAt,
    String? reason,
    int? correctStreak,
    Value<DateTime?> lastCorrectAt = const Value.absent(),
  }) => RevisionQueueData(
    id: id ?? this.id,
    questionUuid: questionUuid ?? this.questionUuid,
    addedAt: addedAt ?? this.addedAt,
    reason: reason ?? this.reason,
    correctStreak: correctStreak ?? this.correctStreak,
    lastCorrectAt: lastCorrectAt.present
        ? lastCorrectAt.value
        : this.lastCorrectAt,
  );
  RevisionQueueData copyWithCompanion(RevisionQueueCompanion data) {
    return RevisionQueueData(
      id: data.id.present ? data.id.value : this.id,
      questionUuid: data.questionUuid.present
          ? data.questionUuid.value
          : this.questionUuid,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      reason: data.reason.present ? data.reason.value : this.reason,
      correctStreak: data.correctStreak.present
          ? data.correctStreak.value
          : this.correctStreak,
      lastCorrectAt: data.lastCorrectAt.present
          ? data.lastCorrectAt.value
          : this.lastCorrectAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RevisionQueueData(')
          ..write('id: $id, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('addedAt: $addedAt, ')
          ..write('reason: $reason, ')
          ..write('correctStreak: $correctStreak, ')
          ..write('lastCorrectAt: $lastCorrectAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questionUuid,
    addedAt,
    reason,
    correctStreak,
    lastCorrectAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevisionQueueData &&
          other.id == this.id &&
          other.questionUuid == this.questionUuid &&
          other.addedAt == this.addedAt &&
          other.reason == this.reason &&
          other.correctStreak == this.correctStreak &&
          other.lastCorrectAt == this.lastCorrectAt);
}

class RevisionQueueCompanion extends UpdateCompanion<RevisionQueueData> {
  final Value<String> id;
  final Value<String> questionUuid;
  final Value<DateTime> addedAt;
  final Value<String> reason;
  final Value<int> correctStreak;
  final Value<DateTime?> lastCorrectAt;
  final Value<int> rowid;
  const RevisionQueueCompanion({
    this.id = const Value.absent(),
    this.questionUuid = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.reason = const Value.absent(),
    this.correctStreak = const Value.absent(),
    this.lastCorrectAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RevisionQueueCompanion.insert({
    required String id,
    required String questionUuid,
    required DateTime addedAt,
    required String reason,
    this.correctStreak = const Value.absent(),
    this.lastCorrectAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       questionUuid = Value(questionUuid),
       addedAt = Value(addedAt),
       reason = Value(reason);
  static Insertable<RevisionQueueData> custom({
    Expression<String>? id,
    Expression<String>? questionUuid,
    Expression<DateTime>? addedAt,
    Expression<String>? reason,
    Expression<int>? correctStreak,
    Expression<DateTime>? lastCorrectAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionUuid != null) 'question_uuid': questionUuid,
      if (addedAt != null) 'added_at': addedAt,
      if (reason != null) 'reason': reason,
      if (correctStreak != null) 'correct_streak': correctStreak,
      if (lastCorrectAt != null) 'last_correct_at': lastCorrectAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RevisionQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? questionUuid,
    Value<DateTime>? addedAt,
    Value<String>? reason,
    Value<int>? correctStreak,
    Value<DateTime?>? lastCorrectAt,
    Value<int>? rowid,
  }) {
    return RevisionQueueCompanion(
      id: id ?? this.id,
      questionUuid: questionUuid ?? this.questionUuid,
      addedAt: addedAt ?? this.addedAt,
      reason: reason ?? this.reason,
      correctStreak: correctStreak ?? this.correctStreak,
      lastCorrectAt: lastCorrectAt ?? this.lastCorrectAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questionUuid.present) {
      map['question_uuid'] = Variable<String>(questionUuid.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (correctStreak.present) {
      map['correct_streak'] = Variable<int>(correctStreak.value);
    }
    if (lastCorrectAt.present) {
      map['last_correct_at'] = Variable<DateTime>(lastCorrectAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevisionQueueCompanion(')
          ..write('id: $id, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('addedAt: $addedAt, ')
          ..write('reason: $reason, ')
          ..write('correctStreak: $correctStreak, ')
          ..write('lastCorrectAt: $lastCorrectAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionQuestionsTable sessionQuestions = $SessionQuestionsTable(
    this,
  );
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $RevisionQueueTable revisionQueue = $RevisionQueueTable(this);
  late final SessionsDao sessionsDao = SessionsDao(this as UserDatabase);
  late final SessionQuestionsDao sessionQuestionsDao = SessionQuestionsDao(
    this as UserDatabase,
  );
  late final BookmarksDao bookmarksDao = BookmarksDao(this as UserDatabase);
  late final RevisionQueueDao revisionQueueDao = RevisionQueueDao(
    this as UserDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    sessionQuestions,
    bookmarks,
    revisionQueue,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      required String subjectSlug,
      Value<String?> topicSlug,
      Value<String?> subTopicSlug,
      required String mode,
      required String status,
      required int questionCount,
      required bool isTimed,
      Value<int?> timeLimitSecs,
      Value<int?> examRemainingSecs,
      Value<String> language,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<String> subjectSlug,
      Value<String?> topicSlug,
      Value<String?> subTopicSlug,
      Value<String> mode,
      Value<String> status,
      Value<int> questionCount,
      Value<bool> isTimed,
      Value<int?> timeLimitSecs,
      Value<int?> examRemainingSecs,
      Value<String> language,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$UserDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionQuestionsTable, List<SessionQuestion>>
  _sessionQuestionsRefsTable(_$UserDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.sessionQuestions,
        aliasName: $_aliasNameGenerator(
          db.sessions.id,
          db.sessionQuestions.sessionId,
        ),
      );

  $$SessionQuestionsTableProcessedTableManager get sessionQuestionsRefs {
    final manager = $$SessionQuestionsTableTableManager(
      $_db,
      $_db.sessionQuestions,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionQuestionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$UserDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectSlug => $composableBuilder(
    column: $table.subjectSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicSlug => $composableBuilder(
    column: $table.topicSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subTopicSlug => $composableBuilder(
    column: $table.subTopicSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTimed => $composableBuilder(
    column: $table.isTimed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeLimitSecs => $composableBuilder(
    column: $table.timeLimitSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get examRemainingSecs => $composableBuilder(
    column: $table.examRemainingSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionQuestionsRefs(
    Expression<bool> Function($$SessionQuestionsTableFilterComposer f) f,
  ) {
    final $$SessionQuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionQuestions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionQuestionsTableFilterComposer(
            $db: $db,
            $table: $db.sessionQuestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$UserDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectSlug => $composableBuilder(
    column: $table.subjectSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicSlug => $composableBuilder(
    column: $table.topicSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subTopicSlug => $composableBuilder(
    column: $table.subTopicSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTimed => $composableBuilder(
    column: $table.isTimed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeLimitSecs => $composableBuilder(
    column: $table.timeLimitSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get examRemainingSecs => $composableBuilder(
    column: $table.examRemainingSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectSlug => $composableBuilder(
    column: $table.subjectSlug,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topicSlug =>
      $composableBuilder(column: $table.topicSlug, builder: (column) => column);

  GeneratedColumn<String> get subTopicSlug => $composableBuilder(
    column: $table.subTopicSlug,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTimed =>
      $composableBuilder(column: $table.isTimed, builder: (column) => column);

  GeneratedColumn<int> get timeLimitSecs => $composableBuilder(
    column: $table.timeLimitSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get examRemainingSecs => $composableBuilder(
    column: $table.examRemainingSecs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  Expression<T> sessionQuestionsRefs<T extends Object>(
    Expression<T> Function($$SessionQuestionsTableAnnotationComposer a) f,
  ) {
    final $$SessionQuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionQuestions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionQuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionQuestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({bool sessionQuestionsRefs})
        > {
  $$SessionsTableTableManager(_$UserDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> subjectSlug = const Value.absent(),
                Value<String?> topicSlug = const Value.absent(),
                Value<String?> subTopicSlug = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> questionCount = const Value.absent(),
                Value<bool> isTimed = const Value.absent(),
                Value<int?> timeLimitSecs = const Value.absent(),
                Value<int?> examRemainingSecs = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                createdAt: createdAt,
                completedAt: completedAt,
                subjectSlug: subjectSlug,
                topicSlug: topicSlug,
                subTopicSlug: subTopicSlug,
                mode: mode,
                status: status,
                questionCount: questionCount,
                isTimed: isTimed,
                timeLimitSecs: timeLimitSecs,
                examRemainingSecs: examRemainingSecs,
                language: language,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                required String subjectSlug,
                Value<String?> topicSlug = const Value.absent(),
                Value<String?> subTopicSlug = const Value.absent(),
                required String mode,
                required String status,
                required int questionCount,
                required bool isTimed,
                Value<int?> timeLimitSecs = const Value.absent(),
                Value<int?> examRemainingSecs = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                completedAt: completedAt,
                subjectSlug: subjectSlug,
                topicSlug: topicSlug,
                subTopicSlug: subTopicSlug,
                mode: mode,
                status: status,
                questionCount: questionCount,
                isTimed: isTimed,
                timeLimitSecs: timeLimitSecs,
                examRemainingSecs: examRemainingSecs,
                language: language,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionQuestionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionQuestionsRefs) db.sessionQuestions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionQuestionsRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      SessionQuestion
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._sessionQuestionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SessionsTableReferences(
                        db,
                        table,
                        p0,
                      ).sessionQuestionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({bool sessionQuestionsRefs})
    >;
typedef $$SessionQuestionsTableCreateCompanionBuilder =
    SessionQuestionsCompanion Function({
      required String id,
      required String sessionId,
      required String questionUuid,
      required int position,
      Value<String?> selectedOption,
      Value<bool?> isCorrect,
      Value<String> status,
      Value<int?> timeSpentSecs,
      Value<bool> flagged,
      Value<int> rowid,
    });
typedef $$SessionQuestionsTableUpdateCompanionBuilder =
    SessionQuestionsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> questionUuid,
      Value<int> position,
      Value<String?> selectedOption,
      Value<bool?> isCorrect,
      Value<String> status,
      Value<int?> timeSpentSecs,
      Value<bool> flagged,
      Value<int> rowid,
    });

final class $$SessionQuestionsTableReferences
    extends
        BaseReferences<
          _$UserDatabase,
          $SessionQuestionsTable,
          SessionQuestion
        > {
  $$SessionQuestionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$UserDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.sessionQuestions.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionQuestionsTableFilterComposer
    extends Composer<_$UserDatabase, $SessionQuestionsTable> {
  $$SessionQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionUuid => $composableBuilder(
    column: $table.questionUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedOption => $composableBuilder(
    column: $table.selectedOption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSpentSecs => $composableBuilder(
    column: $table.timeSpentSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get flagged => $composableBuilder(
    column: $table.flagged,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionQuestionsTableOrderingComposer
    extends Composer<_$UserDatabase, $SessionQuestionsTable> {
  $$SessionQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionUuid => $composableBuilder(
    column: $table.questionUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedOption => $composableBuilder(
    column: $table.selectedOption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSpentSecs => $composableBuilder(
    column: $table.timeSpentSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get flagged => $composableBuilder(
    column: $table.flagged,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionQuestionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $SessionQuestionsTable> {
  $$SessionQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionUuid => $composableBuilder(
    column: $table.questionUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get selectedOption => $composableBuilder(
    column: $table.selectedOption,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get timeSpentSecs => $composableBuilder(
    column: $table.timeSpentSecs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get flagged =>
      $composableBuilder(column: $table.flagged, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionQuestionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $SessionQuestionsTable,
          SessionQuestion,
          $$SessionQuestionsTableFilterComposer,
          $$SessionQuestionsTableOrderingComposer,
          $$SessionQuestionsTableAnnotationComposer,
          $$SessionQuestionsTableCreateCompanionBuilder,
          $$SessionQuestionsTableUpdateCompanionBuilder,
          (SessionQuestion, $$SessionQuestionsTableReferences),
          SessionQuestion,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SessionQuestionsTableTableManager(
    _$UserDatabase db,
    $SessionQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> questionUuid = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> selectedOption = const Value.absent(),
                Value<bool?> isCorrect = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> timeSpentSecs = const Value.absent(),
                Value<bool> flagged = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionQuestionsCompanion(
                id: id,
                sessionId: sessionId,
                questionUuid: questionUuid,
                position: position,
                selectedOption: selectedOption,
                isCorrect: isCorrect,
                status: status,
                timeSpentSecs: timeSpentSecs,
                flagged: flagged,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String questionUuid,
                required int position,
                Value<String?> selectedOption = const Value.absent(),
                Value<bool?> isCorrect = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> timeSpentSecs = const Value.absent(),
                Value<bool> flagged = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionQuestionsCompanion.insert(
                id: id,
                sessionId: sessionId,
                questionUuid: questionUuid,
                position: position,
                selectedOption: selectedOption,
                isCorrect: isCorrect,
                status: status,
                timeSpentSecs: timeSpentSecs,
                flagged: flagged,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionQuestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$SessionQuestionsTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$SessionQuestionsTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $SessionQuestionsTable,
      SessionQuestion,
      $$SessionQuestionsTableFilterComposer,
      $$SessionQuestionsTableOrderingComposer,
      $$SessionQuestionsTableAnnotationComposer,
      $$SessionQuestionsTableCreateCompanionBuilder,
      $$SessionQuestionsTableUpdateCompanionBuilder,
      (SessionQuestion, $$SessionQuestionsTableReferences),
      SessionQuestion,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      required String questionUuid,
      required DateTime createdAt,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<String> questionUuid,
      Value<DateTime> createdAt,
      Value<String?> note,
      Value<int> rowid,
    });

class $$BookmarksTableFilterComposer
    extends Composer<_$UserDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionUuid => $composableBuilder(
    column: $table.questionUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$UserDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionUuid => $composableBuilder(
    column: $table.questionUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$UserDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionUuid => $composableBuilder(
    column: $table.questionUuid,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, BaseReferences<_$UserDatabase, $BookmarksTable, Bookmark>),
          Bookmark,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$UserDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> questionUuid = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                questionUuid: questionUuid,
                createdAt: createdAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String questionUuid,
                required DateTime createdAt,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                questionUuid: questionUuid,
                createdAt: createdAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, BaseReferences<_$UserDatabase, $BookmarksTable, Bookmark>),
      Bookmark,
      PrefetchHooks Function()
    >;
typedef $$RevisionQueueTableCreateCompanionBuilder =
    RevisionQueueCompanion Function({
      required String id,
      required String questionUuid,
      required DateTime addedAt,
      required String reason,
      Value<int> correctStreak,
      Value<DateTime?> lastCorrectAt,
      Value<int> rowid,
    });
typedef $$RevisionQueueTableUpdateCompanionBuilder =
    RevisionQueueCompanion Function({
      Value<String> id,
      Value<String> questionUuid,
      Value<DateTime> addedAt,
      Value<String> reason,
      Value<int> correctStreak,
      Value<DateTime?> lastCorrectAt,
      Value<int> rowid,
    });

class $$RevisionQueueTableFilterComposer
    extends Composer<_$UserDatabase, $RevisionQueueTable> {
  $$RevisionQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionUuid => $composableBuilder(
    column: $table.questionUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCorrectAt => $composableBuilder(
    column: $table.lastCorrectAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RevisionQueueTableOrderingComposer
    extends Composer<_$UserDatabase, $RevisionQueueTable> {
  $$RevisionQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionUuid => $composableBuilder(
    column: $table.questionUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCorrectAt => $composableBuilder(
    column: $table.lastCorrectAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RevisionQueueTableAnnotationComposer
    extends Composer<_$UserDatabase, $RevisionQueueTable> {
  $$RevisionQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionUuid => $composableBuilder(
    column: $table.questionUuid,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCorrectAt => $composableBuilder(
    column: $table.lastCorrectAt,
    builder: (column) => column,
  );
}

class $$RevisionQueueTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $RevisionQueueTable,
          RevisionQueueData,
          $$RevisionQueueTableFilterComposer,
          $$RevisionQueueTableOrderingComposer,
          $$RevisionQueueTableAnnotationComposer,
          $$RevisionQueueTableCreateCompanionBuilder,
          $$RevisionQueueTableUpdateCompanionBuilder,
          (
            RevisionQueueData,
            BaseReferences<
              _$UserDatabase,
              $RevisionQueueTable,
              RevisionQueueData
            >,
          ),
          RevisionQueueData,
          PrefetchHooks Function()
        > {
  $$RevisionQueueTableTableManager(_$UserDatabase db, $RevisionQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RevisionQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RevisionQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RevisionQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> questionUuid = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> correctStreak = const Value.absent(),
                Value<DateTime?> lastCorrectAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionQueueCompanion(
                id: id,
                questionUuid: questionUuid,
                addedAt: addedAt,
                reason: reason,
                correctStreak: correctStreak,
                lastCorrectAt: lastCorrectAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String questionUuid,
                required DateTime addedAt,
                required String reason,
                Value<int> correctStreak = const Value.absent(),
                Value<DateTime?> lastCorrectAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionQueueCompanion.insert(
                id: id,
                questionUuid: questionUuid,
                addedAt: addedAt,
                reason: reason,
                correctStreak: correctStreak,
                lastCorrectAt: lastCorrectAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RevisionQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $RevisionQueueTable,
      RevisionQueueData,
      $$RevisionQueueTableFilterComposer,
      $$RevisionQueueTableOrderingComposer,
      $$RevisionQueueTableAnnotationComposer,
      $$RevisionQueueTableCreateCompanionBuilder,
      $$RevisionQueueTableUpdateCompanionBuilder,
      (
        RevisionQueueData,
        BaseReferences<_$UserDatabase, $RevisionQueueTable, RevisionQueueData>,
      ),
      RevisionQueueData,
      PrefetchHooks Function()
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionQuestionsTableTableManager get sessionQuestions =>
      $$SessionQuestionsTableTableManager(_db, _db.sessionQuestions);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$RevisionQueueTableTableManager get revisionQueue =>
      $$RevisionQueueTableTableManager(_db, _db.revisionQueue);
}
