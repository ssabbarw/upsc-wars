// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_db.dart';

// ignore_for_file: type=lint
mixin _$QuestionsDaoMixin on DatabaseAccessor<UserDatabase> {
  $QuestionsTable get questions => attachedDatabase.questions;
  QuestionsDaoManager get managers => QuestionsDaoManager(this);
}

class QuestionsDaoManager {
  final _$QuestionsDaoMixin _db;
  QuestionsDaoManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db.attachedDatabase, _db.questions);
}

mixin _$QuestionTranslationsDaoMixin on DatabaseAccessor<UserDatabase> {
  $QuestionsTable get questions => attachedDatabase.questions;
  $QuestionTranslationsTable get questionTranslations =>
      attachedDatabase.questionTranslations;
  QuestionTranslationsDaoManager get managers =>
      QuestionTranslationsDaoManager(this);
}

class QuestionTranslationsDaoManager {
  final _$QuestionTranslationsDaoMixin _db;
  QuestionTranslationsDaoManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db.attachedDatabase, _db.questions);
  $$QuestionTranslationsTableTableManager get questionTranslations =>
      $$QuestionTranslationsTableTableManager(
        _db.attachedDatabase,
        _db.questionTranslations,
      );
}

mixin _$QuestionTablesDaoMixin on DatabaseAccessor<UserDatabase> {
  $QuestionsTable get questions => attachedDatabase.questions;
  $QuestionTablesTable get questionTables => attachedDatabase.questionTables;
  QuestionTablesDaoManager get managers => QuestionTablesDaoManager(this);
}

class QuestionTablesDaoManager {
  final _$QuestionTablesDaoMixin _db;
  QuestionTablesDaoManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db.attachedDatabase, _db.questions);
  $$QuestionTablesTableTableManager get questionTables =>
      $$QuestionTablesTableTableManager(
        _db.attachedDatabase,
        _db.questionTables,
      );
}

mixin _$TopicTranslationsDaoMixin on DatabaseAccessor<UserDatabase> {
  $TopicTranslationsTable get topicTranslations =>
      attachedDatabase.topicTranslations;
  TopicTranslationsDaoManager get managers => TopicTranslationsDaoManager(this);
}

class TopicTranslationsDaoManager {
  final _$TopicTranslationsDaoMixin _db;
  TopicTranslationsDaoManager(this._db);
  $$TopicTranslationsTableTableManager get topicTranslations =>
      $$TopicTranslationsTableTableManager(
        _db.attachedDatabase,
        _db.topicTranslations,
      );
}

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
  $QuestionsTable get questions => attachedDatabase.questions;
  $SessionQuestionsTable get sessionQuestions =>
      attachedDatabase.sessionQuestions;
  SessionQuestionsDaoManager get managers => SessionQuestionsDaoManager(this);
}

class SessionQuestionsDaoManager {
  final _$SessionQuestionsDaoMixin _db;
  SessionQuestionsDaoManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db.attachedDatabase, _db.questions);
  $$SessionQuestionsTableTableManager get sessionQuestions =>
      $$SessionQuestionsTableTableManager(
        _db.attachedDatabase,
        _db.sessionQuestions,
      );
}

mixin _$BookmarksDaoMixin on DatabaseAccessor<UserDatabase> {
  $QuestionsTable get questions => attachedDatabase.questions;
  $BookmarksTable get bookmarks => attachedDatabase.bookmarks;
  BookmarksDaoManager get managers => BookmarksDaoManager(this);
}

class BookmarksDaoManager {
  final _$BookmarksDaoMixin _db;
  BookmarksDaoManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db.attachedDatabase, _db.questions);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db.attachedDatabase, _db.bookmarks);
}

mixin _$RevisionQueueDaoMixin on DatabaseAccessor<UserDatabase> {
  $QuestionsTable get questions => attachedDatabase.questions;
  $RevisionQueueTable get revisionQueue => attachedDatabase.revisionQueue;
  RevisionQueueDaoManager get managers => RevisionQueueDaoManager(this);
}

class RevisionQueueDaoManager {
  final _$RevisionQueueDaoMixin _db;
  RevisionQueueDaoManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db.attachedDatabase, _db.questions);
  $$RevisionQueueTableTableManager get revisionQueue =>
      $$RevisionQueueTableTableManager(_db.attachedDatabase, _db.revisionQueue);
}

mixin _$UserFeatureStatsDaoMixin on DatabaseAccessor<UserDatabase> {
  $UserFeatureStatsTable get userFeatureStats =>
      attachedDatabase.userFeatureStats;
  UserFeatureStatsDaoManager get managers => UserFeatureStatsDaoManager(this);
}

class UserFeatureStatsDaoManager {
  final _$UserFeatureStatsDaoMixin _db;
  UserFeatureStatsDaoManager(this._db);
  $$UserFeatureStatsTableTableManager get userFeatureStats =>
      $$UserFeatureStatsTableTableManager(
        _db.attachedDatabase,
        _db.userFeatureStats,
      );
}

mixin _$UserTrapStatsDaoMixin on DatabaseAccessor<UserDatabase> {
  $UserTrapStatsTable get userTrapStats => attachedDatabase.userTrapStats;
  UserTrapStatsDaoManager get managers => UserTrapStatsDaoManager(this);
}

class UserTrapStatsDaoManager {
  final _$UserTrapStatsDaoMixin _db;
  UserTrapStatsDaoManager(this._db);
  $$UserTrapStatsTableTableManager get userTrapStats =>
      $$UserTrapStatsTableTableManager(_db.attachedDatabase, _db.userTrapStats);
}

mixin _$UserTopicStatsDaoMixin on DatabaseAccessor<UserDatabase> {
  $UserTopicStatsTable get userTopicStats => attachedDatabase.userTopicStats;
  UserTopicStatsDaoManager get managers => UserTopicStatsDaoManager(this);
}

class UserTopicStatsDaoManager {
  final _$UserTopicStatsDaoMixin _db;
  UserTopicStatsDaoManager(this._db);
  $$UserTopicStatsTableTableManager get userTopicStats =>
      $$UserTopicStatsTableTableManager(
        _db.attachedDatabase,
        _db.userTopicStats,
      );
}

class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, Question> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subTopicMeta = const VerificationMeta(
    'subTopic',
  );
  @override
  late final GeneratedColumn<String> subTopic = GeneratedColumn<String>(
    'sub_topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionTypeMeta = const VerificationMeta(
    'questionType',
  );
  @override
  late final GeneratedColumn<String> questionType = GeneratedColumn<String>(
    'question_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trapTypeMeta = const VerificationMeta(
    'trapType',
  );
  @override
  late final GeneratedColumn<String> trapType = GeneratedColumn<String>(
    'trap_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctOptionMeta = const VerificationMeta(
    'correctOption',
  );
  @override
  late final GeneratedColumn<String> correctOption = GeneratedColumn<String>(
    'correct_option',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conceptAnchorMeta = const VerificationMeta(
    'conceptAnchor',
  );
  @override
  late final GeneratedColumn<String> conceptAnchor = GeneratedColumn<String>(
    'concept_anchor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conceptsUsedMeta = const VerificationMeta(
    'conceptsUsed',
  );
  @override
  late final GeneratedColumn<String> conceptsUsed = GeneratedColumn<String>(
    'concepts_used',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enDisplayTextMeta = const VerificationMeta(
    'enDisplayText',
  );
  @override
  late final GeneratedColumn<String> enDisplayText = GeneratedColumn<String>(
    'en_display_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiDisplayTextMeta = const VerificationMeta(
    'hiDisplayText',
  );
  @override
  late final GeneratedColumn<String> hiDisplayText = GeneratedColumn<String>(
    'hi_display_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasTableMeta = const VerificationMeta(
    'hasTable',
  );
  @override
  late final GeneratedColumn<bool> hasTable = GeneratedColumn<bool>(
    'has_table',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_table" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _negativeFramingMeta = const VerificationMeta(
    'negativeFraming',
  );
  @override
  late final GeneratedColumn<bool> negativeFraming = GeneratedColumn<bool>(
    'negative_framing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("negative_framing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    subject,
    topic,
    subTopic,
    questionType,
    trapType,
    correctOption,
    conceptAnchor,
    conceptsUsed,
    enDisplayText,
    hiDisplayText,
    hasTable,
    negativeFraming,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Question> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('sub_topic')) {
      context.handle(
        _subTopicMeta,
        subTopic.isAcceptableOrUnknown(data['sub_topic']!, _subTopicMeta),
      );
    } else if (isInserting) {
      context.missing(_subTopicMeta);
    }
    if (data.containsKey('question_type')) {
      context.handle(
        _questionTypeMeta,
        questionType.isAcceptableOrUnknown(
          data['question_type']!,
          _questionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTypeMeta);
    }
    if (data.containsKey('trap_type')) {
      context.handle(
        _trapTypeMeta,
        trapType.isAcceptableOrUnknown(data['trap_type']!, _trapTypeMeta),
      );
    }
    if (data.containsKey('correct_option')) {
      context.handle(
        _correctOptionMeta,
        correctOption.isAcceptableOrUnknown(
          data['correct_option']!,
          _correctOptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctOptionMeta);
    }
    if (data.containsKey('concept_anchor')) {
      context.handle(
        _conceptAnchorMeta,
        conceptAnchor.isAcceptableOrUnknown(
          data['concept_anchor']!,
          _conceptAnchorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conceptAnchorMeta);
    }
    if (data.containsKey('concepts_used')) {
      context.handle(
        _conceptsUsedMeta,
        conceptsUsed.isAcceptableOrUnknown(
          data['concepts_used']!,
          _conceptsUsedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conceptsUsedMeta);
    }
    if (data.containsKey('en_display_text')) {
      context.handle(
        _enDisplayTextMeta,
        enDisplayText.isAcceptableOrUnknown(
          data['en_display_text']!,
          _enDisplayTextMeta,
        ),
      );
    }
    if (data.containsKey('hi_display_text')) {
      context.handle(
        _hiDisplayTextMeta,
        hiDisplayText.isAcceptableOrUnknown(
          data['hi_display_text']!,
          _hiDisplayTextMeta,
        ),
      );
    }
    if (data.containsKey('has_table')) {
      context.handle(
        _hasTableMeta,
        hasTable.isAcceptableOrUnknown(data['has_table']!, _hasTableMeta),
      );
    }
    if (data.containsKey('negative_framing')) {
      context.handle(
        _negativeFramingMeta,
        negativeFraming.isAcceptableOrUnknown(
          data['negative_framing']!,
          _negativeFramingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Question map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Question(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      subTopic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_topic'],
      )!,
      questionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_type'],
      )!,
      trapType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trap_type'],
      ),
      correctOption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_option'],
      )!,
      conceptAnchor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_anchor'],
      )!,
      conceptsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concepts_used'],
      )!,
      enDisplayText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}en_display_text'],
      ),
      hiDisplayText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hi_display_text'],
      ),
      hasTable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_table'],
      )!,
      negativeFraming: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}negative_framing'],
      )!,
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class Question extends DataClass implements Insertable<Question> {
  final String uuid;
  final String subject;
  final String topic;
  final String subTopic;
  final String questionType;
  final String? trapType;
  final String correctOption;
  final String conceptAnchor;
  final String conceptsUsed;
  final String? enDisplayText;
  final String? hiDisplayText;
  final bool hasTable;
  final bool negativeFraming;
  const Question({
    required this.uuid,
    required this.subject,
    required this.topic,
    required this.subTopic,
    required this.questionType,
    this.trapType,
    required this.correctOption,
    required this.conceptAnchor,
    required this.conceptsUsed,
    this.enDisplayText,
    this.hiDisplayText,
    required this.hasTable,
    required this.negativeFraming,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['subject'] = Variable<String>(subject);
    map['topic'] = Variable<String>(topic);
    map['sub_topic'] = Variable<String>(subTopic);
    map['question_type'] = Variable<String>(questionType);
    if (!nullToAbsent || trapType != null) {
      map['trap_type'] = Variable<String>(trapType);
    }
    map['correct_option'] = Variable<String>(correctOption);
    map['concept_anchor'] = Variable<String>(conceptAnchor);
    map['concepts_used'] = Variable<String>(conceptsUsed);
    if (!nullToAbsent || enDisplayText != null) {
      map['en_display_text'] = Variable<String>(enDisplayText);
    }
    if (!nullToAbsent || hiDisplayText != null) {
      map['hi_display_text'] = Variable<String>(hiDisplayText);
    }
    map['has_table'] = Variable<bool>(hasTable);
    map['negative_framing'] = Variable<bool>(negativeFraming);
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      uuid: Value(uuid),
      subject: Value(subject),
      topic: Value(topic),
      subTopic: Value(subTopic),
      questionType: Value(questionType),
      trapType: trapType == null && nullToAbsent
          ? const Value.absent()
          : Value(trapType),
      correctOption: Value(correctOption),
      conceptAnchor: Value(conceptAnchor),
      conceptsUsed: Value(conceptsUsed),
      enDisplayText: enDisplayText == null && nullToAbsent
          ? const Value.absent()
          : Value(enDisplayText),
      hiDisplayText: hiDisplayText == null && nullToAbsent
          ? const Value.absent()
          : Value(hiDisplayText),
      hasTable: Value(hasTable),
      negativeFraming: Value(negativeFraming),
    );
  }

  factory Question.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Question(
      uuid: serializer.fromJson<String>(json['uuid']),
      subject: serializer.fromJson<String>(json['subject']),
      topic: serializer.fromJson<String>(json['topic']),
      subTopic: serializer.fromJson<String>(json['subTopic']),
      questionType: serializer.fromJson<String>(json['questionType']),
      trapType: serializer.fromJson<String?>(json['trapType']),
      correctOption: serializer.fromJson<String>(json['correctOption']),
      conceptAnchor: serializer.fromJson<String>(json['conceptAnchor']),
      conceptsUsed: serializer.fromJson<String>(json['conceptsUsed']),
      enDisplayText: serializer.fromJson<String?>(json['enDisplayText']),
      hiDisplayText: serializer.fromJson<String?>(json['hiDisplayText']),
      hasTable: serializer.fromJson<bool>(json['hasTable']),
      negativeFraming: serializer.fromJson<bool>(json['negativeFraming']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'subject': serializer.toJson<String>(subject),
      'topic': serializer.toJson<String>(topic),
      'subTopic': serializer.toJson<String>(subTopic),
      'questionType': serializer.toJson<String>(questionType),
      'trapType': serializer.toJson<String?>(trapType),
      'correctOption': serializer.toJson<String>(correctOption),
      'conceptAnchor': serializer.toJson<String>(conceptAnchor),
      'conceptsUsed': serializer.toJson<String>(conceptsUsed),
      'enDisplayText': serializer.toJson<String?>(enDisplayText),
      'hiDisplayText': serializer.toJson<String?>(hiDisplayText),
      'hasTable': serializer.toJson<bool>(hasTable),
      'negativeFraming': serializer.toJson<bool>(negativeFraming),
    };
  }

  Question copyWith({
    String? uuid,
    String? subject,
    String? topic,
    String? subTopic,
    String? questionType,
    Value<String?> trapType = const Value.absent(),
    String? correctOption,
    String? conceptAnchor,
    String? conceptsUsed,
    Value<String?> enDisplayText = const Value.absent(),
    Value<String?> hiDisplayText = const Value.absent(),
    bool? hasTable,
    bool? negativeFraming,
  }) => Question(
    uuid: uuid ?? this.uuid,
    subject: subject ?? this.subject,
    topic: topic ?? this.topic,
    subTopic: subTopic ?? this.subTopic,
    questionType: questionType ?? this.questionType,
    trapType: trapType.present ? trapType.value : this.trapType,
    correctOption: correctOption ?? this.correctOption,
    conceptAnchor: conceptAnchor ?? this.conceptAnchor,
    conceptsUsed: conceptsUsed ?? this.conceptsUsed,
    enDisplayText: enDisplayText.present
        ? enDisplayText.value
        : this.enDisplayText,
    hiDisplayText: hiDisplayText.present
        ? hiDisplayText.value
        : this.hiDisplayText,
    hasTable: hasTable ?? this.hasTable,
    negativeFraming: negativeFraming ?? this.negativeFraming,
  );
  Question copyWithCompanion(QuestionsCompanion data) {
    return Question(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      subject: data.subject.present ? data.subject.value : this.subject,
      topic: data.topic.present ? data.topic.value : this.topic,
      subTopic: data.subTopic.present ? data.subTopic.value : this.subTopic,
      questionType: data.questionType.present
          ? data.questionType.value
          : this.questionType,
      trapType: data.trapType.present ? data.trapType.value : this.trapType,
      correctOption: data.correctOption.present
          ? data.correctOption.value
          : this.correctOption,
      conceptAnchor: data.conceptAnchor.present
          ? data.conceptAnchor.value
          : this.conceptAnchor,
      conceptsUsed: data.conceptsUsed.present
          ? data.conceptsUsed.value
          : this.conceptsUsed,
      enDisplayText: data.enDisplayText.present
          ? data.enDisplayText.value
          : this.enDisplayText,
      hiDisplayText: data.hiDisplayText.present
          ? data.hiDisplayText.value
          : this.hiDisplayText,
      hasTable: data.hasTable.present ? data.hasTable.value : this.hasTable,
      negativeFraming: data.negativeFraming.present
          ? data.negativeFraming.value
          : this.negativeFraming,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Question(')
          ..write('uuid: $uuid, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('subTopic: $subTopic, ')
          ..write('questionType: $questionType, ')
          ..write('trapType: $trapType, ')
          ..write('correctOption: $correctOption, ')
          ..write('conceptAnchor: $conceptAnchor, ')
          ..write('conceptsUsed: $conceptsUsed, ')
          ..write('enDisplayText: $enDisplayText, ')
          ..write('hiDisplayText: $hiDisplayText, ')
          ..write('hasTable: $hasTable, ')
          ..write('negativeFraming: $negativeFraming')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    subject,
    topic,
    subTopic,
    questionType,
    trapType,
    correctOption,
    conceptAnchor,
    conceptsUsed,
    enDisplayText,
    hiDisplayText,
    hasTable,
    negativeFraming,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Question &&
          other.uuid == this.uuid &&
          other.subject == this.subject &&
          other.topic == this.topic &&
          other.subTopic == this.subTopic &&
          other.questionType == this.questionType &&
          other.trapType == this.trapType &&
          other.correctOption == this.correctOption &&
          other.conceptAnchor == this.conceptAnchor &&
          other.conceptsUsed == this.conceptsUsed &&
          other.enDisplayText == this.enDisplayText &&
          other.hiDisplayText == this.hiDisplayText &&
          other.hasTable == this.hasTable &&
          other.negativeFraming == this.negativeFraming);
}

class QuestionsCompanion extends UpdateCompanion<Question> {
  final Value<String> uuid;
  final Value<String> subject;
  final Value<String> topic;
  final Value<String> subTopic;
  final Value<String> questionType;
  final Value<String?> trapType;
  final Value<String> correctOption;
  final Value<String> conceptAnchor;
  final Value<String> conceptsUsed;
  final Value<String?> enDisplayText;
  final Value<String?> hiDisplayText;
  final Value<bool> hasTable;
  final Value<bool> negativeFraming;
  final Value<int> rowid;
  const QuestionsCompanion({
    this.uuid = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.subTopic = const Value.absent(),
    this.questionType = const Value.absent(),
    this.trapType = const Value.absent(),
    this.correctOption = const Value.absent(),
    this.conceptAnchor = const Value.absent(),
    this.conceptsUsed = const Value.absent(),
    this.enDisplayText = const Value.absent(),
    this.hiDisplayText = const Value.absent(),
    this.hasTable = const Value.absent(),
    this.negativeFraming = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionsCompanion.insert({
    required String uuid,
    required String subject,
    required String topic,
    required String subTopic,
    required String questionType,
    this.trapType = const Value.absent(),
    required String correctOption,
    required String conceptAnchor,
    required String conceptsUsed,
    this.enDisplayText = const Value.absent(),
    this.hiDisplayText = const Value.absent(),
    this.hasTable = const Value.absent(),
    this.negativeFraming = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       subject = Value(subject),
       topic = Value(topic),
       subTopic = Value(subTopic),
       questionType = Value(questionType),
       correctOption = Value(correctOption),
       conceptAnchor = Value(conceptAnchor),
       conceptsUsed = Value(conceptsUsed);
  static Insertable<Question> custom({
    Expression<String>? uuid,
    Expression<String>? subject,
    Expression<String>? topic,
    Expression<String>? subTopic,
    Expression<String>? questionType,
    Expression<String>? trapType,
    Expression<String>? correctOption,
    Expression<String>? conceptAnchor,
    Expression<String>? conceptsUsed,
    Expression<String>? enDisplayText,
    Expression<String>? hiDisplayText,
    Expression<bool>? hasTable,
    Expression<bool>? negativeFraming,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (subTopic != null) 'sub_topic': subTopic,
      if (questionType != null) 'question_type': questionType,
      if (trapType != null) 'trap_type': trapType,
      if (correctOption != null) 'correct_option': correctOption,
      if (conceptAnchor != null) 'concept_anchor': conceptAnchor,
      if (conceptsUsed != null) 'concepts_used': conceptsUsed,
      if (enDisplayText != null) 'en_display_text': enDisplayText,
      if (hiDisplayText != null) 'hi_display_text': hiDisplayText,
      if (hasTable != null) 'has_table': hasTable,
      if (negativeFraming != null) 'negative_framing': negativeFraming,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionsCompanion copyWith({
    Value<String>? uuid,
    Value<String>? subject,
    Value<String>? topic,
    Value<String>? subTopic,
    Value<String>? questionType,
    Value<String?>? trapType,
    Value<String>? correctOption,
    Value<String>? conceptAnchor,
    Value<String>? conceptsUsed,
    Value<String?>? enDisplayText,
    Value<String?>? hiDisplayText,
    Value<bool>? hasTable,
    Value<bool>? negativeFraming,
    Value<int>? rowid,
  }) {
    return QuestionsCompanion(
      uuid: uuid ?? this.uuid,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subTopic: subTopic ?? this.subTopic,
      questionType: questionType ?? this.questionType,
      trapType: trapType ?? this.trapType,
      correctOption: correctOption ?? this.correctOption,
      conceptAnchor: conceptAnchor ?? this.conceptAnchor,
      conceptsUsed: conceptsUsed ?? this.conceptsUsed,
      enDisplayText: enDisplayText ?? this.enDisplayText,
      hiDisplayText: hiDisplayText ?? this.hiDisplayText,
      hasTable: hasTable ?? this.hasTable,
      negativeFraming: negativeFraming ?? this.negativeFraming,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (subTopic.present) {
      map['sub_topic'] = Variable<String>(subTopic.value);
    }
    if (questionType.present) {
      map['question_type'] = Variable<String>(questionType.value);
    }
    if (trapType.present) {
      map['trap_type'] = Variable<String>(trapType.value);
    }
    if (correctOption.present) {
      map['correct_option'] = Variable<String>(correctOption.value);
    }
    if (conceptAnchor.present) {
      map['concept_anchor'] = Variable<String>(conceptAnchor.value);
    }
    if (conceptsUsed.present) {
      map['concepts_used'] = Variable<String>(conceptsUsed.value);
    }
    if (enDisplayText.present) {
      map['en_display_text'] = Variable<String>(enDisplayText.value);
    }
    if (hiDisplayText.present) {
      map['hi_display_text'] = Variable<String>(hiDisplayText.value);
    }
    if (hasTable.present) {
      map['has_table'] = Variable<bool>(hasTable.value);
    }
    if (negativeFraming.present) {
      map['negative_framing'] = Variable<bool>(negativeFraming.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('subTopic: $subTopic, ')
          ..write('questionType: $questionType, ')
          ..write('trapType: $trapType, ')
          ..write('correctOption: $correctOption, ')
          ..write('conceptAnchor: $conceptAnchor, ')
          ..write('conceptsUsed: $conceptsUsed, ')
          ..write('enDisplayText: $enDisplayText, ')
          ..write('hiDisplayText: $hiDisplayText, ')
          ..write('hasTable: $hasTable, ')
          ..write('negativeFraming: $negativeFraming, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionTranslationsTable extends QuestionTranslations
    with TableInfo<$QuestionTranslationsTable, QuestionTranslation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionTranslationsTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES questions (uuid)',
    ),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strongDistractorMeta = const VerificationMeta(
    'strongDistractor',
  );
  @override
  late final GeneratedColumn<String> strongDistractor = GeneratedColumn<String>(
    'strong_distractor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eliminationLogicMeta = const VerificationMeta(
    'eliminationLogic',
  );
  @override
  late final GeneratedColumn<String> eliminationLogic = GeneratedColumn<String>(
    'elimination_logic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _upscTrapExplanationMeta =
      const VerificationMeta('upscTrapExplanation');
  @override
  late final GeneratedColumn<String> upscTrapExplanation =
      GeneratedColumn<String>(
        'upsc_trap_explanation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _finalExplanationMeta = const VerificationMeta(
    'finalExplanation',
  );
  @override
  late final GeneratedColumn<String> finalExplanation = GeneratedColumn<String>(
    'final_explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statementAnalysisMeta = const VerificationMeta(
    'statementAnalysis',
  );
  @override
  late final GeneratedColumn<String> statementAnalysis =
      GeneratedColumn<String>(
        'statement_analysis',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    questionUuid,
    language,
    strongDistractor,
    eliminationLogic,
    upscTrapExplanation,
    finalExplanation,
    statementAnalysis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'explanations';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionTranslation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('strong_distractor')) {
      context.handle(
        _strongDistractorMeta,
        strongDistractor.isAcceptableOrUnknown(
          data['strong_distractor']!,
          _strongDistractorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strongDistractorMeta);
    }
    if (data.containsKey('elimination_logic')) {
      context.handle(
        _eliminationLogicMeta,
        eliminationLogic.isAcceptableOrUnknown(
          data['elimination_logic']!,
          _eliminationLogicMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eliminationLogicMeta);
    }
    if (data.containsKey('upsc_trap_explanation')) {
      context.handle(
        _upscTrapExplanationMeta,
        upscTrapExplanation.isAcceptableOrUnknown(
          data['upsc_trap_explanation']!,
          _upscTrapExplanationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_upscTrapExplanationMeta);
    }
    if (data.containsKey('final_explanation')) {
      context.handle(
        _finalExplanationMeta,
        finalExplanation.isAcceptableOrUnknown(
          data['final_explanation']!,
          _finalExplanationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_finalExplanationMeta);
    }
    if (data.containsKey('statement_analysis')) {
      context.handle(
        _statementAnalysisMeta,
        statementAnalysis.isAcceptableOrUnknown(
          data['statement_analysis']!,
          _statementAnalysisMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {questionUuid, language},
  ];
  @override
  QuestionTranslation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionTranslation(
      questionUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_uuid'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      strongDistractor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strong_distractor'],
      )!,
      eliminationLogic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}elimination_logic'],
      )!,
      upscTrapExplanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upsc_trap_explanation'],
      )!,
      finalExplanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_explanation'],
      )!,
      statementAnalysis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statement_analysis'],
      ),
    );
  }

  @override
  $QuestionTranslationsTable createAlias(String alias) {
    return $QuestionTranslationsTable(attachedDatabase, alias);
  }
}

class QuestionTranslation extends DataClass
    implements Insertable<QuestionTranslation> {
  final String questionUuid;
  final String language;
  final String strongDistractor;
  final String eliminationLogic;
  final String upscTrapExplanation;
  final String finalExplanation;
  final String? statementAnalysis;
  const QuestionTranslation({
    required this.questionUuid,
    required this.language,
    required this.strongDistractor,
    required this.eliminationLogic,
    required this.upscTrapExplanation,
    required this.finalExplanation,
    this.statementAnalysis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_uuid'] = Variable<String>(questionUuid);
    map['language'] = Variable<String>(language);
    map['strong_distractor'] = Variable<String>(strongDistractor);
    map['elimination_logic'] = Variable<String>(eliminationLogic);
    map['upsc_trap_explanation'] = Variable<String>(upscTrapExplanation);
    map['final_explanation'] = Variable<String>(finalExplanation);
    if (!nullToAbsent || statementAnalysis != null) {
      map['statement_analysis'] = Variable<String>(statementAnalysis);
    }
    return map;
  }

  QuestionTranslationsCompanion toCompanion(bool nullToAbsent) {
    return QuestionTranslationsCompanion(
      questionUuid: Value(questionUuid),
      language: Value(language),
      strongDistractor: Value(strongDistractor),
      eliminationLogic: Value(eliminationLogic),
      upscTrapExplanation: Value(upscTrapExplanation),
      finalExplanation: Value(finalExplanation),
      statementAnalysis: statementAnalysis == null && nullToAbsent
          ? const Value.absent()
          : Value(statementAnalysis),
    );
  }

  factory QuestionTranslation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionTranslation(
      questionUuid: serializer.fromJson<String>(json['questionUuid']),
      language: serializer.fromJson<String>(json['language']),
      strongDistractor: serializer.fromJson<String>(json['strongDistractor']),
      eliminationLogic: serializer.fromJson<String>(json['eliminationLogic']),
      upscTrapExplanation: serializer.fromJson<String>(
        json['upscTrapExplanation'],
      ),
      finalExplanation: serializer.fromJson<String>(json['finalExplanation']),
      statementAnalysis: serializer.fromJson<String?>(
        json['statementAnalysis'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionUuid': serializer.toJson<String>(questionUuid),
      'language': serializer.toJson<String>(language),
      'strongDistractor': serializer.toJson<String>(strongDistractor),
      'eliminationLogic': serializer.toJson<String>(eliminationLogic),
      'upscTrapExplanation': serializer.toJson<String>(upscTrapExplanation),
      'finalExplanation': serializer.toJson<String>(finalExplanation),
      'statementAnalysis': serializer.toJson<String?>(statementAnalysis),
    };
  }

  QuestionTranslation copyWith({
    String? questionUuid,
    String? language,
    String? strongDistractor,
    String? eliminationLogic,
    String? upscTrapExplanation,
    String? finalExplanation,
    Value<String?> statementAnalysis = const Value.absent(),
  }) => QuestionTranslation(
    questionUuid: questionUuid ?? this.questionUuid,
    language: language ?? this.language,
    strongDistractor: strongDistractor ?? this.strongDistractor,
    eliminationLogic: eliminationLogic ?? this.eliminationLogic,
    upscTrapExplanation: upscTrapExplanation ?? this.upscTrapExplanation,
    finalExplanation: finalExplanation ?? this.finalExplanation,
    statementAnalysis: statementAnalysis.present
        ? statementAnalysis.value
        : this.statementAnalysis,
  );
  QuestionTranslation copyWithCompanion(QuestionTranslationsCompanion data) {
    return QuestionTranslation(
      questionUuid: data.questionUuid.present
          ? data.questionUuid.value
          : this.questionUuid,
      language: data.language.present ? data.language.value : this.language,
      strongDistractor: data.strongDistractor.present
          ? data.strongDistractor.value
          : this.strongDistractor,
      eliminationLogic: data.eliminationLogic.present
          ? data.eliminationLogic.value
          : this.eliminationLogic,
      upscTrapExplanation: data.upscTrapExplanation.present
          ? data.upscTrapExplanation.value
          : this.upscTrapExplanation,
      finalExplanation: data.finalExplanation.present
          ? data.finalExplanation.value
          : this.finalExplanation,
      statementAnalysis: data.statementAnalysis.present
          ? data.statementAnalysis.value
          : this.statementAnalysis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionTranslation(')
          ..write('questionUuid: $questionUuid, ')
          ..write('language: $language, ')
          ..write('strongDistractor: $strongDistractor, ')
          ..write('eliminationLogic: $eliminationLogic, ')
          ..write('upscTrapExplanation: $upscTrapExplanation, ')
          ..write('finalExplanation: $finalExplanation, ')
          ..write('statementAnalysis: $statementAnalysis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    questionUuid,
    language,
    strongDistractor,
    eliminationLogic,
    upscTrapExplanation,
    finalExplanation,
    statementAnalysis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionTranslation &&
          other.questionUuid == this.questionUuid &&
          other.language == this.language &&
          other.strongDistractor == this.strongDistractor &&
          other.eliminationLogic == this.eliminationLogic &&
          other.upscTrapExplanation == this.upscTrapExplanation &&
          other.finalExplanation == this.finalExplanation &&
          other.statementAnalysis == this.statementAnalysis);
}

class QuestionTranslationsCompanion
    extends UpdateCompanion<QuestionTranslation> {
  final Value<String> questionUuid;
  final Value<String> language;
  final Value<String> strongDistractor;
  final Value<String> eliminationLogic;
  final Value<String> upscTrapExplanation;
  final Value<String> finalExplanation;
  final Value<String?> statementAnalysis;
  final Value<int> rowid;
  const QuestionTranslationsCompanion({
    this.questionUuid = const Value.absent(),
    this.language = const Value.absent(),
    this.strongDistractor = const Value.absent(),
    this.eliminationLogic = const Value.absent(),
    this.upscTrapExplanation = const Value.absent(),
    this.finalExplanation = const Value.absent(),
    this.statementAnalysis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionTranslationsCompanion.insert({
    required String questionUuid,
    required String language,
    required String strongDistractor,
    required String eliminationLogic,
    required String upscTrapExplanation,
    required String finalExplanation,
    this.statementAnalysis = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : questionUuid = Value(questionUuid),
       language = Value(language),
       strongDistractor = Value(strongDistractor),
       eliminationLogic = Value(eliminationLogic),
       upscTrapExplanation = Value(upscTrapExplanation),
       finalExplanation = Value(finalExplanation);
  static Insertable<QuestionTranslation> custom({
    Expression<String>? questionUuid,
    Expression<String>? language,
    Expression<String>? strongDistractor,
    Expression<String>? eliminationLogic,
    Expression<String>? upscTrapExplanation,
    Expression<String>? finalExplanation,
    Expression<String>? statementAnalysis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionUuid != null) 'question_uuid': questionUuid,
      if (language != null) 'language': language,
      if (strongDistractor != null) 'strong_distractor': strongDistractor,
      if (eliminationLogic != null) 'elimination_logic': eliminationLogic,
      if (upscTrapExplanation != null)
        'upsc_trap_explanation': upscTrapExplanation,
      if (finalExplanation != null) 'final_explanation': finalExplanation,
      if (statementAnalysis != null) 'statement_analysis': statementAnalysis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionTranslationsCompanion copyWith({
    Value<String>? questionUuid,
    Value<String>? language,
    Value<String>? strongDistractor,
    Value<String>? eliminationLogic,
    Value<String>? upscTrapExplanation,
    Value<String>? finalExplanation,
    Value<String?>? statementAnalysis,
    Value<int>? rowid,
  }) {
    return QuestionTranslationsCompanion(
      questionUuid: questionUuid ?? this.questionUuid,
      language: language ?? this.language,
      strongDistractor: strongDistractor ?? this.strongDistractor,
      eliminationLogic: eliminationLogic ?? this.eliminationLogic,
      upscTrapExplanation: upscTrapExplanation ?? this.upscTrapExplanation,
      finalExplanation: finalExplanation ?? this.finalExplanation,
      statementAnalysis: statementAnalysis ?? this.statementAnalysis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionUuid.present) {
      map['question_uuid'] = Variable<String>(questionUuid.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (strongDistractor.present) {
      map['strong_distractor'] = Variable<String>(strongDistractor.value);
    }
    if (eliminationLogic.present) {
      map['elimination_logic'] = Variable<String>(eliminationLogic.value);
    }
    if (upscTrapExplanation.present) {
      map['upsc_trap_explanation'] = Variable<String>(
        upscTrapExplanation.value,
      );
    }
    if (finalExplanation.present) {
      map['final_explanation'] = Variable<String>(finalExplanation.value);
    }
    if (statementAnalysis.present) {
      map['statement_analysis'] = Variable<String>(statementAnalysis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionTranslationsCompanion(')
          ..write('questionUuid: $questionUuid, ')
          ..write('language: $language, ')
          ..write('strongDistractor: $strongDistractor, ')
          ..write('eliminationLogic: $eliminationLogic, ')
          ..write('upscTrapExplanation: $upscTrapExplanation, ')
          ..write('finalExplanation: $finalExplanation, ')
          ..write('statementAnalysis: $statementAnalysis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionTablesTable extends QuestionTables
    with TableInfo<$QuestionTablesTable, QuestionTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES questions (uuid)',
    ),
  );
  static const VerificationMeta _enHeaderTextMeta = const VerificationMeta(
    'enHeaderText',
  );
  @override
  late final GeneratedColumn<String> enHeaderText = GeneratedColumn<String>(
    'en_header_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enFooterTextMeta = const VerificationMeta(
    'enFooterText',
  );
  @override
  late final GeneratedColumn<String> enFooterText = GeneratedColumn<String>(
    'en_footer_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enColumnsMeta = const VerificationMeta(
    'enColumns',
  );
  @override
  late final GeneratedColumn<String> enColumns = GeneratedColumn<String>(
    'en_columns',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enRowsMeta = const VerificationMeta('enRows');
  @override
  late final GeneratedColumn<String> enRows = GeneratedColumn<String>(
    'en_rows',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hiHeaderTextMeta = const VerificationMeta(
    'hiHeaderText',
  );
  @override
  late final GeneratedColumn<String> hiHeaderText = GeneratedColumn<String>(
    'hi_header_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiFooterTextMeta = const VerificationMeta(
    'hiFooterText',
  );
  @override
  late final GeneratedColumn<String> hiFooterText = GeneratedColumn<String>(
    'hi_footer_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiColumnsMeta = const VerificationMeta(
    'hiColumns',
  );
  @override
  late final GeneratedColumn<String> hiColumns = GeneratedColumn<String>(
    'hi_columns',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hiRowsMeta = const VerificationMeta('hiRows');
  @override
  late final GeneratedColumn<String> hiRows = GeneratedColumn<String>(
    'hi_rows',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionUuid,
    enHeaderText,
    enFooterText,
    enColumns,
    enRows,
    hiHeaderText,
    hiFooterText,
    hiColumns,
    hiRows,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('en_header_text')) {
      context.handle(
        _enHeaderTextMeta,
        enHeaderText.isAcceptableOrUnknown(
          data['en_header_text']!,
          _enHeaderTextMeta,
        ),
      );
    }
    if (data.containsKey('en_footer_text')) {
      context.handle(
        _enFooterTextMeta,
        enFooterText.isAcceptableOrUnknown(
          data['en_footer_text']!,
          _enFooterTextMeta,
        ),
      );
    }
    if (data.containsKey('en_columns')) {
      context.handle(
        _enColumnsMeta,
        enColumns.isAcceptableOrUnknown(data['en_columns']!, _enColumnsMeta),
      );
    } else if (isInserting) {
      context.missing(_enColumnsMeta);
    }
    if (data.containsKey('en_rows')) {
      context.handle(
        _enRowsMeta,
        enRows.isAcceptableOrUnknown(data['en_rows']!, _enRowsMeta),
      );
    } else if (isInserting) {
      context.missing(_enRowsMeta);
    }
    if (data.containsKey('hi_header_text')) {
      context.handle(
        _hiHeaderTextMeta,
        hiHeaderText.isAcceptableOrUnknown(
          data['hi_header_text']!,
          _hiHeaderTextMeta,
        ),
      );
    }
    if (data.containsKey('hi_footer_text')) {
      context.handle(
        _hiFooterTextMeta,
        hiFooterText.isAcceptableOrUnknown(
          data['hi_footer_text']!,
          _hiFooterTextMeta,
        ),
      );
    }
    if (data.containsKey('hi_columns')) {
      context.handle(
        _hiColumnsMeta,
        hiColumns.isAcceptableOrUnknown(data['hi_columns']!, _hiColumnsMeta),
      );
    } else if (isInserting) {
      context.missing(_hiColumnsMeta);
    }
    if (data.containsKey('hi_rows')) {
      context.handle(
        _hiRowsMeta,
        hiRows.isAcceptableOrUnknown(data['hi_rows']!, _hiRowsMeta),
      );
    } else if (isInserting) {
      context.missing(_hiRowsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {questionUuid},
  ];
  @override
  QuestionTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_uuid'],
      )!,
      enHeaderText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}en_header_text'],
      ),
      enFooterText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}en_footer_text'],
      ),
      enColumns: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}en_columns'],
      )!,
      enRows: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}en_rows'],
      )!,
      hiHeaderText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hi_header_text'],
      ),
      hiFooterText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hi_footer_text'],
      ),
      hiColumns: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hi_columns'],
      )!,
      hiRows: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hi_rows'],
      )!,
    );
  }

  @override
  $QuestionTablesTable createAlias(String alias) {
    return $QuestionTablesTable(attachedDatabase, alias);
  }
}

class QuestionTable extends DataClass implements Insertable<QuestionTable> {
  final int id;
  final String questionUuid;
  final String? enHeaderText;
  final String? enFooterText;
  final String enColumns;
  final String enRows;
  final String? hiHeaderText;
  final String? hiFooterText;
  final String hiColumns;
  final String hiRows;
  const QuestionTable({
    required this.id,
    required this.questionUuid,
    this.enHeaderText,
    this.enFooterText,
    required this.enColumns,
    required this.enRows,
    this.hiHeaderText,
    this.hiFooterText,
    required this.hiColumns,
    required this.hiRows,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_uuid'] = Variable<String>(questionUuid);
    if (!nullToAbsent || enHeaderText != null) {
      map['en_header_text'] = Variable<String>(enHeaderText);
    }
    if (!nullToAbsent || enFooterText != null) {
      map['en_footer_text'] = Variable<String>(enFooterText);
    }
    map['en_columns'] = Variable<String>(enColumns);
    map['en_rows'] = Variable<String>(enRows);
    if (!nullToAbsent || hiHeaderText != null) {
      map['hi_header_text'] = Variable<String>(hiHeaderText);
    }
    if (!nullToAbsent || hiFooterText != null) {
      map['hi_footer_text'] = Variable<String>(hiFooterText);
    }
    map['hi_columns'] = Variable<String>(hiColumns);
    map['hi_rows'] = Variable<String>(hiRows);
    return map;
  }

  QuestionTablesCompanion toCompanion(bool nullToAbsent) {
    return QuestionTablesCompanion(
      id: Value(id),
      questionUuid: Value(questionUuid),
      enHeaderText: enHeaderText == null && nullToAbsent
          ? const Value.absent()
          : Value(enHeaderText),
      enFooterText: enFooterText == null && nullToAbsent
          ? const Value.absent()
          : Value(enFooterText),
      enColumns: Value(enColumns),
      enRows: Value(enRows),
      hiHeaderText: hiHeaderText == null && nullToAbsent
          ? const Value.absent()
          : Value(hiHeaderText),
      hiFooterText: hiFooterText == null && nullToAbsent
          ? const Value.absent()
          : Value(hiFooterText),
      hiColumns: Value(hiColumns),
      hiRows: Value(hiRows),
    );
  }

  factory QuestionTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionTable(
      id: serializer.fromJson<int>(json['id']),
      questionUuid: serializer.fromJson<String>(json['questionUuid']),
      enHeaderText: serializer.fromJson<String?>(json['enHeaderText']),
      enFooterText: serializer.fromJson<String?>(json['enFooterText']),
      enColumns: serializer.fromJson<String>(json['enColumns']),
      enRows: serializer.fromJson<String>(json['enRows']),
      hiHeaderText: serializer.fromJson<String?>(json['hiHeaderText']),
      hiFooterText: serializer.fromJson<String?>(json['hiFooterText']),
      hiColumns: serializer.fromJson<String>(json['hiColumns']),
      hiRows: serializer.fromJson<String>(json['hiRows']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionUuid': serializer.toJson<String>(questionUuid),
      'enHeaderText': serializer.toJson<String?>(enHeaderText),
      'enFooterText': serializer.toJson<String?>(enFooterText),
      'enColumns': serializer.toJson<String>(enColumns),
      'enRows': serializer.toJson<String>(enRows),
      'hiHeaderText': serializer.toJson<String?>(hiHeaderText),
      'hiFooterText': serializer.toJson<String?>(hiFooterText),
      'hiColumns': serializer.toJson<String>(hiColumns),
      'hiRows': serializer.toJson<String>(hiRows),
    };
  }

  QuestionTable copyWith({
    int? id,
    String? questionUuid,
    Value<String?> enHeaderText = const Value.absent(),
    Value<String?> enFooterText = const Value.absent(),
    String? enColumns,
    String? enRows,
    Value<String?> hiHeaderText = const Value.absent(),
    Value<String?> hiFooterText = const Value.absent(),
    String? hiColumns,
    String? hiRows,
  }) => QuestionTable(
    id: id ?? this.id,
    questionUuid: questionUuid ?? this.questionUuid,
    enHeaderText: enHeaderText.present ? enHeaderText.value : this.enHeaderText,
    enFooterText: enFooterText.present ? enFooterText.value : this.enFooterText,
    enColumns: enColumns ?? this.enColumns,
    enRows: enRows ?? this.enRows,
    hiHeaderText: hiHeaderText.present ? hiHeaderText.value : this.hiHeaderText,
    hiFooterText: hiFooterText.present ? hiFooterText.value : this.hiFooterText,
    hiColumns: hiColumns ?? this.hiColumns,
    hiRows: hiRows ?? this.hiRows,
  );
  QuestionTable copyWithCompanion(QuestionTablesCompanion data) {
    return QuestionTable(
      id: data.id.present ? data.id.value : this.id,
      questionUuid: data.questionUuid.present
          ? data.questionUuid.value
          : this.questionUuid,
      enHeaderText: data.enHeaderText.present
          ? data.enHeaderText.value
          : this.enHeaderText,
      enFooterText: data.enFooterText.present
          ? data.enFooterText.value
          : this.enFooterText,
      enColumns: data.enColumns.present ? data.enColumns.value : this.enColumns,
      enRows: data.enRows.present ? data.enRows.value : this.enRows,
      hiHeaderText: data.hiHeaderText.present
          ? data.hiHeaderText.value
          : this.hiHeaderText,
      hiFooterText: data.hiFooterText.present
          ? data.hiFooterText.value
          : this.hiFooterText,
      hiColumns: data.hiColumns.present ? data.hiColumns.value : this.hiColumns,
      hiRows: data.hiRows.present ? data.hiRows.value : this.hiRows,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionTable(')
          ..write('id: $id, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('enHeaderText: $enHeaderText, ')
          ..write('enFooterText: $enFooterText, ')
          ..write('enColumns: $enColumns, ')
          ..write('enRows: $enRows, ')
          ..write('hiHeaderText: $hiHeaderText, ')
          ..write('hiFooterText: $hiFooterText, ')
          ..write('hiColumns: $hiColumns, ')
          ..write('hiRows: $hiRows')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questionUuid,
    enHeaderText,
    enFooterText,
    enColumns,
    enRows,
    hiHeaderText,
    hiFooterText,
    hiColumns,
    hiRows,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionTable &&
          other.id == this.id &&
          other.questionUuid == this.questionUuid &&
          other.enHeaderText == this.enHeaderText &&
          other.enFooterText == this.enFooterText &&
          other.enColumns == this.enColumns &&
          other.enRows == this.enRows &&
          other.hiHeaderText == this.hiHeaderText &&
          other.hiFooterText == this.hiFooterText &&
          other.hiColumns == this.hiColumns &&
          other.hiRows == this.hiRows);
}

class QuestionTablesCompanion extends UpdateCompanion<QuestionTable> {
  final Value<int> id;
  final Value<String> questionUuid;
  final Value<String?> enHeaderText;
  final Value<String?> enFooterText;
  final Value<String> enColumns;
  final Value<String> enRows;
  final Value<String?> hiHeaderText;
  final Value<String?> hiFooterText;
  final Value<String> hiColumns;
  final Value<String> hiRows;
  const QuestionTablesCompanion({
    this.id = const Value.absent(),
    this.questionUuid = const Value.absent(),
    this.enHeaderText = const Value.absent(),
    this.enFooterText = const Value.absent(),
    this.enColumns = const Value.absent(),
    this.enRows = const Value.absent(),
    this.hiHeaderText = const Value.absent(),
    this.hiFooterText = const Value.absent(),
    this.hiColumns = const Value.absent(),
    this.hiRows = const Value.absent(),
  });
  QuestionTablesCompanion.insert({
    this.id = const Value.absent(),
    required String questionUuid,
    this.enHeaderText = const Value.absent(),
    this.enFooterText = const Value.absent(),
    required String enColumns,
    required String enRows,
    this.hiHeaderText = const Value.absent(),
    this.hiFooterText = const Value.absent(),
    required String hiColumns,
    required String hiRows,
  }) : questionUuid = Value(questionUuid),
       enColumns = Value(enColumns),
       enRows = Value(enRows),
       hiColumns = Value(hiColumns),
       hiRows = Value(hiRows);
  static Insertable<QuestionTable> custom({
    Expression<int>? id,
    Expression<String>? questionUuid,
    Expression<String>? enHeaderText,
    Expression<String>? enFooterText,
    Expression<String>? enColumns,
    Expression<String>? enRows,
    Expression<String>? hiHeaderText,
    Expression<String>? hiFooterText,
    Expression<String>? hiColumns,
    Expression<String>? hiRows,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionUuid != null) 'question_uuid': questionUuid,
      if (enHeaderText != null) 'en_header_text': enHeaderText,
      if (enFooterText != null) 'en_footer_text': enFooterText,
      if (enColumns != null) 'en_columns': enColumns,
      if (enRows != null) 'en_rows': enRows,
      if (hiHeaderText != null) 'hi_header_text': hiHeaderText,
      if (hiFooterText != null) 'hi_footer_text': hiFooterText,
      if (hiColumns != null) 'hi_columns': hiColumns,
      if (hiRows != null) 'hi_rows': hiRows,
    });
  }

  QuestionTablesCompanion copyWith({
    Value<int>? id,
    Value<String>? questionUuid,
    Value<String?>? enHeaderText,
    Value<String?>? enFooterText,
    Value<String>? enColumns,
    Value<String>? enRows,
    Value<String?>? hiHeaderText,
    Value<String?>? hiFooterText,
    Value<String>? hiColumns,
    Value<String>? hiRows,
  }) {
    return QuestionTablesCompanion(
      id: id ?? this.id,
      questionUuid: questionUuid ?? this.questionUuid,
      enHeaderText: enHeaderText ?? this.enHeaderText,
      enFooterText: enFooterText ?? this.enFooterText,
      enColumns: enColumns ?? this.enColumns,
      enRows: enRows ?? this.enRows,
      hiHeaderText: hiHeaderText ?? this.hiHeaderText,
      hiFooterText: hiFooterText ?? this.hiFooterText,
      hiColumns: hiColumns ?? this.hiColumns,
      hiRows: hiRows ?? this.hiRows,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionUuid.present) {
      map['question_uuid'] = Variable<String>(questionUuid.value);
    }
    if (enHeaderText.present) {
      map['en_header_text'] = Variable<String>(enHeaderText.value);
    }
    if (enFooterText.present) {
      map['en_footer_text'] = Variable<String>(enFooterText.value);
    }
    if (enColumns.present) {
      map['en_columns'] = Variable<String>(enColumns.value);
    }
    if (enRows.present) {
      map['en_rows'] = Variable<String>(enRows.value);
    }
    if (hiHeaderText.present) {
      map['hi_header_text'] = Variable<String>(hiHeaderText.value);
    }
    if (hiFooterText.present) {
      map['hi_footer_text'] = Variable<String>(hiFooterText.value);
    }
    if (hiColumns.present) {
      map['hi_columns'] = Variable<String>(hiColumns.value);
    }
    if (hiRows.present) {
      map['hi_rows'] = Variable<String>(hiRows.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionTablesCompanion(')
          ..write('id: $id, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('enHeaderText: $enHeaderText, ')
          ..write('enFooterText: $enFooterText, ')
          ..write('enColumns: $enColumns, ')
          ..write('enRows: $enRows, ')
          ..write('hiHeaderText: $hiHeaderText, ')
          ..write('hiFooterText: $hiFooterText, ')
          ..write('hiColumns: $hiColumns, ')
          ..write('hiRows: $hiRows')
          ..write(')'))
        .toString();
  }
}

class $TopicTranslationsTable extends TopicTranslations
    with TableInfo<$TopicTranslationsTable, TopicTranslation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicTranslationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _englishNameMeta = const VerificationMeta(
    'englishName',
  );
  @override
  late final GeneratedColumn<String> englishName = GeneratedColumn<String>(
    'english_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hindiNameMeta = const VerificationMeta(
    'hindiName',
  );
  @override
  late final GeneratedColumn<String> hindiName = GeneratedColumn<String>(
    'hindi_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, englishName, hindiName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_translations';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicTranslation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('english_name')) {
      context.handle(
        _englishNameMeta,
        englishName.isAcceptableOrUnknown(
          data['english_name']!,
          _englishNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_englishNameMeta);
    }
    if (data.containsKey('hindi_name')) {
      context.handle(
        _hindiNameMeta,
        hindiName.isAcceptableOrUnknown(data['hindi_name']!, _hindiNameMeta),
      );
    } else if (isInserting) {
      context.missing(_hindiNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TopicTranslation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicTranslation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      englishName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_name'],
      )!,
      hindiName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hindi_name'],
      )!,
    );
  }

  @override
  $TopicTranslationsTable createAlias(String alias) {
    return $TopicTranslationsTable(attachedDatabase, alias);
  }
}

class TopicTranslation extends DataClass
    implements Insertable<TopicTranslation> {
  final int id;
  final String englishName;
  final String hindiName;
  const TopicTranslation({
    required this.id,
    required this.englishName,
    required this.hindiName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['english_name'] = Variable<String>(englishName);
    map['hindi_name'] = Variable<String>(hindiName);
    return map;
  }

  TopicTranslationsCompanion toCompanion(bool nullToAbsent) {
    return TopicTranslationsCompanion(
      id: Value(id),
      englishName: Value(englishName),
      hindiName: Value(hindiName),
    );
  }

  factory TopicTranslation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicTranslation(
      id: serializer.fromJson<int>(json['id']),
      englishName: serializer.fromJson<String>(json['englishName']),
      hindiName: serializer.fromJson<String>(json['hindiName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'englishName': serializer.toJson<String>(englishName),
      'hindiName': serializer.toJson<String>(hindiName),
    };
  }

  TopicTranslation copyWith({
    int? id,
    String? englishName,
    String? hindiName,
  }) => TopicTranslation(
    id: id ?? this.id,
    englishName: englishName ?? this.englishName,
    hindiName: hindiName ?? this.hindiName,
  );
  TopicTranslation copyWithCompanion(TopicTranslationsCompanion data) {
    return TopicTranslation(
      id: data.id.present ? data.id.value : this.id,
      englishName: data.englishName.present
          ? data.englishName.value
          : this.englishName,
      hindiName: data.hindiName.present ? data.hindiName.value : this.hindiName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicTranslation(')
          ..write('id: $id, ')
          ..write('englishName: $englishName, ')
          ..write('hindiName: $hindiName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, englishName, hindiName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicTranslation &&
          other.id == this.id &&
          other.englishName == this.englishName &&
          other.hindiName == this.hindiName);
}

class TopicTranslationsCompanion extends UpdateCompanion<TopicTranslation> {
  final Value<int> id;
  final Value<String> englishName;
  final Value<String> hindiName;
  const TopicTranslationsCompanion({
    this.id = const Value.absent(),
    this.englishName = const Value.absent(),
    this.hindiName = const Value.absent(),
  });
  TopicTranslationsCompanion.insert({
    this.id = const Value.absent(),
    required String englishName,
    required String hindiName,
  }) : englishName = Value(englishName),
       hindiName = Value(hindiName);
  static Insertable<TopicTranslation> custom({
    Expression<int>? id,
    Expression<String>? englishName,
    Expression<String>? hindiName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (englishName != null) 'english_name': englishName,
      if (hindiName != null) 'hindi_name': hindiName,
    });
  }

  TopicTranslationsCompanion copyWith({
    Value<int>? id,
    Value<String>? englishName,
    Value<String>? hindiName,
  }) {
    return TopicTranslationsCompanion(
      id: id ?? this.id,
      englishName: englishName ?? this.englishName,
      hindiName: hindiName ?? this.hindiName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (englishName.present) {
      map['english_name'] = Variable<String>(englishName.value);
    }
    if (hindiName.present) {
      map['hindi_name'] = Variable<String>(hindiName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicTranslationsCompanion(')
          ..write('id: $id, ')
          ..write('englishName: $englishName, ')
          ..write('hindiName: $hindiName')
          ..write(')'))
        .toString();
  }
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
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subTopicMeta = const VerificationMeta(
    'subTopic',
  );
  @override
  late final GeneratedColumn<String> subTopic = GeneratedColumn<String>(
    'sub_topic',
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
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _analyticsFeatureKeyMeta =
      const VerificationMeta('analyticsFeatureKey');
  @override
  late final GeneratedColumn<String> analyticsFeatureKey =
      GeneratedColumn<String>(
        'analytics_feature_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    completedAt,
    subject,
    topic,
    subTopic,
    mode,
    status,
    questionCount,
    score,
    isTimed,
    timeLimitSecs,
    examRemainingSecs,
    language,
    analyticsFeatureKey,
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
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('sub_topic')) {
      context.handle(
        _subTopicMeta,
        subTopic.isAcceptableOrUnknown(data['sub_topic']!, _subTopicMeta),
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
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
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
    if (data.containsKey('analytics_feature_key')) {
      context.handle(
        _analyticsFeatureKeyMeta,
        analyticsFeatureKey.isAcceptableOrUnknown(
          data['analytics_feature_key']!,
          _analyticsFeatureKeyMeta,
        ),
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
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      subTopic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_topic'],
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
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
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
      analyticsFeatureKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analytics_feature_key'],
      ),
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
  final String subject;
  final String? topic;
  final String? subTopic;
  final String mode;
  final String status;
  final int questionCount;
  final int? score;
  final bool isTimed;
  final int? timeLimitSecs;
  final int? examRemainingSecs;
  final String language;
  final String? analyticsFeatureKey;
  const Session({
    required this.id,
    required this.createdAt,
    this.completedAt,
    required this.subject,
    this.topic,
    this.subTopic,
    required this.mode,
    required this.status,
    required this.questionCount,
    this.score,
    required this.isTimed,
    this.timeLimitSecs,
    this.examRemainingSecs,
    required this.language,
    this.analyticsFeatureKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['subject'] = Variable<String>(subject);
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    if (!nullToAbsent || subTopic != null) {
      map['sub_topic'] = Variable<String>(subTopic);
    }
    map['mode'] = Variable<String>(mode);
    map['status'] = Variable<String>(status);
    map['question_count'] = Variable<int>(questionCount);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    map['is_timed'] = Variable<bool>(isTimed);
    if (!nullToAbsent || timeLimitSecs != null) {
      map['time_limit_secs'] = Variable<int>(timeLimitSecs);
    }
    if (!nullToAbsent || examRemainingSecs != null) {
      map['exam_remaining_secs'] = Variable<int>(examRemainingSecs);
    }
    map['language'] = Variable<String>(language);
    if (!nullToAbsent || analyticsFeatureKey != null) {
      map['analytics_feature_key'] = Variable<String>(analyticsFeatureKey);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      subject: Value(subject),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      subTopic: subTopic == null && nullToAbsent
          ? const Value.absent()
          : Value(subTopic),
      mode: Value(mode),
      status: Value(status),
      questionCount: Value(questionCount),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      isTimed: Value(isTimed),
      timeLimitSecs: timeLimitSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(timeLimitSecs),
      examRemainingSecs: examRemainingSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(examRemainingSecs),
      language: Value(language),
      analyticsFeatureKey: analyticsFeatureKey == null && nullToAbsent
          ? const Value.absent()
          : Value(analyticsFeatureKey),
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
      subject: serializer.fromJson<String>(json['subject']),
      topic: serializer.fromJson<String?>(json['topic']),
      subTopic: serializer.fromJson<String?>(json['subTopic']),
      mode: serializer.fromJson<String>(json['mode']),
      status: serializer.fromJson<String>(json['status']),
      questionCount: serializer.fromJson<int>(json['questionCount']),
      score: serializer.fromJson<int?>(json['score']),
      isTimed: serializer.fromJson<bool>(json['isTimed']),
      timeLimitSecs: serializer.fromJson<int?>(json['timeLimitSecs']),
      examRemainingSecs: serializer.fromJson<int?>(json['examRemainingSecs']),
      language: serializer.fromJson<String>(json['language']),
      analyticsFeatureKey: serializer.fromJson<String?>(
        json['analyticsFeatureKey'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'subject': serializer.toJson<String>(subject),
      'topic': serializer.toJson<String?>(topic),
      'subTopic': serializer.toJson<String?>(subTopic),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(status),
      'questionCount': serializer.toJson<int>(questionCount),
      'score': serializer.toJson<int?>(score),
      'isTimed': serializer.toJson<bool>(isTimed),
      'timeLimitSecs': serializer.toJson<int?>(timeLimitSecs),
      'examRemainingSecs': serializer.toJson<int?>(examRemainingSecs),
      'language': serializer.toJson<String>(language),
      'analyticsFeatureKey': serializer.toJson<String?>(analyticsFeatureKey),
    };
  }

  Session copyWith({
    String? id,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    String? subject,
    Value<String?> topic = const Value.absent(),
    Value<String?> subTopic = const Value.absent(),
    String? mode,
    String? status,
    int? questionCount,
    Value<int?> score = const Value.absent(),
    bool? isTimed,
    Value<int?> timeLimitSecs = const Value.absent(),
    Value<int?> examRemainingSecs = const Value.absent(),
    String? language,
    Value<String?> analyticsFeatureKey = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    subject: subject ?? this.subject,
    topic: topic.present ? topic.value : this.topic,
    subTopic: subTopic.present ? subTopic.value : this.subTopic,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    questionCount: questionCount ?? this.questionCount,
    score: score.present ? score.value : this.score,
    isTimed: isTimed ?? this.isTimed,
    timeLimitSecs: timeLimitSecs.present
        ? timeLimitSecs.value
        : this.timeLimitSecs,
    examRemainingSecs: examRemainingSecs.present
        ? examRemainingSecs.value
        : this.examRemainingSecs,
    language: language ?? this.language,
    analyticsFeatureKey: analyticsFeatureKey.present
        ? analyticsFeatureKey.value
        : this.analyticsFeatureKey,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      subject: data.subject.present ? data.subject.value : this.subject,
      topic: data.topic.present ? data.topic.value : this.topic,
      subTopic: data.subTopic.present ? data.subTopic.value : this.subTopic,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      questionCount: data.questionCount.present
          ? data.questionCount.value
          : this.questionCount,
      score: data.score.present ? data.score.value : this.score,
      isTimed: data.isTimed.present ? data.isTimed.value : this.isTimed,
      timeLimitSecs: data.timeLimitSecs.present
          ? data.timeLimitSecs.value
          : this.timeLimitSecs,
      examRemainingSecs: data.examRemainingSecs.present
          ? data.examRemainingSecs.value
          : this.examRemainingSecs,
      language: data.language.present ? data.language.value : this.language,
      analyticsFeatureKey: data.analyticsFeatureKey.present
          ? data.analyticsFeatureKey.value
          : this.analyticsFeatureKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('subTopic: $subTopic, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('questionCount: $questionCount, ')
          ..write('score: $score, ')
          ..write('isTimed: $isTimed, ')
          ..write('timeLimitSecs: $timeLimitSecs, ')
          ..write('examRemainingSecs: $examRemainingSecs, ')
          ..write('language: $language, ')
          ..write('analyticsFeatureKey: $analyticsFeatureKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    completedAt,
    subject,
    topic,
    subTopic,
    mode,
    status,
    questionCount,
    score,
    isTimed,
    timeLimitSecs,
    examRemainingSecs,
    language,
    analyticsFeatureKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.subject == this.subject &&
          other.topic == this.topic &&
          other.subTopic == this.subTopic &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.questionCount == this.questionCount &&
          other.score == this.score &&
          other.isTimed == this.isTimed &&
          other.timeLimitSecs == this.timeLimitSecs &&
          other.examRemainingSecs == this.examRemainingSecs &&
          other.language == this.language &&
          other.analyticsFeatureKey == this.analyticsFeatureKey);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<String> subject;
  final Value<String?> topic;
  final Value<String?> subTopic;
  final Value<String> mode;
  final Value<String> status;
  final Value<int> questionCount;
  final Value<int?> score;
  final Value<bool> isTimed;
  final Value<int?> timeLimitSecs;
  final Value<int?> examRemainingSecs;
  final Value<String> language;
  final Value<String?> analyticsFeatureKey;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.subTopic = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.questionCount = const Value.absent(),
    this.score = const Value.absent(),
    this.isTimed = const Value.absent(),
    this.timeLimitSecs = const Value.absent(),
    this.examRemainingSecs = const Value.absent(),
    this.language = const Value.absent(),
    this.analyticsFeatureKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    required String subject,
    this.topic = const Value.absent(),
    this.subTopic = const Value.absent(),
    required String mode,
    required String status,
    required int questionCount,
    this.score = const Value.absent(),
    required bool isTimed,
    this.timeLimitSecs = const Value.absent(),
    this.examRemainingSecs = const Value.absent(),
    this.language = const Value.absent(),
    this.analyticsFeatureKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       subject = Value(subject),
       mode = Value(mode),
       status = Value(status),
       questionCount = Value(questionCount),
       isTimed = Value(isTimed);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<String>? subject,
    Expression<String>? topic,
    Expression<String>? subTopic,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<int>? questionCount,
    Expression<int>? score,
    Expression<bool>? isTimed,
    Expression<int>? timeLimitSecs,
    Expression<int>? examRemainingSecs,
    Expression<String>? language,
    Expression<String>? analyticsFeatureKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (subTopic != null) 'sub_topic': subTopic,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (questionCount != null) 'question_count': questionCount,
      if (score != null) 'score': score,
      if (isTimed != null) 'is_timed': isTimed,
      if (timeLimitSecs != null) 'time_limit_secs': timeLimitSecs,
      if (examRemainingSecs != null) 'exam_remaining_secs': examRemainingSecs,
      if (language != null) 'language': language,
      if (analyticsFeatureKey != null)
        'analytics_feature_key': analyticsFeatureKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<String>? subject,
    Value<String?>? topic,
    Value<String?>? subTopic,
    Value<String>? mode,
    Value<String>? status,
    Value<int>? questionCount,
    Value<int?>? score,
    Value<bool>? isTimed,
    Value<int?>? timeLimitSecs,
    Value<int?>? examRemainingSecs,
    Value<String>? language,
    Value<String?>? analyticsFeatureKey,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subTopic: subTopic ?? this.subTopic,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      score: score ?? this.score,
      isTimed: isTimed ?? this.isTimed,
      timeLimitSecs: timeLimitSecs ?? this.timeLimitSecs,
      examRemainingSecs: examRemainingSecs ?? this.examRemainingSecs,
      language: language ?? this.language,
      analyticsFeatureKey: analyticsFeatureKey ?? this.analyticsFeatureKey,
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
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (subTopic.present) {
      map['sub_topic'] = Variable<String>(subTopic.value);
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
    if (score.present) {
      map['score'] = Variable<int>(score.value);
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
    if (analyticsFeatureKey.present) {
      map['analytics_feature_key'] = Variable<String>(
        analyticsFeatureKey.value,
      );
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
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('subTopic: $subTopic, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('questionCount: $questionCount, ')
          ..write('score: $score, ')
          ..write('isTimed: $isTimed, ')
          ..write('timeLimitSecs: $timeLimitSecs, ')
          ..write('examRemainingSecs: $examRemainingSecs, ')
          ..write('language: $language, ')
          ..write('analyticsFeatureKey: $analyticsFeatureKey, ')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES questions (uuid)',
    ),
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
  static const VerificationMeta _attemptedAtMeta = const VerificationMeta(
    'attemptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> attemptedAt = GeneratedColumn<DateTime>(
    'attempted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    attemptedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
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
    if (data.containsKey('attempted_at')) {
      context.handle(
        _attemptedAtMeta,
        attemptedAt.isAcceptableOrUnknown(
          data['attempted_at']!,
          _attemptedAtMeta,
        ),
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
      attemptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}attempted_at'],
      ),
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
  final DateTime? attemptedAt;
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
    this.attemptedAt,
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
    if (!nullToAbsent || attemptedAt != null) {
      map['attempted_at'] = Variable<DateTime>(attemptedAt);
    }
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
      attemptedAt: attemptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(attemptedAt),
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
      attemptedAt: serializer.fromJson<DateTime?>(json['attemptedAt']),
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
      'attemptedAt': serializer.toJson<DateTime?>(attemptedAt),
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
    Value<DateTime?> attemptedAt = const Value.absent(),
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
    attemptedAt: attemptedAt.present ? attemptedAt.value : this.attemptedAt,
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
      attemptedAt: data.attemptedAt.present
          ? data.attemptedAt.value
          : this.attemptedAt,
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
          ..write('flagged: $flagged, ')
          ..write('attemptedAt: $attemptedAt')
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
    attemptedAt,
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
          other.flagged == this.flagged &&
          other.attemptedAt == this.attemptedAt);
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
  final Value<DateTime?> attemptedAt;
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
    this.attemptedAt = const Value.absent(),
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
    this.attemptedAt = const Value.absent(),
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
    Expression<DateTime>? attemptedAt,
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
      if (attemptedAt != null) 'attempted_at': attemptedAt,
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
    Value<DateTime?>? attemptedAt,
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
      attemptedAt: attemptedAt ?? this.attemptedAt,
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
    if (attemptedAt.present) {
      map['attempted_at'] = Variable<DateTime>(attemptedAt.value);
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
          ..write('attemptedAt: $attemptedAt, ')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES questions (uuid)',
    ),
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
  static const VerificationMeta _userNoteMeta = const VerificationMeta(
    'userNote',
  );
  @override
  late final GeneratedColumn<String> userNote = GeneratedColumn<String>(
    'user_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, questionUuid, createdAt, userNote];
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
    if (data.containsKey('user_note')) {
      context.handle(
        _userNoteMeta,
        userNote.isAcceptableOrUnknown(data['user_note']!, _userNoteMeta),
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
      userNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_note'],
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
  final String? userNote;
  const Bookmark({
    required this.id,
    required this.questionUuid,
    required this.createdAt,
    this.userNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_uuid'] = Variable<String>(questionUuid);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || userNote != null) {
      map['user_note'] = Variable<String>(userNote);
    }
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      questionUuid: Value(questionUuid),
      createdAt: Value(createdAt),
      userNote: userNote == null && nullToAbsent
          ? const Value.absent()
          : Value(userNote),
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
      userNote: serializer.fromJson<String?>(json['userNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionUuid': serializer.toJson<String>(questionUuid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'userNote': serializer.toJson<String?>(userNote),
    };
  }

  Bookmark copyWith({
    String? id,
    String? questionUuid,
    DateTime? createdAt,
    Value<String?> userNote = const Value.absent(),
  }) => Bookmark(
    id: id ?? this.id,
    questionUuid: questionUuid ?? this.questionUuid,
    createdAt: createdAt ?? this.createdAt,
    userNote: userNote.present ? userNote.value : this.userNote,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      questionUuid: data.questionUuid.present
          ? data.questionUuid.value
          : this.questionUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      userNote: data.userNote.present ? data.userNote.value : this.userNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('userNote: $userNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionUuid, createdAt, userNote);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.questionUuid == this.questionUuid &&
          other.createdAt == this.createdAt &&
          other.userNote == this.userNote);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<String> questionUuid;
  final Value<DateTime> createdAt;
  final Value<String?> userNote;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.questionUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.userNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String questionUuid,
    required DateTime createdAt,
    this.userNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       questionUuid = Value(questionUuid),
       createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<String>? questionUuid,
    Expression<DateTime>? createdAt,
    Expression<String>? userNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionUuid != null) 'question_uuid': questionUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (userNote != null) 'user_note': userNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? questionUuid,
    Value<DateTime>? createdAt,
    Value<String?>? userNote,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      questionUuid: questionUuid ?? this.questionUuid,
      createdAt: createdAt ?? this.createdAt,
      userNote: userNote ?? this.userNote,
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
    if (userNote.present) {
      map['user_note'] = Variable<String>(userNote.value);
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
          ..write('userNote: $userNote, ')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES questions (uuid)',
    ),
  );
  static const VerificationMeta _dateAddedToQueueMeta = const VerificationMeta(
    'dateAddedToQueue',
  );
  @override
  late final GeneratedColumn<DateTime> dateAddedToQueue =
      GeneratedColumn<DateTime>(
        'date_added_to_queue',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _numberOfTimesAnsweredCorrectlyInRevisionMeta =
      const VerificationMeta('numberOfTimesAnsweredCorrectlyInRevision');
  @override
  late final GeneratedColumn<int> numberOfTimesAnsweredCorrectlyInRevision =
      GeneratedColumn<int>(
        'number_of_times_answered_correctly_in_revision',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta
  _numberOfTimesAnsweredIncorrectlyInRevisionMeta = const VerificationMeta(
    'numberOfTimesAnsweredIncorrectlyInRevision',
  );
  @override
  late final GeneratedColumn<int> numberOfTimesAnsweredIncorrectlyInRevision =
      GeneratedColumn<int>(
        'number_of_times_answered_incorrectly_in_revision',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _hasGraduatedFromQueueMeta =
      const VerificationMeta('hasGraduatedFromQueue');
  @override
  late final GeneratedColumn<bool> hasGraduatedFromQueue =
      GeneratedColumn<bool>(
        'has_graduated_from_queue',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_graduated_from_queue" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _dateGraduatedMeta = const VerificationMeta(
    'dateGraduated',
  );
  @override
  late final GeneratedColumn<DateTime> dateGraduated =
      GeneratedColumn<DateTime>(
        'date_graduated',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionUuid,
    dateAddedToQueue,
    numberOfTimesAnsweredCorrectlyInRevision,
    numberOfTimesAnsweredIncorrectlyInRevision,
    hasGraduatedFromQueue,
    dateGraduated,
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
    if (data.containsKey('date_added_to_queue')) {
      context.handle(
        _dateAddedToQueueMeta,
        dateAddedToQueue.isAcceptableOrUnknown(
          data['date_added_to_queue']!,
          _dateAddedToQueueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateAddedToQueueMeta);
    }
    if (data.containsKey('number_of_times_answered_correctly_in_revision')) {
      context.handle(
        _numberOfTimesAnsweredCorrectlyInRevisionMeta,
        numberOfTimesAnsweredCorrectlyInRevision.isAcceptableOrUnknown(
          data['number_of_times_answered_correctly_in_revision']!,
          _numberOfTimesAnsweredCorrectlyInRevisionMeta,
        ),
      );
    }
    if (data.containsKey('number_of_times_answered_incorrectly_in_revision')) {
      context.handle(
        _numberOfTimesAnsweredIncorrectlyInRevisionMeta,
        numberOfTimesAnsweredIncorrectlyInRevision.isAcceptableOrUnknown(
          data['number_of_times_answered_incorrectly_in_revision']!,
          _numberOfTimesAnsweredIncorrectlyInRevisionMeta,
        ),
      );
    }
    if (data.containsKey('has_graduated_from_queue')) {
      context.handle(
        _hasGraduatedFromQueueMeta,
        hasGraduatedFromQueue.isAcceptableOrUnknown(
          data['has_graduated_from_queue']!,
          _hasGraduatedFromQueueMeta,
        ),
      );
    }
    if (data.containsKey('date_graduated')) {
      context.handle(
        _dateGraduatedMeta,
        dateGraduated.isAcceptableOrUnknown(
          data['date_graduated']!,
          _dateGraduatedMeta,
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
      dateAddedToQueue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added_to_queue'],
      )!,
      numberOfTimesAnsweredCorrectlyInRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_times_answered_correctly_in_revision'],
      )!,
      numberOfTimesAnsweredIncorrectlyInRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_times_answered_incorrectly_in_revision'],
      )!,
      hasGraduatedFromQueue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_graduated_from_queue'],
      )!,
      dateGraduated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_graduated'],
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
  final DateTime dateAddedToQueue;
  final int numberOfTimesAnsweredCorrectlyInRevision;
  final int numberOfTimesAnsweredIncorrectlyInRevision;
  final bool hasGraduatedFromQueue;
  final DateTime? dateGraduated;
  const RevisionQueueData({
    required this.id,
    required this.questionUuid,
    required this.dateAddedToQueue,
    required this.numberOfTimesAnsweredCorrectlyInRevision,
    required this.numberOfTimesAnsweredIncorrectlyInRevision,
    required this.hasGraduatedFromQueue,
    this.dateGraduated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_uuid'] = Variable<String>(questionUuid);
    map['date_added_to_queue'] = Variable<DateTime>(dateAddedToQueue);
    map['number_of_times_answered_correctly_in_revision'] = Variable<int>(
      numberOfTimesAnsweredCorrectlyInRevision,
    );
    map['number_of_times_answered_incorrectly_in_revision'] = Variable<int>(
      numberOfTimesAnsweredIncorrectlyInRevision,
    );
    map['has_graduated_from_queue'] = Variable<bool>(hasGraduatedFromQueue);
    if (!nullToAbsent || dateGraduated != null) {
      map['date_graduated'] = Variable<DateTime>(dateGraduated);
    }
    return map;
  }

  RevisionQueueCompanion toCompanion(bool nullToAbsent) {
    return RevisionQueueCompanion(
      id: Value(id),
      questionUuid: Value(questionUuid),
      dateAddedToQueue: Value(dateAddedToQueue),
      numberOfTimesAnsweredCorrectlyInRevision: Value(
        numberOfTimesAnsweredCorrectlyInRevision,
      ),
      numberOfTimesAnsweredIncorrectlyInRevision: Value(
        numberOfTimesAnsweredIncorrectlyInRevision,
      ),
      hasGraduatedFromQueue: Value(hasGraduatedFromQueue),
      dateGraduated: dateGraduated == null && nullToAbsent
          ? const Value.absent()
          : Value(dateGraduated),
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
      dateAddedToQueue: serializer.fromJson<DateTime>(json['dateAddedToQueue']),
      numberOfTimesAnsweredCorrectlyInRevision: serializer.fromJson<int>(
        json['numberOfTimesAnsweredCorrectlyInRevision'],
      ),
      numberOfTimesAnsweredIncorrectlyInRevision: serializer.fromJson<int>(
        json['numberOfTimesAnsweredIncorrectlyInRevision'],
      ),
      hasGraduatedFromQueue: serializer.fromJson<bool>(
        json['hasGraduatedFromQueue'],
      ),
      dateGraduated: serializer.fromJson<DateTime?>(json['dateGraduated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionUuid': serializer.toJson<String>(questionUuid),
      'dateAddedToQueue': serializer.toJson<DateTime>(dateAddedToQueue),
      'numberOfTimesAnsweredCorrectlyInRevision': serializer.toJson<int>(
        numberOfTimesAnsweredCorrectlyInRevision,
      ),
      'numberOfTimesAnsweredIncorrectlyInRevision': serializer.toJson<int>(
        numberOfTimesAnsweredIncorrectlyInRevision,
      ),
      'hasGraduatedFromQueue': serializer.toJson<bool>(hasGraduatedFromQueue),
      'dateGraduated': serializer.toJson<DateTime?>(dateGraduated),
    };
  }

  RevisionQueueData copyWith({
    String? id,
    String? questionUuid,
    DateTime? dateAddedToQueue,
    int? numberOfTimesAnsweredCorrectlyInRevision,
    int? numberOfTimesAnsweredIncorrectlyInRevision,
    bool? hasGraduatedFromQueue,
    Value<DateTime?> dateGraduated = const Value.absent(),
  }) => RevisionQueueData(
    id: id ?? this.id,
    questionUuid: questionUuid ?? this.questionUuid,
    dateAddedToQueue: dateAddedToQueue ?? this.dateAddedToQueue,
    numberOfTimesAnsweredCorrectlyInRevision:
        numberOfTimesAnsweredCorrectlyInRevision ??
        this.numberOfTimesAnsweredCorrectlyInRevision,
    numberOfTimesAnsweredIncorrectlyInRevision:
        numberOfTimesAnsweredIncorrectlyInRevision ??
        this.numberOfTimesAnsweredIncorrectlyInRevision,
    hasGraduatedFromQueue: hasGraduatedFromQueue ?? this.hasGraduatedFromQueue,
    dateGraduated: dateGraduated.present
        ? dateGraduated.value
        : this.dateGraduated,
  );
  RevisionQueueData copyWithCompanion(RevisionQueueCompanion data) {
    return RevisionQueueData(
      id: data.id.present ? data.id.value : this.id,
      questionUuid: data.questionUuid.present
          ? data.questionUuid.value
          : this.questionUuid,
      dateAddedToQueue: data.dateAddedToQueue.present
          ? data.dateAddedToQueue.value
          : this.dateAddedToQueue,
      numberOfTimesAnsweredCorrectlyInRevision:
          data.numberOfTimesAnsweredCorrectlyInRevision.present
          ? data.numberOfTimesAnsweredCorrectlyInRevision.value
          : this.numberOfTimesAnsweredCorrectlyInRevision,
      numberOfTimesAnsweredIncorrectlyInRevision:
          data.numberOfTimesAnsweredIncorrectlyInRevision.present
          ? data.numberOfTimesAnsweredIncorrectlyInRevision.value
          : this.numberOfTimesAnsweredIncorrectlyInRevision,
      hasGraduatedFromQueue: data.hasGraduatedFromQueue.present
          ? data.hasGraduatedFromQueue.value
          : this.hasGraduatedFromQueue,
      dateGraduated: data.dateGraduated.present
          ? data.dateGraduated.value
          : this.dateGraduated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RevisionQueueData(')
          ..write('id: $id, ')
          ..write('questionUuid: $questionUuid, ')
          ..write('dateAddedToQueue: $dateAddedToQueue, ')
          ..write(
            'numberOfTimesAnsweredCorrectlyInRevision: $numberOfTimesAnsweredCorrectlyInRevision, ',
          )
          ..write(
            'numberOfTimesAnsweredIncorrectlyInRevision: $numberOfTimesAnsweredIncorrectlyInRevision, ',
          )
          ..write('hasGraduatedFromQueue: $hasGraduatedFromQueue, ')
          ..write('dateGraduated: $dateGraduated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questionUuid,
    dateAddedToQueue,
    numberOfTimesAnsweredCorrectlyInRevision,
    numberOfTimesAnsweredIncorrectlyInRevision,
    hasGraduatedFromQueue,
    dateGraduated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevisionQueueData &&
          other.id == this.id &&
          other.questionUuid == this.questionUuid &&
          other.dateAddedToQueue == this.dateAddedToQueue &&
          other.numberOfTimesAnsweredCorrectlyInRevision ==
              this.numberOfTimesAnsweredCorrectlyInRevision &&
          other.numberOfTimesAnsweredIncorrectlyInRevision ==
              this.numberOfTimesAnsweredIncorrectlyInRevision &&
          other.hasGraduatedFromQueue == this.hasGraduatedFromQueue &&
          other.dateGraduated == this.dateGraduated);
}

class RevisionQueueCompanion extends UpdateCompanion<RevisionQueueData> {
  final Value<String> id;
  final Value<String> questionUuid;
  final Value<DateTime> dateAddedToQueue;
  final Value<int> numberOfTimesAnsweredCorrectlyInRevision;
  final Value<int> numberOfTimesAnsweredIncorrectlyInRevision;
  final Value<bool> hasGraduatedFromQueue;
  final Value<DateTime?> dateGraduated;
  final Value<int> rowid;
  const RevisionQueueCompanion({
    this.id = const Value.absent(),
    this.questionUuid = const Value.absent(),
    this.dateAddedToQueue = const Value.absent(),
    this.numberOfTimesAnsweredCorrectlyInRevision = const Value.absent(),
    this.numberOfTimesAnsweredIncorrectlyInRevision = const Value.absent(),
    this.hasGraduatedFromQueue = const Value.absent(),
    this.dateGraduated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RevisionQueueCompanion.insert({
    required String id,
    required String questionUuid,
    required DateTime dateAddedToQueue,
    this.numberOfTimesAnsweredCorrectlyInRevision = const Value.absent(),
    this.numberOfTimesAnsweredIncorrectlyInRevision = const Value.absent(),
    this.hasGraduatedFromQueue = const Value.absent(),
    this.dateGraduated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       questionUuid = Value(questionUuid),
       dateAddedToQueue = Value(dateAddedToQueue);
  static Insertable<RevisionQueueData> custom({
    Expression<String>? id,
    Expression<String>? questionUuid,
    Expression<DateTime>? dateAddedToQueue,
    Expression<int>? numberOfTimesAnsweredCorrectlyInRevision,
    Expression<int>? numberOfTimesAnsweredIncorrectlyInRevision,
    Expression<bool>? hasGraduatedFromQueue,
    Expression<DateTime>? dateGraduated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionUuid != null) 'question_uuid': questionUuid,
      if (dateAddedToQueue != null) 'date_added_to_queue': dateAddedToQueue,
      if (numberOfTimesAnsweredCorrectlyInRevision != null)
        'number_of_times_answered_correctly_in_revision':
            numberOfTimesAnsweredCorrectlyInRevision,
      if (numberOfTimesAnsweredIncorrectlyInRevision != null)
        'number_of_times_answered_incorrectly_in_revision':
            numberOfTimesAnsweredIncorrectlyInRevision,
      if (hasGraduatedFromQueue != null)
        'has_graduated_from_queue': hasGraduatedFromQueue,
      if (dateGraduated != null) 'date_graduated': dateGraduated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RevisionQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? questionUuid,
    Value<DateTime>? dateAddedToQueue,
    Value<int>? numberOfTimesAnsweredCorrectlyInRevision,
    Value<int>? numberOfTimesAnsweredIncorrectlyInRevision,
    Value<bool>? hasGraduatedFromQueue,
    Value<DateTime?>? dateGraduated,
    Value<int>? rowid,
  }) {
    return RevisionQueueCompanion(
      id: id ?? this.id,
      questionUuid: questionUuid ?? this.questionUuid,
      dateAddedToQueue: dateAddedToQueue ?? this.dateAddedToQueue,
      numberOfTimesAnsweredCorrectlyInRevision:
          numberOfTimesAnsweredCorrectlyInRevision ??
          this.numberOfTimesAnsweredCorrectlyInRevision,
      numberOfTimesAnsweredIncorrectlyInRevision:
          numberOfTimesAnsweredIncorrectlyInRevision ??
          this.numberOfTimesAnsweredIncorrectlyInRevision,
      hasGraduatedFromQueue:
          hasGraduatedFromQueue ?? this.hasGraduatedFromQueue,
      dateGraduated: dateGraduated ?? this.dateGraduated,
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
    if (dateAddedToQueue.present) {
      map['date_added_to_queue'] = Variable<DateTime>(dateAddedToQueue.value);
    }
    if (numberOfTimesAnsweredCorrectlyInRevision.present) {
      map['number_of_times_answered_correctly_in_revision'] = Variable<int>(
        numberOfTimesAnsweredCorrectlyInRevision.value,
      );
    }
    if (numberOfTimesAnsweredIncorrectlyInRevision.present) {
      map['number_of_times_answered_incorrectly_in_revision'] = Variable<int>(
        numberOfTimesAnsweredIncorrectlyInRevision.value,
      );
    }
    if (hasGraduatedFromQueue.present) {
      map['has_graduated_from_queue'] = Variable<bool>(
        hasGraduatedFromQueue.value,
      );
    }
    if (dateGraduated.present) {
      map['date_graduated'] = Variable<DateTime>(dateGraduated.value);
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
          ..write('dateAddedToQueue: $dateAddedToQueue, ')
          ..write(
            'numberOfTimesAnsweredCorrectlyInRevision: $numberOfTimesAnsweredCorrectlyInRevision, ',
          )
          ..write(
            'numberOfTimesAnsweredIncorrectlyInRevision: $numberOfTimesAnsweredIncorrectlyInRevision, ',
          )
          ..write('hasGraduatedFromQueue: $hasGraduatedFromQueue, ')
          ..write('dateGraduated: $dateGraduated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserTopicStatsTable extends UserTopicStats
    with TableInfo<$UserTopicStatsTable, UserTopicStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTopicStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAttemptedMeta = const VerificationMeta(
    'totalAttempted',
  );
  @override
  late final GeneratedColumn<int> totalAttempted = GeneratedColumn<int>(
    'total_attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCorrectMeta = const VerificationMeta(
    'totalCorrect',
  );
  @override
  late final GeneratedColumn<int> totalCorrect = GeneratedColumn<int>(
    'total_correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wrongAttemptsMeta = const VerificationMeta(
    'wrongAttempts',
  );
  @override
  late final GeneratedColumn<int> wrongAttempts = GeneratedColumn<int>(
    'wrong_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalTimeSpentSecsMeta =
      const VerificationMeta('totalTimeSpentSecs');
  @override
  late final GeneratedColumn<int> totalTimeSpentSecs = GeneratedColumn<int>(
    'total_time_spent_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _accuracyPercentageMeta =
      const VerificationMeta('accuracyPercentage');
  @override
  late final GeneratedColumn<double> accuracyPercentage =
      GeneratedColumn<double>(
        'accuracy_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _lastAttemptedAtMeta = const VerificationMeta(
    'lastAttemptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptedAt =
      GeneratedColumn<DateTime>(
        'last_attempted_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subject,
    topic,
    totalAttempted,
    totalCorrect,
    wrongAttempts,
    totalTimeSpentSecs,
    accuracyPercentage,
    lastAttemptedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_topic_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserTopicStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('total_attempted')) {
      context.handle(
        _totalAttemptedMeta,
        totalAttempted.isAcceptableOrUnknown(
          data['total_attempted']!,
          _totalAttemptedMeta,
        ),
      );
    }
    if (data.containsKey('total_correct')) {
      context.handle(
        _totalCorrectMeta,
        totalCorrect.isAcceptableOrUnknown(
          data['total_correct']!,
          _totalCorrectMeta,
        ),
      );
    }
    if (data.containsKey('wrong_attempts')) {
      context.handle(
        _wrongAttemptsMeta,
        wrongAttempts.isAcceptableOrUnknown(
          data['wrong_attempts']!,
          _wrongAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('total_time_spent_secs')) {
      context.handle(
        _totalTimeSpentSecsMeta,
        totalTimeSpentSecs.isAcceptableOrUnknown(
          data['total_time_spent_secs']!,
          _totalTimeSpentSecsMeta,
        ),
      );
    }
    if (data.containsKey('accuracy_percentage')) {
      context.handle(
        _accuracyPercentageMeta,
        accuracyPercentage.isAcceptableOrUnknown(
          data['accuracy_percentage']!,
          _accuracyPercentageMeta,
        ),
      );
    }
    if (data.containsKey('last_attempted_at')) {
      context.handle(
        _lastAttemptedAtMeta,
        lastAttemptedAt.isAcceptableOrUnknown(
          data['last_attempted_at']!,
          _lastAttemptedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAttemptedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {subject, topic},
  ];
  @override
  UserTopicStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserTopicStat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      totalAttempted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_attempted'],
      )!,
      totalCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_correct'],
      )!,
      wrongAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong_attempts'],
      )!,
      totalTimeSpentSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_time_spent_secs'],
      )!,
      accuracyPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_percentage'],
      )!,
      lastAttemptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempted_at'],
      )!,
    );
  }

  @override
  $UserTopicStatsTable createAlias(String alias) {
    return $UserTopicStatsTable(attachedDatabase, alias);
  }
}

class UserTopicStat extends DataClass implements Insertable<UserTopicStat> {
  final int id;
  final String subject;
  final String topic;
  final int totalAttempted;
  final int totalCorrect;
  final int wrongAttempts;
  final int totalTimeSpentSecs;
  final double accuracyPercentage;
  final DateTime lastAttemptedAt;
  const UserTopicStat({
    required this.id,
    required this.subject,
    required this.topic,
    required this.totalAttempted,
    required this.totalCorrect,
    required this.wrongAttempts,
    required this.totalTimeSpentSecs,
    required this.accuracyPercentage,
    required this.lastAttemptedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject'] = Variable<String>(subject);
    map['topic'] = Variable<String>(topic);
    map['total_attempted'] = Variable<int>(totalAttempted);
    map['total_correct'] = Variable<int>(totalCorrect);
    map['wrong_attempts'] = Variable<int>(wrongAttempts);
    map['total_time_spent_secs'] = Variable<int>(totalTimeSpentSecs);
    map['accuracy_percentage'] = Variable<double>(accuracyPercentage);
    map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt);
    return map;
  }

  UserTopicStatsCompanion toCompanion(bool nullToAbsent) {
    return UserTopicStatsCompanion(
      id: Value(id),
      subject: Value(subject),
      topic: Value(topic),
      totalAttempted: Value(totalAttempted),
      totalCorrect: Value(totalCorrect),
      wrongAttempts: Value(wrongAttempts),
      totalTimeSpentSecs: Value(totalTimeSpentSecs),
      accuracyPercentage: Value(accuracyPercentage),
      lastAttemptedAt: Value(lastAttemptedAt),
    );
  }

  factory UserTopicStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserTopicStat(
      id: serializer.fromJson<int>(json['id']),
      subject: serializer.fromJson<String>(json['subject']),
      topic: serializer.fromJson<String>(json['topic']),
      totalAttempted: serializer.fromJson<int>(json['totalAttempted']),
      totalCorrect: serializer.fromJson<int>(json['totalCorrect']),
      wrongAttempts: serializer.fromJson<int>(json['wrongAttempts']),
      totalTimeSpentSecs: serializer.fromJson<int>(json['totalTimeSpentSecs']),
      accuracyPercentage: serializer.fromJson<double>(
        json['accuracyPercentage'],
      ),
      lastAttemptedAt: serializer.fromJson<DateTime>(json['lastAttemptedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subject': serializer.toJson<String>(subject),
      'topic': serializer.toJson<String>(topic),
      'totalAttempted': serializer.toJson<int>(totalAttempted),
      'totalCorrect': serializer.toJson<int>(totalCorrect),
      'wrongAttempts': serializer.toJson<int>(wrongAttempts),
      'totalTimeSpentSecs': serializer.toJson<int>(totalTimeSpentSecs),
      'accuracyPercentage': serializer.toJson<double>(accuracyPercentage),
      'lastAttemptedAt': serializer.toJson<DateTime>(lastAttemptedAt),
    };
  }

  UserTopicStat copyWith({
    int? id,
    String? subject,
    String? topic,
    int? totalAttempted,
    int? totalCorrect,
    int? wrongAttempts,
    int? totalTimeSpentSecs,
    double? accuracyPercentage,
    DateTime? lastAttemptedAt,
  }) => UserTopicStat(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    topic: topic ?? this.topic,
    totalAttempted: totalAttempted ?? this.totalAttempted,
    totalCorrect: totalCorrect ?? this.totalCorrect,
    wrongAttempts: wrongAttempts ?? this.wrongAttempts,
    totalTimeSpentSecs: totalTimeSpentSecs ?? this.totalTimeSpentSecs,
    accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
    lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
  );
  UserTopicStat copyWithCompanion(UserTopicStatsCompanion data) {
    return UserTopicStat(
      id: data.id.present ? data.id.value : this.id,
      subject: data.subject.present ? data.subject.value : this.subject,
      topic: data.topic.present ? data.topic.value : this.topic,
      totalAttempted: data.totalAttempted.present
          ? data.totalAttempted.value
          : this.totalAttempted,
      totalCorrect: data.totalCorrect.present
          ? data.totalCorrect.value
          : this.totalCorrect,
      wrongAttempts: data.wrongAttempts.present
          ? data.wrongAttempts.value
          : this.wrongAttempts,
      totalTimeSpentSecs: data.totalTimeSpentSecs.present
          ? data.totalTimeSpentSecs.value
          : this.totalTimeSpentSecs,
      accuracyPercentage: data.accuracyPercentage.present
          ? data.accuracyPercentage.value
          : this.accuracyPercentage,
      lastAttemptedAt: data.lastAttemptedAt.present
          ? data.lastAttemptedAt.value
          : this.lastAttemptedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserTopicStat(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('totalAttempted: $totalAttempted, ')
          ..write('totalCorrect: $totalCorrect, ')
          ..write('wrongAttempts: $wrongAttempts, ')
          ..write('totalTimeSpentSecs: $totalTimeSpentSecs, ')
          ..write('accuracyPercentage: $accuracyPercentage, ')
          ..write('lastAttemptedAt: $lastAttemptedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subject,
    topic,
    totalAttempted,
    totalCorrect,
    wrongAttempts,
    totalTimeSpentSecs,
    accuracyPercentage,
    lastAttemptedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserTopicStat &&
          other.id == this.id &&
          other.subject == this.subject &&
          other.topic == this.topic &&
          other.totalAttempted == this.totalAttempted &&
          other.totalCorrect == this.totalCorrect &&
          other.wrongAttempts == this.wrongAttempts &&
          other.totalTimeSpentSecs == this.totalTimeSpentSecs &&
          other.accuracyPercentage == this.accuracyPercentage &&
          other.lastAttemptedAt == this.lastAttemptedAt);
}

class UserTopicStatsCompanion extends UpdateCompanion<UserTopicStat> {
  final Value<int> id;
  final Value<String> subject;
  final Value<String> topic;
  final Value<int> totalAttempted;
  final Value<int> totalCorrect;
  final Value<int> wrongAttempts;
  final Value<int> totalTimeSpentSecs;
  final Value<double> accuracyPercentage;
  final Value<DateTime> lastAttemptedAt;
  const UserTopicStatsCompanion({
    this.id = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.totalAttempted = const Value.absent(),
    this.totalCorrect = const Value.absent(),
    this.wrongAttempts = const Value.absent(),
    this.totalTimeSpentSecs = const Value.absent(),
    this.accuracyPercentage = const Value.absent(),
    this.lastAttemptedAt = const Value.absent(),
  });
  UserTopicStatsCompanion.insert({
    this.id = const Value.absent(),
    required String subject,
    required String topic,
    this.totalAttempted = const Value.absent(),
    this.totalCorrect = const Value.absent(),
    this.wrongAttempts = const Value.absent(),
    this.totalTimeSpentSecs = const Value.absent(),
    this.accuracyPercentage = const Value.absent(),
    required DateTime lastAttemptedAt,
  }) : subject = Value(subject),
       topic = Value(topic),
       lastAttemptedAt = Value(lastAttemptedAt);
  static Insertable<UserTopicStat> custom({
    Expression<int>? id,
    Expression<String>? subject,
    Expression<String>? topic,
    Expression<int>? totalAttempted,
    Expression<int>? totalCorrect,
    Expression<int>? wrongAttempts,
    Expression<int>? totalTimeSpentSecs,
    Expression<double>? accuracyPercentage,
    Expression<DateTime>? lastAttemptedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (totalAttempted != null) 'total_attempted': totalAttempted,
      if (totalCorrect != null) 'total_correct': totalCorrect,
      if (wrongAttempts != null) 'wrong_attempts': wrongAttempts,
      if (totalTimeSpentSecs != null)
        'total_time_spent_secs': totalTimeSpentSecs,
      if (accuracyPercentage != null) 'accuracy_percentage': accuracyPercentage,
      if (lastAttemptedAt != null) 'last_attempted_at': lastAttemptedAt,
    });
  }

  UserTopicStatsCompanion copyWith({
    Value<int>? id,
    Value<String>? subject,
    Value<String>? topic,
    Value<int>? totalAttempted,
    Value<int>? totalCorrect,
    Value<int>? wrongAttempts,
    Value<int>? totalTimeSpentSecs,
    Value<double>? accuracyPercentage,
    Value<DateTime>? lastAttemptedAt,
  }) {
    return UserTopicStatsCompanion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      totalAttempted: totalAttempted ?? this.totalAttempted,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      totalTimeSpentSecs: totalTimeSpentSecs ?? this.totalTimeSpentSecs,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (totalAttempted.present) {
      map['total_attempted'] = Variable<int>(totalAttempted.value);
    }
    if (totalCorrect.present) {
      map['total_correct'] = Variable<int>(totalCorrect.value);
    }
    if (wrongAttempts.present) {
      map['wrong_attempts'] = Variable<int>(wrongAttempts.value);
    }
    if (totalTimeSpentSecs.present) {
      map['total_time_spent_secs'] = Variable<int>(totalTimeSpentSecs.value);
    }
    if (accuracyPercentage.present) {
      map['accuracy_percentage'] = Variable<double>(accuracyPercentage.value);
    }
    if (lastAttemptedAt.present) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserTopicStatsCompanion(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('totalAttempted: $totalAttempted, ')
          ..write('totalCorrect: $totalCorrect, ')
          ..write('wrongAttempts: $wrongAttempts, ')
          ..write('totalTimeSpentSecs: $totalTimeSpentSecs, ')
          ..write('accuracyPercentage: $accuracyPercentage, ')
          ..write('lastAttemptedAt: $lastAttemptedAt')
          ..write(')'))
        .toString();
  }
}

class $UserFeatureStatsTable extends UserFeatureStats
    with TableInfo<$UserFeatureStatsTable, UserFeatureStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserFeatureStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _featureNameMeta = const VerificationMeta(
    'featureName',
  );
  @override
  late final GeneratedColumn<String> featureName = GeneratedColumn<String>(
    'feature_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalViewsMeta = const VerificationMeta(
    'totalViews',
  );
  @override
  late final GeneratedColumn<int> totalViews = GeneratedColumn<int>(
    'total_views',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalStartsMeta = const VerificationMeta(
    'totalStarts',
  );
  @override
  late final GeneratedColumn<int> totalStarts = GeneratedColumn<int>(
    'total_starts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCompletionsMeta = const VerificationMeta(
    'totalCompletions',
  );
  @override
  late final GeneratedColumn<int> totalCompletions = GeneratedColumn<int>(
    'total_completions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    featureName,
    totalViews,
    totalStarts,
    totalCompletions,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_feature_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserFeatureStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('feature_name')) {
      context.handle(
        _featureNameMeta,
        featureName.isAcceptableOrUnknown(
          data['feature_name']!,
          _featureNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_featureNameMeta);
    }
    if (data.containsKey('total_views')) {
      context.handle(
        _totalViewsMeta,
        totalViews.isAcceptableOrUnknown(data['total_views']!, _totalViewsMeta),
      );
    }
    if (data.containsKey('total_starts')) {
      context.handle(
        _totalStartsMeta,
        totalStarts.isAcceptableOrUnknown(
          data['total_starts']!,
          _totalStartsMeta,
        ),
      );
    }
    if (data.containsKey('total_completions')) {
      context.handle(
        _totalCompletionsMeta,
        totalCompletions.isAcceptableOrUnknown(
          data['total_completions']!,
          _totalCompletionsMeta,
        ),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {featureName};
  @override
  UserFeatureStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserFeatureStat(
      featureName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feature_name'],
      )!,
      totalViews: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_views'],
      )!,
      totalStarts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_starts'],
      )!,
      totalCompletions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_completions'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $UserFeatureStatsTable createAlias(String alias) {
    return $UserFeatureStatsTable(attachedDatabase, alias);
  }
}

class UserFeatureStat extends DataClass implements Insertable<UserFeatureStat> {
  final String featureName;
  final int totalViews;
  final int totalStarts;
  final int totalCompletions;
  final DateTime lastUsedAt;
  const UserFeatureStat({
    required this.featureName,
    required this.totalViews,
    required this.totalStarts,
    required this.totalCompletions,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['feature_name'] = Variable<String>(featureName);
    map['total_views'] = Variable<int>(totalViews);
    map['total_starts'] = Variable<int>(totalStarts);
    map['total_completions'] = Variable<int>(totalCompletions);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  UserFeatureStatsCompanion toCompanion(bool nullToAbsent) {
    return UserFeatureStatsCompanion(
      featureName: Value(featureName),
      totalViews: Value(totalViews),
      totalStarts: Value(totalStarts),
      totalCompletions: Value(totalCompletions),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory UserFeatureStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserFeatureStat(
      featureName: serializer.fromJson<String>(json['featureName']),
      totalViews: serializer.fromJson<int>(json['totalViews']),
      totalStarts: serializer.fromJson<int>(json['totalStarts']),
      totalCompletions: serializer.fromJson<int>(json['totalCompletions']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'featureName': serializer.toJson<String>(featureName),
      'totalViews': serializer.toJson<int>(totalViews),
      'totalStarts': serializer.toJson<int>(totalStarts),
      'totalCompletions': serializer.toJson<int>(totalCompletions),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  UserFeatureStat copyWith({
    String? featureName,
    int? totalViews,
    int? totalStarts,
    int? totalCompletions,
    DateTime? lastUsedAt,
  }) => UserFeatureStat(
    featureName: featureName ?? this.featureName,
    totalViews: totalViews ?? this.totalViews,
    totalStarts: totalStarts ?? this.totalStarts,
    totalCompletions: totalCompletions ?? this.totalCompletions,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  UserFeatureStat copyWithCompanion(UserFeatureStatsCompanion data) {
    return UserFeatureStat(
      featureName: data.featureName.present
          ? data.featureName.value
          : this.featureName,
      totalViews: data.totalViews.present
          ? data.totalViews.value
          : this.totalViews,
      totalStarts: data.totalStarts.present
          ? data.totalStarts.value
          : this.totalStarts,
      totalCompletions: data.totalCompletions.present
          ? data.totalCompletions.value
          : this.totalCompletions,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserFeatureStat(')
          ..write('featureName: $featureName, ')
          ..write('totalViews: $totalViews, ')
          ..write('totalStarts: $totalStarts, ')
          ..write('totalCompletions: $totalCompletions, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    featureName,
    totalViews,
    totalStarts,
    totalCompletions,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserFeatureStat &&
          other.featureName == this.featureName &&
          other.totalViews == this.totalViews &&
          other.totalStarts == this.totalStarts &&
          other.totalCompletions == this.totalCompletions &&
          other.lastUsedAt == this.lastUsedAt);
}

class UserFeatureStatsCompanion extends UpdateCompanion<UserFeatureStat> {
  final Value<String> featureName;
  final Value<int> totalViews;
  final Value<int> totalStarts;
  final Value<int> totalCompletions;
  final Value<DateTime> lastUsedAt;
  final Value<int> rowid;
  const UserFeatureStatsCompanion({
    this.featureName = const Value.absent(),
    this.totalViews = const Value.absent(),
    this.totalStarts = const Value.absent(),
    this.totalCompletions = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserFeatureStatsCompanion.insert({
    required String featureName,
    this.totalViews = const Value.absent(),
    this.totalStarts = const Value.absent(),
    this.totalCompletions = const Value.absent(),
    required DateTime lastUsedAt,
    this.rowid = const Value.absent(),
  }) : featureName = Value(featureName),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<UserFeatureStat> custom({
    Expression<String>? featureName,
    Expression<int>? totalViews,
    Expression<int>? totalStarts,
    Expression<int>? totalCompletions,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (featureName != null) 'feature_name': featureName,
      if (totalViews != null) 'total_views': totalViews,
      if (totalStarts != null) 'total_starts': totalStarts,
      if (totalCompletions != null) 'total_completions': totalCompletions,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserFeatureStatsCompanion copyWith({
    Value<String>? featureName,
    Value<int>? totalViews,
    Value<int>? totalStarts,
    Value<int>? totalCompletions,
    Value<DateTime>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return UserFeatureStatsCompanion(
      featureName: featureName ?? this.featureName,
      totalViews: totalViews ?? this.totalViews,
      totalStarts: totalStarts ?? this.totalStarts,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (featureName.present) {
      map['feature_name'] = Variable<String>(featureName.value);
    }
    if (totalViews.present) {
      map['total_views'] = Variable<int>(totalViews.value);
    }
    if (totalStarts.present) {
      map['total_starts'] = Variable<int>(totalStarts.value);
    }
    if (totalCompletions.present) {
      map['total_completions'] = Variable<int>(totalCompletions.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserFeatureStatsCompanion(')
          ..write('featureName: $featureName, ')
          ..write('totalViews: $totalViews, ')
          ..write('totalStarts: $totalStarts, ')
          ..write('totalCompletions: $totalCompletions, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserTrapStatsTable extends UserTrapStats
    with TableInfo<$UserTrapStatsTable, UserTrapStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTrapStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trapTypeMeta = const VerificationMeta(
    'trapType',
  );
  @override
  late final GeneratedColumn<String> trapType = GeneratedColumn<String>(
    'trap_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalFailuresMeta = const VerificationMeta(
    'totalFailures',
  );
  @override
  late final GeneratedColumn<int> totalFailures = GeneratedColumn<int>(
    'total_failures',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastFailedAtMeta = const VerificationMeta(
    'lastFailedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFailedAt = GeneratedColumn<DateTime>(
    'last_failed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [trapType, totalFailures, lastFailedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_trap_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserTrapStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trap_type')) {
      context.handle(
        _trapTypeMeta,
        trapType.isAcceptableOrUnknown(data['trap_type']!, _trapTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_trapTypeMeta);
    }
    if (data.containsKey('total_failures')) {
      context.handle(
        _totalFailuresMeta,
        totalFailures.isAcceptableOrUnknown(
          data['total_failures']!,
          _totalFailuresMeta,
        ),
      );
    }
    if (data.containsKey('last_failed_at')) {
      context.handle(
        _lastFailedAtMeta,
        lastFailedAt.isAcceptableOrUnknown(
          data['last_failed_at']!,
          _lastFailedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastFailedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trapType};
  @override
  UserTrapStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserTrapStat(
      trapType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trap_type'],
      )!,
      totalFailures: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_failures'],
      )!,
      lastFailedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_failed_at'],
      )!,
    );
  }

  @override
  $UserTrapStatsTable createAlias(String alias) {
    return $UserTrapStatsTable(attachedDatabase, alias);
  }
}

class UserTrapStat extends DataClass implements Insertable<UserTrapStat> {
  final String trapType;
  final int totalFailures;
  final DateTime lastFailedAt;
  const UserTrapStat({
    required this.trapType,
    required this.totalFailures,
    required this.lastFailedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trap_type'] = Variable<String>(trapType);
    map['total_failures'] = Variable<int>(totalFailures);
    map['last_failed_at'] = Variable<DateTime>(lastFailedAt);
    return map;
  }

  UserTrapStatsCompanion toCompanion(bool nullToAbsent) {
    return UserTrapStatsCompanion(
      trapType: Value(trapType),
      totalFailures: Value(totalFailures),
      lastFailedAt: Value(lastFailedAt),
    );
  }

  factory UserTrapStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserTrapStat(
      trapType: serializer.fromJson<String>(json['trapType']),
      totalFailures: serializer.fromJson<int>(json['totalFailures']),
      lastFailedAt: serializer.fromJson<DateTime>(json['lastFailedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trapType': serializer.toJson<String>(trapType),
      'totalFailures': serializer.toJson<int>(totalFailures),
      'lastFailedAt': serializer.toJson<DateTime>(lastFailedAt),
    };
  }

  UserTrapStat copyWith({
    String? trapType,
    int? totalFailures,
    DateTime? lastFailedAt,
  }) => UserTrapStat(
    trapType: trapType ?? this.trapType,
    totalFailures: totalFailures ?? this.totalFailures,
    lastFailedAt: lastFailedAt ?? this.lastFailedAt,
  );
  UserTrapStat copyWithCompanion(UserTrapStatsCompanion data) {
    return UserTrapStat(
      trapType: data.trapType.present ? data.trapType.value : this.trapType,
      totalFailures: data.totalFailures.present
          ? data.totalFailures.value
          : this.totalFailures,
      lastFailedAt: data.lastFailedAt.present
          ? data.lastFailedAt.value
          : this.lastFailedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserTrapStat(')
          ..write('trapType: $trapType, ')
          ..write('totalFailures: $totalFailures, ')
          ..write('lastFailedAt: $lastFailedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trapType, totalFailures, lastFailedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserTrapStat &&
          other.trapType == this.trapType &&
          other.totalFailures == this.totalFailures &&
          other.lastFailedAt == this.lastFailedAt);
}

class UserTrapStatsCompanion extends UpdateCompanion<UserTrapStat> {
  final Value<String> trapType;
  final Value<int> totalFailures;
  final Value<DateTime> lastFailedAt;
  final Value<int> rowid;
  const UserTrapStatsCompanion({
    this.trapType = const Value.absent(),
    this.totalFailures = const Value.absent(),
    this.lastFailedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserTrapStatsCompanion.insert({
    required String trapType,
    this.totalFailures = const Value.absent(),
    required DateTime lastFailedAt,
    this.rowid = const Value.absent(),
  }) : trapType = Value(trapType),
       lastFailedAt = Value(lastFailedAt);
  static Insertable<UserTrapStat> custom({
    Expression<String>? trapType,
    Expression<int>? totalFailures,
    Expression<DateTime>? lastFailedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trapType != null) 'trap_type': trapType,
      if (totalFailures != null) 'total_failures': totalFailures,
      if (lastFailedAt != null) 'last_failed_at': lastFailedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserTrapStatsCompanion copyWith({
    Value<String>? trapType,
    Value<int>? totalFailures,
    Value<DateTime>? lastFailedAt,
    Value<int>? rowid,
  }) {
    return UserTrapStatsCompanion(
      trapType: trapType ?? this.trapType,
      totalFailures: totalFailures ?? this.totalFailures,
      lastFailedAt: lastFailedAt ?? this.lastFailedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trapType.present) {
      map['trap_type'] = Variable<String>(trapType.value);
    }
    if (totalFailures.present) {
      map['total_failures'] = Variable<int>(totalFailures.value);
    }
    if (lastFailedAt.present) {
      map['last_failed_at'] = Variable<DateTime>(lastFailedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserTrapStatsCompanion(')
          ..write('trapType: $trapType, ')
          ..write('totalFailures: $totalFailures, ')
          ..write('lastFailedAt: $lastFailedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $QuestionTranslationsTable questionTranslations =
      $QuestionTranslationsTable(this);
  late final $QuestionTablesTable questionTables = $QuestionTablesTable(this);
  late final $TopicTranslationsTable topicTranslations =
      $TopicTranslationsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionQuestionsTable sessionQuestions = $SessionQuestionsTable(
    this,
  );
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $RevisionQueueTable revisionQueue = $RevisionQueueTable(this);
  late final $UserTopicStatsTable userTopicStats = $UserTopicStatsTable(this);
  late final $UserFeatureStatsTable userFeatureStats = $UserFeatureStatsTable(
    this,
  );
  late final $UserTrapStatsTable userTrapStats = $UserTrapStatsTable(this);
  late final QuestionsDao questionsDao = QuestionsDao(this as UserDatabase);
  late final QuestionTranslationsDao questionTranslationsDao =
      QuestionTranslationsDao(this as UserDatabase);
  late final QuestionTablesDao questionTablesDao = QuestionTablesDao(
    this as UserDatabase,
  );
  late final TopicTranslationsDao topicTranslationsDao = TopicTranslationsDao(
    this as UserDatabase,
  );
  late final SessionsDao sessionsDao = SessionsDao(this as UserDatabase);
  late final SessionQuestionsDao sessionQuestionsDao = SessionQuestionsDao(
    this as UserDatabase,
  );
  late final BookmarksDao bookmarksDao = BookmarksDao(this as UserDatabase);
  late final RevisionQueueDao revisionQueueDao = RevisionQueueDao(
    this as UserDatabase,
  );
  late final UserTopicStatsDao userTopicStatsDao = UserTopicStatsDao(
    this as UserDatabase,
  );
  late final UserFeatureStatsDao userFeatureStatsDao = UserFeatureStatsDao(
    this as UserDatabase,
  );
  late final UserTrapStatsDao userTrapStatsDao = UserTrapStatsDao(
    this as UserDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    questions,
    questionTranslations,
    questionTables,
    topicTranslations,
    sessions,
    sessionQuestions,
    bookmarks,
    revisionQueue,
    userTopicStats,
    userFeatureStats,
    userTrapStats,
  ];
}

typedef $$QuestionsTableCreateCompanionBuilder =
    QuestionsCompanion Function({
      required String uuid,
      required String subject,
      required String topic,
      required String subTopic,
      required String questionType,
      Value<String?> trapType,
      required String correctOption,
      required String conceptAnchor,
      required String conceptsUsed,
      Value<String?> enDisplayText,
      Value<String?> hiDisplayText,
      Value<bool> hasTable,
      Value<bool> negativeFraming,
      Value<int> rowid,
    });
typedef $$QuestionsTableUpdateCompanionBuilder =
    QuestionsCompanion Function({
      Value<String> uuid,
      Value<String> subject,
      Value<String> topic,
      Value<String> subTopic,
      Value<String> questionType,
      Value<String?> trapType,
      Value<String> correctOption,
      Value<String> conceptAnchor,
      Value<String> conceptsUsed,
      Value<String?> enDisplayText,
      Value<String?> hiDisplayText,
      Value<bool> hasTable,
      Value<bool> negativeFraming,
      Value<int> rowid,
    });

final class $$QuestionsTableReferences
    extends BaseReferences<_$UserDatabase, $QuestionsTable, Question> {
  $$QuestionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $QuestionTranslationsTable,
    List<QuestionTranslation>
  >
  _questionTranslationsRefsTable(_$UserDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.questionTranslations,
        aliasName: $_aliasNameGenerator(
          db.questions.uuid,
          db.questionTranslations.questionUuid,
        ),
      );

  $$QuestionTranslationsTableProcessedTableManager
  get questionTranslationsRefs {
    final manager =
        $$QuestionTranslationsTableTableManager(
          $_db,
          $_db.questionTranslations,
        ).filter(
          (f) => f.questionUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _questionTranslationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QuestionTablesTable, List<QuestionTable>>
  _questionTablesRefsTable(_$UserDatabase db) => MultiTypedResultKey.fromTable(
    db.questionTables,
    aliasName: $_aliasNameGenerator(
      db.questions.uuid,
      db.questionTables.questionUuid,
    ),
  );

  $$QuestionTablesTableProcessedTableManager get questionTablesRefs {
    final manager = $$QuestionTablesTableTableManager($_db, $_db.questionTables)
        .filter(
          (f) => f.questionUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(_questionTablesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionQuestionsTable, List<SessionQuestion>>
  _sessionQuestionsRefsTable(_$UserDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.sessionQuestions,
        aliasName: $_aliasNameGenerator(
          db.questions.uuid,
          db.sessionQuestions.questionUuid,
        ),
      );

  $$SessionQuestionsTableProcessedTableManager get sessionQuestionsRefs {
    final manager =
        $$SessionQuestionsTableTableManager($_db, $_db.sessionQuestions).filter(
          (f) => f.questionUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _sessionQuestionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
  _bookmarksRefsTable(_$UserDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: $_aliasNameGenerator(
      db.questions.uuid,
      db.bookmarks.questionUuid,
    ),
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager($_db, $_db.bookmarks).filter(
      (f) => f.questionUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RevisionQueueTable, List<RevisionQueueData>>
  _revisionQueueRefsTable(_$UserDatabase db) => MultiTypedResultKey.fromTable(
    db.revisionQueue,
    aliasName: $_aliasNameGenerator(
      db.questions.uuid,
      db.revisionQueue.questionUuid,
    ),
  );

  $$RevisionQueueTableProcessedTableManager get revisionQueueRefs {
    final manager = $$RevisionQueueTableTableManager($_db, $_db.revisionQueue)
        .filter(
          (f) => f.questionUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(_revisionQueueRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuestionsTableFilterComposer
    extends Composer<_$UserDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subTopic => $composableBuilder(
    column: $table.subTopic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trapType => $composableBuilder(
    column: $table.trapType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctOption => $composableBuilder(
    column: $table.correctOption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conceptAnchor => $composableBuilder(
    column: $table.conceptAnchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conceptsUsed => $composableBuilder(
    column: $table.conceptsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enDisplayText => $composableBuilder(
    column: $table.enDisplayText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hiDisplayText => $composableBuilder(
    column: $table.hiDisplayText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasTable => $composableBuilder(
    column: $table.hasTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get negativeFraming => $composableBuilder(
    column: $table.negativeFraming,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> questionTranslationsRefs(
    Expression<bool> Function($$QuestionTranslationsTableFilterComposer f) f,
  ) {
    final $$QuestionTranslationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.questionTranslations,
      getReferencedColumn: (t) => t.questionUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionTranslationsTableFilterComposer(
            $db: $db,
            $table: $db.questionTranslations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> questionTablesRefs(
    Expression<bool> Function($$QuestionTablesTableFilterComposer f) f,
  ) {
    final $$QuestionTablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.questionTables,
      getReferencedColumn: (t) => t.questionUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionTablesTableFilterComposer(
            $db: $db,
            $table: $db.questionTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionQuestionsRefs(
    Expression<bool> Function($$SessionQuestionsTableFilterComposer f) f,
  ) {
    final $$SessionQuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.sessionQuestions,
      getReferencedColumn: (t) => t.questionUuid,
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

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.questionUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> revisionQueueRefs(
    Expression<bool> Function($$RevisionQueueTableFilterComposer f) f,
  ) {
    final $$RevisionQueueTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.revisionQueue,
      getReferencedColumn: (t) => t.questionUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RevisionQueueTableFilterComposer(
            $db: $db,
            $table: $db.revisionQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$UserDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subTopic => $composableBuilder(
    column: $table.subTopic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trapType => $composableBuilder(
    column: $table.trapType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctOption => $composableBuilder(
    column: $table.correctOption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conceptAnchor => $composableBuilder(
    column: $table.conceptAnchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conceptsUsed => $composableBuilder(
    column: $table.conceptsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enDisplayText => $composableBuilder(
    column: $table.enDisplayText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hiDisplayText => $composableBuilder(
    column: $table.hiDisplayText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasTable => $composableBuilder(
    column: $table.hasTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get negativeFraming => $composableBuilder(
    column: $table.negativeFraming,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get subTopic =>
      $composableBuilder(column: $table.subTopic, builder: (column) => column);

  GeneratedColumn<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trapType =>
      $composableBuilder(column: $table.trapType, builder: (column) => column);

  GeneratedColumn<String> get correctOption => $composableBuilder(
    column: $table.correctOption,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conceptAnchor => $composableBuilder(
    column: $table.conceptAnchor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conceptsUsed => $composableBuilder(
    column: $table.conceptsUsed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enDisplayText => $composableBuilder(
    column: $table.enDisplayText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hiDisplayText => $composableBuilder(
    column: $table.hiDisplayText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasTable =>
      $composableBuilder(column: $table.hasTable, builder: (column) => column);

  GeneratedColumn<bool> get negativeFraming => $composableBuilder(
    column: $table.negativeFraming,
    builder: (column) => column,
  );

  Expression<T> questionTranslationsRefs<T extends Object>(
    Expression<T> Function($$QuestionTranslationsTableAnnotationComposer a) f,
  ) {
    final $$QuestionTranslationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.questionTranslations,
          getReferencedColumn: (t) => t.questionUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$QuestionTranslationsTableAnnotationComposer(
                $db: $db,
                $table: $db.questionTranslations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> questionTablesRefs<T extends Object>(
    Expression<T> Function($$QuestionTablesTableAnnotationComposer a) f,
  ) {
    final $$QuestionTablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.questionTables,
      getReferencedColumn: (t) => t.questionUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionTablesTableAnnotationComposer(
            $db: $db,
            $table: $db.questionTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionQuestionsRefs<T extends Object>(
    Expression<T> Function($$SessionQuestionsTableAnnotationComposer a) f,
  ) {
    final $$SessionQuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.sessionQuestions,
      getReferencedColumn: (t) => t.questionUuid,
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

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.questionUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> revisionQueueRefs<T extends Object>(
    Expression<T> Function($$RevisionQueueTableAnnotationComposer a) f,
  ) {
    final $$RevisionQueueTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.revisionQueue,
      getReferencedColumn: (t) => t.questionUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RevisionQueueTableAnnotationComposer(
            $db: $db,
            $table: $db.revisionQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $QuestionsTable,
          Question,
          $$QuestionsTableFilterComposer,
          $$QuestionsTableOrderingComposer,
          $$QuestionsTableAnnotationComposer,
          $$QuestionsTableCreateCompanionBuilder,
          $$QuestionsTableUpdateCompanionBuilder,
          (Question, $$QuestionsTableReferences),
          Question,
          PrefetchHooks Function({
            bool questionTranslationsRefs,
            bool questionTablesRefs,
            bool sessionQuestionsRefs,
            bool bookmarksRefs,
            bool revisionQueueRefs,
          })
        > {
  $$QuestionsTableTableManager(_$UserDatabase db, $QuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> subTopic = const Value.absent(),
                Value<String> questionType = const Value.absent(),
                Value<String?> trapType = const Value.absent(),
                Value<String> correctOption = const Value.absent(),
                Value<String> conceptAnchor = const Value.absent(),
                Value<String> conceptsUsed = const Value.absent(),
                Value<String?> enDisplayText = const Value.absent(),
                Value<String?> hiDisplayText = const Value.absent(),
                Value<bool> hasTable = const Value.absent(),
                Value<bool> negativeFraming = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion(
                uuid: uuid,
                subject: subject,
                topic: topic,
                subTopic: subTopic,
                questionType: questionType,
                trapType: trapType,
                correctOption: correctOption,
                conceptAnchor: conceptAnchor,
                conceptsUsed: conceptsUsed,
                enDisplayText: enDisplayText,
                hiDisplayText: hiDisplayText,
                hasTable: hasTable,
                negativeFraming: negativeFraming,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String subject,
                required String topic,
                required String subTopic,
                required String questionType,
                Value<String?> trapType = const Value.absent(),
                required String correctOption,
                required String conceptAnchor,
                required String conceptsUsed,
                Value<String?> enDisplayText = const Value.absent(),
                Value<String?> hiDisplayText = const Value.absent(),
                Value<bool> hasTable = const Value.absent(),
                Value<bool> negativeFraming = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion.insert(
                uuid: uuid,
                subject: subject,
                topic: topic,
                subTopic: subTopic,
                questionType: questionType,
                trapType: trapType,
                correctOption: correctOption,
                conceptAnchor: conceptAnchor,
                conceptsUsed: conceptsUsed,
                enDisplayText: enDisplayText,
                hiDisplayText: hiDisplayText,
                hasTable: hasTable,
                negativeFraming: negativeFraming,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                questionTranslationsRefs = false,
                questionTablesRefs = false,
                sessionQuestionsRefs = false,
                bookmarksRefs = false,
                revisionQueueRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questionTranslationsRefs) db.questionTranslations,
                    if (questionTablesRefs) db.questionTables,
                    if (sessionQuestionsRefs) db.sessionQuestions,
                    if (bookmarksRefs) db.bookmarks,
                    if (revisionQueueRefs) db.revisionQueue,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (questionTranslationsRefs)
                        await $_getPrefetchedData<
                          Question,
                          $QuestionsTable,
                          QuestionTranslation
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._questionTranslationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).questionTranslationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (questionTablesRefs)
                        await $_getPrefetchedData<
                          Question,
                          $QuestionsTable,
                          QuestionTable
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._questionTablesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).questionTablesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (sessionQuestionsRefs)
                        await $_getPrefetchedData<
                          Question,
                          $QuestionsTable,
                          SessionQuestion
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._sessionQuestionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionQuestionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedData<
                          Question,
                          $QuestionsTable,
                          Bookmark
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (revisionQueueRefs)
                        await $_getPrefetchedData<
                          Question,
                          $QuestionsTable,
                          RevisionQueueData
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._revisionQueueRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).revisionQueueRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$QuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $QuestionsTable,
      Question,
      $$QuestionsTableFilterComposer,
      $$QuestionsTableOrderingComposer,
      $$QuestionsTableAnnotationComposer,
      $$QuestionsTableCreateCompanionBuilder,
      $$QuestionsTableUpdateCompanionBuilder,
      (Question, $$QuestionsTableReferences),
      Question,
      PrefetchHooks Function({
        bool questionTranslationsRefs,
        bool questionTablesRefs,
        bool sessionQuestionsRefs,
        bool bookmarksRefs,
        bool revisionQueueRefs,
      })
    >;
typedef $$QuestionTranslationsTableCreateCompanionBuilder =
    QuestionTranslationsCompanion Function({
      required String questionUuid,
      required String language,
      required String strongDistractor,
      required String eliminationLogic,
      required String upscTrapExplanation,
      required String finalExplanation,
      Value<String?> statementAnalysis,
      Value<int> rowid,
    });
typedef $$QuestionTranslationsTableUpdateCompanionBuilder =
    QuestionTranslationsCompanion Function({
      Value<String> questionUuid,
      Value<String> language,
      Value<String> strongDistractor,
      Value<String> eliminationLogic,
      Value<String> upscTrapExplanation,
      Value<String> finalExplanation,
      Value<String?> statementAnalysis,
      Value<int> rowid,
    });

final class $$QuestionTranslationsTableReferences
    extends
        BaseReferences<
          _$UserDatabase,
          $QuestionTranslationsTable,
          QuestionTranslation
        > {
  $$QuestionTranslationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $QuestionsTable _questionUuidTable(_$UserDatabase db) =>
      db.questions.createAlias(
        $_aliasNameGenerator(
          db.questionTranslations.questionUuid,
          db.questions.uuid,
        ),
      );

  $$QuestionsTableProcessedTableManager get questionUuid {
    final $_column = $_itemColumn<String>('question_uuid')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestionTranslationsTableFilterComposer
    extends Composer<_$UserDatabase, $QuestionTranslationsTable> {
  $$QuestionTranslationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strongDistractor => $composableBuilder(
    column: $table.strongDistractor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eliminationLogic => $composableBuilder(
    column: $table.eliminationLogic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get upscTrapExplanation => $composableBuilder(
    column: $table.upscTrapExplanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalExplanation => $composableBuilder(
    column: $table.finalExplanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statementAnalysis => $composableBuilder(
    column: $table.statementAnalysis,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionsTableFilterComposer get questionUuid {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionTranslationsTableOrderingComposer
    extends Composer<_$UserDatabase, $QuestionTranslationsTable> {
  $$QuestionTranslationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strongDistractor => $composableBuilder(
    column: $table.strongDistractor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eliminationLogic => $composableBuilder(
    column: $table.eliminationLogic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get upscTrapExplanation => $composableBuilder(
    column: $table.upscTrapExplanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalExplanation => $composableBuilder(
    column: $table.finalExplanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statementAnalysis => $composableBuilder(
    column: $table.statementAnalysis,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionsTableOrderingComposer get questionUuid {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionTranslationsTableAnnotationComposer
    extends Composer<_$UserDatabase, $QuestionTranslationsTable> {
  $$QuestionTranslationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get strongDistractor => $composableBuilder(
    column: $table.strongDistractor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eliminationLogic => $composableBuilder(
    column: $table.eliminationLogic,
    builder: (column) => column,
  );

  GeneratedColumn<String> get upscTrapExplanation => $composableBuilder(
    column: $table.upscTrapExplanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalExplanation => $composableBuilder(
    column: $table.finalExplanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statementAnalysis => $composableBuilder(
    column: $table.statementAnalysis,
    builder: (column) => column,
  );

  $$QuestionsTableAnnotationComposer get questionUuid {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionTranslationsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $QuestionTranslationsTable,
          QuestionTranslation,
          $$QuestionTranslationsTableFilterComposer,
          $$QuestionTranslationsTableOrderingComposer,
          $$QuestionTranslationsTableAnnotationComposer,
          $$QuestionTranslationsTableCreateCompanionBuilder,
          $$QuestionTranslationsTableUpdateCompanionBuilder,
          (QuestionTranslation, $$QuestionTranslationsTableReferences),
          QuestionTranslation,
          PrefetchHooks Function({bool questionUuid})
        > {
  $$QuestionTranslationsTableTableManager(
    _$UserDatabase db,
    $QuestionTranslationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionTranslationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionTranslationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QuestionTranslationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> questionUuid = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> strongDistractor = const Value.absent(),
                Value<String> eliminationLogic = const Value.absent(),
                Value<String> upscTrapExplanation = const Value.absent(),
                Value<String> finalExplanation = const Value.absent(),
                Value<String?> statementAnalysis = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionTranslationsCompanion(
                questionUuid: questionUuid,
                language: language,
                strongDistractor: strongDistractor,
                eliminationLogic: eliminationLogic,
                upscTrapExplanation: upscTrapExplanation,
                finalExplanation: finalExplanation,
                statementAnalysis: statementAnalysis,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionUuid,
                required String language,
                required String strongDistractor,
                required String eliminationLogic,
                required String upscTrapExplanation,
                required String finalExplanation,
                Value<String?> statementAnalysis = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionTranslationsCompanion.insert(
                questionUuid: questionUuid,
                language: language,
                strongDistractor: strongDistractor,
                eliminationLogic: eliminationLogic,
                upscTrapExplanation: upscTrapExplanation,
                finalExplanation: finalExplanation,
                statementAnalysis: statementAnalysis,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionTranslationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionUuid = false}) {
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
                    if (questionUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionUuid,
                                referencedTable:
                                    $$QuestionTranslationsTableReferences
                                        ._questionUuidTable(db),
                                referencedColumn:
                                    $$QuestionTranslationsTableReferences
                                        ._questionUuidTable(db)
                                        .uuid,
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

typedef $$QuestionTranslationsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $QuestionTranslationsTable,
      QuestionTranslation,
      $$QuestionTranslationsTableFilterComposer,
      $$QuestionTranslationsTableOrderingComposer,
      $$QuestionTranslationsTableAnnotationComposer,
      $$QuestionTranslationsTableCreateCompanionBuilder,
      $$QuestionTranslationsTableUpdateCompanionBuilder,
      (QuestionTranslation, $$QuestionTranslationsTableReferences),
      QuestionTranslation,
      PrefetchHooks Function({bool questionUuid})
    >;
typedef $$QuestionTablesTableCreateCompanionBuilder =
    QuestionTablesCompanion Function({
      Value<int> id,
      required String questionUuid,
      Value<String?> enHeaderText,
      Value<String?> enFooterText,
      required String enColumns,
      required String enRows,
      Value<String?> hiHeaderText,
      Value<String?> hiFooterText,
      required String hiColumns,
      required String hiRows,
    });
typedef $$QuestionTablesTableUpdateCompanionBuilder =
    QuestionTablesCompanion Function({
      Value<int> id,
      Value<String> questionUuid,
      Value<String?> enHeaderText,
      Value<String?> enFooterText,
      Value<String> enColumns,
      Value<String> enRows,
      Value<String?> hiHeaderText,
      Value<String?> hiFooterText,
      Value<String> hiColumns,
      Value<String> hiRows,
    });

final class $$QuestionTablesTableReferences
    extends
        BaseReferences<_$UserDatabase, $QuestionTablesTable, QuestionTable> {
  $$QuestionTablesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $QuestionsTable _questionUuidTable(_$UserDatabase db) =>
      db.questions.createAlias(
        $_aliasNameGenerator(db.questionTables.questionUuid, db.questions.uuid),
      );

  $$QuestionsTableProcessedTableManager get questionUuid {
    final $_column = $_itemColumn<String>('question_uuid')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestionTablesTableFilterComposer
    extends Composer<_$UserDatabase, $QuestionTablesTable> {
  $$QuestionTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enHeaderText => $composableBuilder(
    column: $table.enHeaderText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enFooterText => $composableBuilder(
    column: $table.enFooterText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enColumns => $composableBuilder(
    column: $table.enColumns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enRows => $composableBuilder(
    column: $table.enRows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hiHeaderText => $composableBuilder(
    column: $table.hiHeaderText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hiFooterText => $composableBuilder(
    column: $table.hiFooterText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hiColumns => $composableBuilder(
    column: $table.hiColumns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hiRows => $composableBuilder(
    column: $table.hiRows,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionsTableFilterComposer get questionUuid {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionTablesTableOrderingComposer
    extends Composer<_$UserDatabase, $QuestionTablesTable> {
  $$QuestionTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enHeaderText => $composableBuilder(
    column: $table.enHeaderText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enFooterText => $composableBuilder(
    column: $table.enFooterText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enColumns => $composableBuilder(
    column: $table.enColumns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enRows => $composableBuilder(
    column: $table.enRows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hiHeaderText => $composableBuilder(
    column: $table.hiHeaderText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hiFooterText => $composableBuilder(
    column: $table.hiFooterText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hiColumns => $composableBuilder(
    column: $table.hiColumns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hiRows => $composableBuilder(
    column: $table.hiRows,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionsTableOrderingComposer get questionUuid {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionTablesTableAnnotationComposer
    extends Composer<_$UserDatabase, $QuestionTablesTable> {
  $$QuestionTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get enHeaderText => $composableBuilder(
    column: $table.enHeaderText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enFooterText => $composableBuilder(
    column: $table.enFooterText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enColumns =>
      $composableBuilder(column: $table.enColumns, builder: (column) => column);

  GeneratedColumn<String> get enRows =>
      $composableBuilder(column: $table.enRows, builder: (column) => column);

  GeneratedColumn<String> get hiHeaderText => $composableBuilder(
    column: $table.hiHeaderText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hiFooterText => $composableBuilder(
    column: $table.hiFooterText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hiColumns =>
      $composableBuilder(column: $table.hiColumns, builder: (column) => column);

  GeneratedColumn<String> get hiRows =>
      $composableBuilder(column: $table.hiRows, builder: (column) => column);

  $$QuestionsTableAnnotationComposer get questionUuid {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionTablesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $QuestionTablesTable,
          QuestionTable,
          $$QuestionTablesTableFilterComposer,
          $$QuestionTablesTableOrderingComposer,
          $$QuestionTablesTableAnnotationComposer,
          $$QuestionTablesTableCreateCompanionBuilder,
          $$QuestionTablesTableUpdateCompanionBuilder,
          (QuestionTable, $$QuestionTablesTableReferences),
          QuestionTable,
          PrefetchHooks Function({bool questionUuid})
        > {
  $$QuestionTablesTableTableManager(
    _$UserDatabase db,
    $QuestionTablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questionUuid = const Value.absent(),
                Value<String?> enHeaderText = const Value.absent(),
                Value<String?> enFooterText = const Value.absent(),
                Value<String> enColumns = const Value.absent(),
                Value<String> enRows = const Value.absent(),
                Value<String?> hiHeaderText = const Value.absent(),
                Value<String?> hiFooterText = const Value.absent(),
                Value<String> hiColumns = const Value.absent(),
                Value<String> hiRows = const Value.absent(),
              }) => QuestionTablesCompanion(
                id: id,
                questionUuid: questionUuid,
                enHeaderText: enHeaderText,
                enFooterText: enFooterText,
                enColumns: enColumns,
                enRows: enRows,
                hiHeaderText: hiHeaderText,
                hiFooterText: hiFooterText,
                hiColumns: hiColumns,
                hiRows: hiRows,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questionUuid,
                Value<String?> enHeaderText = const Value.absent(),
                Value<String?> enFooterText = const Value.absent(),
                required String enColumns,
                required String enRows,
                Value<String?> hiHeaderText = const Value.absent(),
                Value<String?> hiFooterText = const Value.absent(),
                required String hiColumns,
                required String hiRows,
              }) => QuestionTablesCompanion.insert(
                id: id,
                questionUuid: questionUuid,
                enHeaderText: enHeaderText,
                enFooterText: enFooterText,
                enColumns: enColumns,
                enRows: enRows,
                hiHeaderText: hiHeaderText,
                hiFooterText: hiFooterText,
                hiColumns: hiColumns,
                hiRows: hiRows,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionTablesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionUuid = false}) {
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
                    if (questionUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionUuid,
                                referencedTable: $$QuestionTablesTableReferences
                                    ._questionUuidTable(db),
                                referencedColumn:
                                    $$QuestionTablesTableReferences
                                        ._questionUuidTable(db)
                                        .uuid,
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

typedef $$QuestionTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $QuestionTablesTable,
      QuestionTable,
      $$QuestionTablesTableFilterComposer,
      $$QuestionTablesTableOrderingComposer,
      $$QuestionTablesTableAnnotationComposer,
      $$QuestionTablesTableCreateCompanionBuilder,
      $$QuestionTablesTableUpdateCompanionBuilder,
      (QuestionTable, $$QuestionTablesTableReferences),
      QuestionTable,
      PrefetchHooks Function({bool questionUuid})
    >;
typedef $$TopicTranslationsTableCreateCompanionBuilder =
    TopicTranslationsCompanion Function({
      Value<int> id,
      required String englishName,
      required String hindiName,
    });
typedef $$TopicTranslationsTableUpdateCompanionBuilder =
    TopicTranslationsCompanion Function({
      Value<int> id,
      Value<String> englishName,
      Value<String> hindiName,
    });

class $$TopicTranslationsTableFilterComposer
    extends Composer<_$UserDatabase, $TopicTranslationsTable> {
  $$TopicTranslationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hindiName => $composableBuilder(
    column: $table.hindiName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TopicTranslationsTableOrderingComposer
    extends Composer<_$UserDatabase, $TopicTranslationsTable> {
  $$TopicTranslationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hindiName => $composableBuilder(
    column: $table.hindiName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TopicTranslationsTableAnnotationComposer
    extends Composer<_$UserDatabase, $TopicTranslationsTable> {
  $$TopicTranslationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hindiName =>
      $composableBuilder(column: $table.hindiName, builder: (column) => column);
}

class $$TopicTranslationsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $TopicTranslationsTable,
          TopicTranslation,
          $$TopicTranslationsTableFilterComposer,
          $$TopicTranslationsTableOrderingComposer,
          $$TopicTranslationsTableAnnotationComposer,
          $$TopicTranslationsTableCreateCompanionBuilder,
          $$TopicTranslationsTableUpdateCompanionBuilder,
          (
            TopicTranslation,
            BaseReferences<
              _$UserDatabase,
              $TopicTranslationsTable,
              TopicTranslation
            >,
          ),
          TopicTranslation,
          PrefetchHooks Function()
        > {
  $$TopicTranslationsTableTableManager(
    _$UserDatabase db,
    $TopicTranslationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicTranslationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicTranslationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicTranslationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> englishName = const Value.absent(),
                Value<String> hindiName = const Value.absent(),
              }) => TopicTranslationsCompanion(
                id: id,
                englishName: englishName,
                hindiName: hindiName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String englishName,
                required String hindiName,
              }) => TopicTranslationsCompanion.insert(
                id: id,
                englishName: englishName,
                hindiName: hindiName,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TopicTranslationsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $TopicTranslationsTable,
      TopicTranslation,
      $$TopicTranslationsTableFilterComposer,
      $$TopicTranslationsTableOrderingComposer,
      $$TopicTranslationsTableAnnotationComposer,
      $$TopicTranslationsTableCreateCompanionBuilder,
      $$TopicTranslationsTableUpdateCompanionBuilder,
      (
        TopicTranslation,
        BaseReferences<
          _$UserDatabase,
          $TopicTranslationsTable,
          TopicTranslation
        >,
      ),
      TopicTranslation,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      required String subject,
      Value<String?> topic,
      Value<String?> subTopic,
      required String mode,
      required String status,
      required int questionCount,
      Value<int?> score,
      required bool isTimed,
      Value<int?> timeLimitSecs,
      Value<int?> examRemainingSecs,
      Value<String> language,
      Value<String?> analyticsFeatureKey,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<String> subject,
      Value<String?> topic,
      Value<String?> subTopic,
      Value<String> mode,
      Value<String> status,
      Value<int> questionCount,
      Value<int?> score,
      Value<bool> isTimed,
      Value<int?> timeLimitSecs,
      Value<int?> examRemainingSecs,
      Value<String> language,
      Value<String?> analyticsFeatureKey,
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

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subTopic => $composableBuilder(
    column: $table.subTopic,
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

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
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

  ColumnFilters<String> get analyticsFeatureKey => $composableBuilder(
    column: $table.analyticsFeatureKey,
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

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subTopic => $composableBuilder(
    column: $table.subTopic,
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

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
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

  ColumnOrderings<String> get analyticsFeatureKey => $composableBuilder(
    column: $table.analyticsFeatureKey,
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

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get subTopic =>
      $composableBuilder(column: $table.subTopic, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

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

  GeneratedColumn<String> get analyticsFeatureKey => $composableBuilder(
    column: $table.analyticsFeatureKey,
    builder: (column) => column,
  );

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
                Value<String> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> subTopic = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> questionCount = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<bool> isTimed = const Value.absent(),
                Value<int?> timeLimitSecs = const Value.absent(),
                Value<int?> examRemainingSecs = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> analyticsFeatureKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                createdAt: createdAt,
                completedAt: completedAt,
                subject: subject,
                topic: topic,
                subTopic: subTopic,
                mode: mode,
                status: status,
                questionCount: questionCount,
                score: score,
                isTimed: isTimed,
                timeLimitSecs: timeLimitSecs,
                examRemainingSecs: examRemainingSecs,
                language: language,
                analyticsFeatureKey: analyticsFeatureKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                required String subject,
                Value<String?> topic = const Value.absent(),
                Value<String?> subTopic = const Value.absent(),
                required String mode,
                required String status,
                required int questionCount,
                Value<int?> score = const Value.absent(),
                required bool isTimed,
                Value<int?> timeLimitSecs = const Value.absent(),
                Value<int?> examRemainingSecs = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> analyticsFeatureKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                completedAt: completedAt,
                subject: subject,
                topic: topic,
                subTopic: subTopic,
                mode: mode,
                status: status,
                questionCount: questionCount,
                score: score,
                isTimed: isTimed,
                timeLimitSecs: timeLimitSecs,
                examRemainingSecs: examRemainingSecs,
                language: language,
                analyticsFeatureKey: analyticsFeatureKey,
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
      Value<DateTime?> attemptedAt,
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
      Value<DateTime?> attemptedAt,
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

  static $QuestionsTable _questionUuidTable(_$UserDatabase db) =>
      db.questions.createAlias(
        $_aliasNameGenerator(
          db.sessionQuestions.questionUuid,
          db.questions.uuid,
        ),
      );

  $$QuestionsTableProcessedTableManager get questionUuid {
    final $_column = $_itemColumn<String>('question_uuid')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionUuidTable($_db));
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

  ColumnFilters<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
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

  $$QuestionsTableFilterComposer get questionUuid {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
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

  ColumnOrderings<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
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

  $$QuestionsTableOrderingComposer get questionUuid {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
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

  GeneratedColumn<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => column,
  );

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

  $$QuestionsTableAnnotationComposer get questionUuid {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
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
          PrefetchHooks Function({bool sessionId, bool questionUuid})
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
                Value<DateTime?> attemptedAt = const Value.absent(),
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
                attemptedAt: attemptedAt,
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
                Value<DateTime?> attemptedAt = const Value.absent(),
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
                attemptedAt: attemptedAt,
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
          prefetchHooksCallback: ({sessionId = false, questionUuid = false}) {
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
                    if (questionUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionUuid,
                                referencedTable:
                                    $$SessionQuestionsTableReferences
                                        ._questionUuidTable(db),
                                referencedColumn:
                                    $$SessionQuestionsTableReferences
                                        ._questionUuidTable(db)
                                        .uuid,
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
      PrefetchHooks Function({bool sessionId, bool questionUuid})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      required String questionUuid,
      required DateTime createdAt,
      Value<String?> userNote,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<String> questionUuid,
      Value<DateTime> createdAt,
      Value<String?> userNote,
      Value<int> rowid,
    });

final class $$BookmarksTableReferences
    extends BaseReferences<_$UserDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuestionsTable _questionUuidTable(_$UserDatabase db) =>
      db.questions.createAlias(
        $_aliasNameGenerator(db.bookmarks.questionUuid, db.questions.uuid),
      );

  $$QuestionsTableProcessedTableManager get questionUuid {
    final $_column = $_itemColumn<String>('question_uuid')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userNote => $composableBuilder(
    column: $table.userNote,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionsTableFilterComposer get questionUuid {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userNote => $composableBuilder(
    column: $table.userNote,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionsTableOrderingComposer get questionUuid {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get userNote =>
      $composableBuilder(column: $table.userNote, builder: (column) => column);

  $$QuestionsTableAnnotationComposer get questionUuid {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (Bookmark, $$BookmarksTableReferences),
          Bookmark,
          PrefetchHooks Function({bool questionUuid})
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
                Value<String?> userNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                questionUuid: questionUuid,
                createdAt: createdAt,
                userNote: userNote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String questionUuid,
                required DateTime createdAt,
                Value<String?> userNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                questionUuid: questionUuid,
                createdAt: createdAt,
                userNote: userNote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionUuid = false}) {
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
                    if (questionUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionUuid,
                                referencedTable: $$BookmarksTableReferences
                                    ._questionUuidTable(db),
                                referencedColumn: $$BookmarksTableReferences
                                    ._questionUuidTable(db)
                                    .uuid,
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
      (Bookmark, $$BookmarksTableReferences),
      Bookmark,
      PrefetchHooks Function({bool questionUuid})
    >;
typedef $$RevisionQueueTableCreateCompanionBuilder =
    RevisionQueueCompanion Function({
      required String id,
      required String questionUuid,
      required DateTime dateAddedToQueue,
      Value<int> numberOfTimesAnsweredCorrectlyInRevision,
      Value<int> numberOfTimesAnsweredIncorrectlyInRevision,
      Value<bool> hasGraduatedFromQueue,
      Value<DateTime?> dateGraduated,
      Value<int> rowid,
    });
typedef $$RevisionQueueTableUpdateCompanionBuilder =
    RevisionQueueCompanion Function({
      Value<String> id,
      Value<String> questionUuid,
      Value<DateTime> dateAddedToQueue,
      Value<int> numberOfTimesAnsweredCorrectlyInRevision,
      Value<int> numberOfTimesAnsweredIncorrectlyInRevision,
      Value<bool> hasGraduatedFromQueue,
      Value<DateTime?> dateGraduated,
      Value<int> rowid,
    });

final class $$RevisionQueueTableReferences
    extends
        BaseReferences<_$UserDatabase, $RevisionQueueTable, RevisionQueueData> {
  $$RevisionQueueTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $QuestionsTable _questionUuidTable(_$UserDatabase db) =>
      db.questions.createAlias(
        $_aliasNameGenerator(db.revisionQueue.questionUuid, db.questions.uuid),
      );

  $$QuestionsTableProcessedTableManager get questionUuid {
    final $_column = $_itemColumn<String>('question_uuid')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<DateTime> get dateAddedToQueue => $composableBuilder(
    column: $table.dateAddedToQueue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberOfTimesAnsweredCorrectlyInRevision =>
      $composableBuilder(
        column: $table.numberOfTimesAnsweredCorrectlyInRevision,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<int> get numberOfTimesAnsweredIncorrectlyInRevision =>
      $composableBuilder(
        column: $table.numberOfTimesAnsweredIncorrectlyInRevision,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<bool> get hasGraduatedFromQueue => $composableBuilder(
    column: $table.hasGraduatedFromQueue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateGraduated => $composableBuilder(
    column: $table.dateGraduated,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionsTableFilterComposer get questionUuid {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<DateTime> get dateAddedToQueue => $composableBuilder(
    column: $table.dateAddedToQueue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberOfTimesAnsweredCorrectlyInRevision =>
      $composableBuilder(
        column: $table.numberOfTimesAnsweredCorrectlyInRevision,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get numberOfTimesAnsweredIncorrectlyInRevision =>
      $composableBuilder(
        column: $table.numberOfTimesAnsweredIncorrectlyInRevision,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<bool> get hasGraduatedFromQueue => $composableBuilder(
    column: $table.hasGraduatedFromQueue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateGraduated => $composableBuilder(
    column: $table.dateGraduated,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionsTableOrderingComposer get questionUuid {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<DateTime> get dateAddedToQueue => $composableBuilder(
    column: $table.dateAddedToQueue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numberOfTimesAnsweredCorrectlyInRevision =>
      $composableBuilder(
        column: $table.numberOfTimesAnsweredCorrectlyInRevision,
        builder: (column) => column,
      );

  GeneratedColumn<int> get numberOfTimesAnsweredIncorrectlyInRevision =>
      $composableBuilder(
        column: $table.numberOfTimesAnsweredIncorrectlyInRevision,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get hasGraduatedFromQueue => $composableBuilder(
    column: $table.hasGraduatedFromQueue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateGraduated => $composableBuilder(
    column: $table.dateGraduated,
    builder: (column) => column,
  );

  $$QuestionsTableAnnotationComposer get questionUuid {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionUuid,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (RevisionQueueData, $$RevisionQueueTableReferences),
          RevisionQueueData,
          PrefetchHooks Function({bool questionUuid})
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
                Value<DateTime> dateAddedToQueue = const Value.absent(),
                Value<int> numberOfTimesAnsweredCorrectlyInRevision =
                    const Value.absent(),
                Value<int> numberOfTimesAnsweredIncorrectlyInRevision =
                    const Value.absent(),
                Value<bool> hasGraduatedFromQueue = const Value.absent(),
                Value<DateTime?> dateGraduated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionQueueCompanion(
                id: id,
                questionUuid: questionUuid,
                dateAddedToQueue: dateAddedToQueue,
                numberOfTimesAnsweredCorrectlyInRevision:
                    numberOfTimesAnsweredCorrectlyInRevision,
                numberOfTimesAnsweredIncorrectlyInRevision:
                    numberOfTimesAnsweredIncorrectlyInRevision,
                hasGraduatedFromQueue: hasGraduatedFromQueue,
                dateGraduated: dateGraduated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String questionUuid,
                required DateTime dateAddedToQueue,
                Value<int> numberOfTimesAnsweredCorrectlyInRevision =
                    const Value.absent(),
                Value<int> numberOfTimesAnsweredIncorrectlyInRevision =
                    const Value.absent(),
                Value<bool> hasGraduatedFromQueue = const Value.absent(),
                Value<DateTime?> dateGraduated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionQueueCompanion.insert(
                id: id,
                questionUuid: questionUuid,
                dateAddedToQueue: dateAddedToQueue,
                numberOfTimesAnsweredCorrectlyInRevision:
                    numberOfTimesAnsweredCorrectlyInRevision,
                numberOfTimesAnsweredIncorrectlyInRevision:
                    numberOfTimesAnsweredIncorrectlyInRevision,
                hasGraduatedFromQueue: hasGraduatedFromQueue,
                dateGraduated: dateGraduated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RevisionQueueTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionUuid = false}) {
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
                    if (questionUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionUuid,
                                referencedTable: $$RevisionQueueTableReferences
                                    ._questionUuidTable(db),
                                referencedColumn: $$RevisionQueueTableReferences
                                    ._questionUuidTable(db)
                                    .uuid,
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
      (RevisionQueueData, $$RevisionQueueTableReferences),
      RevisionQueueData,
      PrefetchHooks Function({bool questionUuid})
    >;
typedef $$UserTopicStatsTableCreateCompanionBuilder =
    UserTopicStatsCompanion Function({
      Value<int> id,
      required String subject,
      required String topic,
      Value<int> totalAttempted,
      Value<int> totalCorrect,
      Value<int> wrongAttempts,
      Value<int> totalTimeSpentSecs,
      Value<double> accuracyPercentage,
      required DateTime lastAttemptedAt,
    });
typedef $$UserTopicStatsTableUpdateCompanionBuilder =
    UserTopicStatsCompanion Function({
      Value<int> id,
      Value<String> subject,
      Value<String> topic,
      Value<int> totalAttempted,
      Value<int> totalCorrect,
      Value<int> wrongAttempts,
      Value<int> totalTimeSpentSecs,
      Value<double> accuracyPercentage,
      Value<DateTime> lastAttemptedAt,
    });

class $$UserTopicStatsTableFilterComposer
    extends Composer<_$UserDatabase, $UserTopicStatsTable> {
  $$UserTopicStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalAttempted => $composableBuilder(
    column: $table.totalAttempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCorrect => $composableBuilder(
    column: $table.totalCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrongAttempts => $composableBuilder(
    column: $table.wrongAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTimeSpentSecs => $composableBuilder(
    column: $table.totalTimeSpentSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyPercentage => $composableBuilder(
    column: $table.accuracyPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserTopicStatsTableOrderingComposer
    extends Composer<_$UserDatabase, $UserTopicStatsTable> {
  $$UserTopicStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalAttempted => $composableBuilder(
    column: $table.totalAttempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCorrect => $composableBuilder(
    column: $table.totalCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrongAttempts => $composableBuilder(
    column: $table.wrongAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTimeSpentSecs => $composableBuilder(
    column: $table.totalTimeSpentSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyPercentage => $composableBuilder(
    column: $table.accuracyPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserTopicStatsTableAnnotationComposer
    extends Composer<_$UserDatabase, $UserTopicStatsTable> {
  $$UserTopicStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<int> get totalAttempted => $composableBuilder(
    column: $table.totalAttempted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCorrect => $composableBuilder(
    column: $table.totalCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wrongAttempts => $composableBuilder(
    column: $table.wrongAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalTimeSpentSecs => $composableBuilder(
    column: $table.totalTimeSpentSecs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get accuracyPercentage => $composableBuilder(
    column: $table.accuracyPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => column,
  );
}

class $$UserTopicStatsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $UserTopicStatsTable,
          UserTopicStat,
          $$UserTopicStatsTableFilterComposer,
          $$UserTopicStatsTableOrderingComposer,
          $$UserTopicStatsTableAnnotationComposer,
          $$UserTopicStatsTableCreateCompanionBuilder,
          $$UserTopicStatsTableUpdateCompanionBuilder,
          (
            UserTopicStat,
            BaseReferences<_$UserDatabase, $UserTopicStatsTable, UserTopicStat>,
          ),
          UserTopicStat,
          PrefetchHooks Function()
        > {
  $$UserTopicStatsTableTableManager(
    _$UserDatabase db,
    $UserTopicStatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserTopicStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserTopicStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserTopicStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<int> totalAttempted = const Value.absent(),
                Value<int> totalCorrect = const Value.absent(),
                Value<int> wrongAttempts = const Value.absent(),
                Value<int> totalTimeSpentSecs = const Value.absent(),
                Value<double> accuracyPercentage = const Value.absent(),
                Value<DateTime> lastAttemptedAt = const Value.absent(),
              }) => UserTopicStatsCompanion(
                id: id,
                subject: subject,
                topic: topic,
                totalAttempted: totalAttempted,
                totalCorrect: totalCorrect,
                wrongAttempts: wrongAttempts,
                totalTimeSpentSecs: totalTimeSpentSecs,
                accuracyPercentage: accuracyPercentage,
                lastAttemptedAt: lastAttemptedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String subject,
                required String topic,
                Value<int> totalAttempted = const Value.absent(),
                Value<int> totalCorrect = const Value.absent(),
                Value<int> wrongAttempts = const Value.absent(),
                Value<int> totalTimeSpentSecs = const Value.absent(),
                Value<double> accuracyPercentage = const Value.absent(),
                required DateTime lastAttemptedAt,
              }) => UserTopicStatsCompanion.insert(
                id: id,
                subject: subject,
                topic: topic,
                totalAttempted: totalAttempted,
                totalCorrect: totalCorrect,
                wrongAttempts: wrongAttempts,
                totalTimeSpentSecs: totalTimeSpentSecs,
                accuracyPercentage: accuracyPercentage,
                lastAttemptedAt: lastAttemptedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserTopicStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $UserTopicStatsTable,
      UserTopicStat,
      $$UserTopicStatsTableFilterComposer,
      $$UserTopicStatsTableOrderingComposer,
      $$UserTopicStatsTableAnnotationComposer,
      $$UserTopicStatsTableCreateCompanionBuilder,
      $$UserTopicStatsTableUpdateCompanionBuilder,
      (
        UserTopicStat,
        BaseReferences<_$UserDatabase, $UserTopicStatsTable, UserTopicStat>,
      ),
      UserTopicStat,
      PrefetchHooks Function()
    >;
typedef $$UserFeatureStatsTableCreateCompanionBuilder =
    UserFeatureStatsCompanion Function({
      required String featureName,
      Value<int> totalViews,
      Value<int> totalStarts,
      Value<int> totalCompletions,
      required DateTime lastUsedAt,
      Value<int> rowid,
    });
typedef $$UserFeatureStatsTableUpdateCompanionBuilder =
    UserFeatureStatsCompanion Function({
      Value<String> featureName,
      Value<int> totalViews,
      Value<int> totalStarts,
      Value<int> totalCompletions,
      Value<DateTime> lastUsedAt,
      Value<int> rowid,
    });

class $$UserFeatureStatsTableFilterComposer
    extends Composer<_$UserDatabase, $UserFeatureStatsTable> {
  $$UserFeatureStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get featureName => $composableBuilder(
    column: $table.featureName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalViews => $composableBuilder(
    column: $table.totalViews,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalStarts => $composableBuilder(
    column: $table.totalStarts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCompletions => $composableBuilder(
    column: $table.totalCompletions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserFeatureStatsTableOrderingComposer
    extends Composer<_$UserDatabase, $UserFeatureStatsTable> {
  $$UserFeatureStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get featureName => $composableBuilder(
    column: $table.featureName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalViews => $composableBuilder(
    column: $table.totalViews,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalStarts => $composableBuilder(
    column: $table.totalStarts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCompletions => $composableBuilder(
    column: $table.totalCompletions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserFeatureStatsTableAnnotationComposer
    extends Composer<_$UserDatabase, $UserFeatureStatsTable> {
  $$UserFeatureStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get featureName => $composableBuilder(
    column: $table.featureName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalViews => $composableBuilder(
    column: $table.totalViews,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalStarts => $composableBuilder(
    column: $table.totalStarts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCompletions => $composableBuilder(
    column: $table.totalCompletions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$UserFeatureStatsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $UserFeatureStatsTable,
          UserFeatureStat,
          $$UserFeatureStatsTableFilterComposer,
          $$UserFeatureStatsTableOrderingComposer,
          $$UserFeatureStatsTableAnnotationComposer,
          $$UserFeatureStatsTableCreateCompanionBuilder,
          $$UserFeatureStatsTableUpdateCompanionBuilder,
          (
            UserFeatureStat,
            BaseReferences<
              _$UserDatabase,
              $UserFeatureStatsTable,
              UserFeatureStat
            >,
          ),
          UserFeatureStat,
          PrefetchHooks Function()
        > {
  $$UserFeatureStatsTableTableManager(
    _$UserDatabase db,
    $UserFeatureStatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserFeatureStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserFeatureStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserFeatureStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> featureName = const Value.absent(),
                Value<int> totalViews = const Value.absent(),
                Value<int> totalStarts = const Value.absent(),
                Value<int> totalCompletions = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserFeatureStatsCompanion(
                featureName: featureName,
                totalViews: totalViews,
                totalStarts: totalStarts,
                totalCompletions: totalCompletions,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String featureName,
                Value<int> totalViews = const Value.absent(),
                Value<int> totalStarts = const Value.absent(),
                Value<int> totalCompletions = const Value.absent(),
                required DateTime lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserFeatureStatsCompanion.insert(
                featureName: featureName,
                totalViews: totalViews,
                totalStarts: totalStarts,
                totalCompletions: totalCompletions,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserFeatureStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $UserFeatureStatsTable,
      UserFeatureStat,
      $$UserFeatureStatsTableFilterComposer,
      $$UserFeatureStatsTableOrderingComposer,
      $$UserFeatureStatsTableAnnotationComposer,
      $$UserFeatureStatsTableCreateCompanionBuilder,
      $$UserFeatureStatsTableUpdateCompanionBuilder,
      (
        UserFeatureStat,
        BaseReferences<_$UserDatabase, $UserFeatureStatsTable, UserFeatureStat>,
      ),
      UserFeatureStat,
      PrefetchHooks Function()
    >;
typedef $$UserTrapStatsTableCreateCompanionBuilder =
    UserTrapStatsCompanion Function({
      required String trapType,
      Value<int> totalFailures,
      required DateTime lastFailedAt,
      Value<int> rowid,
    });
typedef $$UserTrapStatsTableUpdateCompanionBuilder =
    UserTrapStatsCompanion Function({
      Value<String> trapType,
      Value<int> totalFailures,
      Value<DateTime> lastFailedAt,
      Value<int> rowid,
    });

class $$UserTrapStatsTableFilterComposer
    extends Composer<_$UserDatabase, $UserTrapStatsTable> {
  $$UserTrapStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trapType => $composableBuilder(
    column: $table.trapType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalFailures => $composableBuilder(
    column: $table.totalFailures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFailedAt => $composableBuilder(
    column: $table.lastFailedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserTrapStatsTableOrderingComposer
    extends Composer<_$UserDatabase, $UserTrapStatsTable> {
  $$UserTrapStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trapType => $composableBuilder(
    column: $table.trapType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalFailures => $composableBuilder(
    column: $table.totalFailures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFailedAt => $composableBuilder(
    column: $table.lastFailedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserTrapStatsTableAnnotationComposer
    extends Composer<_$UserDatabase, $UserTrapStatsTable> {
  $$UserTrapStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trapType =>
      $composableBuilder(column: $table.trapType, builder: (column) => column);

  GeneratedColumn<int> get totalFailures => $composableBuilder(
    column: $table.totalFailures,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastFailedAt => $composableBuilder(
    column: $table.lastFailedAt,
    builder: (column) => column,
  );
}

class $$UserTrapStatsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $UserTrapStatsTable,
          UserTrapStat,
          $$UserTrapStatsTableFilterComposer,
          $$UserTrapStatsTableOrderingComposer,
          $$UserTrapStatsTableAnnotationComposer,
          $$UserTrapStatsTableCreateCompanionBuilder,
          $$UserTrapStatsTableUpdateCompanionBuilder,
          (
            UserTrapStat,
            BaseReferences<_$UserDatabase, $UserTrapStatsTable, UserTrapStat>,
          ),
          UserTrapStat,
          PrefetchHooks Function()
        > {
  $$UserTrapStatsTableTableManager(_$UserDatabase db, $UserTrapStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserTrapStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserTrapStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserTrapStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trapType = const Value.absent(),
                Value<int> totalFailures = const Value.absent(),
                Value<DateTime> lastFailedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserTrapStatsCompanion(
                trapType: trapType,
                totalFailures: totalFailures,
                lastFailedAt: lastFailedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trapType,
                Value<int> totalFailures = const Value.absent(),
                required DateTime lastFailedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserTrapStatsCompanion.insert(
                trapType: trapType,
                totalFailures: totalFailures,
                lastFailedAt: lastFailedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserTrapStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $UserTrapStatsTable,
      UserTrapStat,
      $$UserTrapStatsTableFilterComposer,
      $$UserTrapStatsTableOrderingComposer,
      $$UserTrapStatsTableAnnotationComposer,
      $$UserTrapStatsTableCreateCompanionBuilder,
      $$UserTrapStatsTableUpdateCompanionBuilder,
      (
        UserTrapStat,
        BaseReferences<_$UserDatabase, $UserTrapStatsTable, UserTrapStat>,
      ),
      UserTrapStat,
      PrefetchHooks Function()
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$QuestionTranslationsTableTableManager get questionTranslations =>
      $$QuestionTranslationsTableTableManager(_db, _db.questionTranslations);
  $$QuestionTablesTableTableManager get questionTables =>
      $$QuestionTablesTableTableManager(_db, _db.questionTables);
  $$TopicTranslationsTableTableManager get topicTranslations =>
      $$TopicTranslationsTableTableManager(_db, _db.topicTranslations);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionQuestionsTableTableManager get sessionQuestions =>
      $$SessionQuestionsTableTableManager(_db, _db.sessionQuestions);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$RevisionQueueTableTableManager get revisionQueue =>
      $$RevisionQueueTableTableManager(_db, _db.revisionQueue);
  $$UserTopicStatsTableTableManager get userTopicStats =>
      $$UserTopicStatsTableTableManager(_db, _db.userTopicStats);
  $$UserFeatureStatsTableTableManager get userFeatureStats =>
      $$UserFeatureStatsTableTableManager(_db, _db.userFeatureStats);
  $$UserTrapStatsTableTableManager get userTrapStats =>
      $$UserTrapStatsTableTableManager(_db, _db.userTrapStats);
}
