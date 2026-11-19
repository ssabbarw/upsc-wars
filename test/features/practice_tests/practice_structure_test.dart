import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/features/practice_tests/domain/practice_test_splitter.dart';
import 'package:upsc_wars/features/practice_tests/providers/practice_catalog_provider.dart';

void main() {
  late UserDatabase db;

  setUp(() async {
    db = UserDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed(
    String uuid,
    String subject,
    String topic, {
    String sourceKind = 'static',
  }) async {
    await db
        .into(db.questions)
        .insert(
          QuestionsCompanion.insert(
            uuid: uuid,
            subject: subject,
            topic: topic,
            subTopic: 'st',
            questionType: 'direct',
            correctOption: 'a',
            conceptAnchor: 'c',
            conceptsUsed: '[]',
            enDisplayText: const Value('Stem'),
            sourceKind: Value(sourceKind),
          ),
        );
  }

  test('structure matches splitting each scope directly', () async {
    final polity = <String>[];
    final economy = <String>[];
    for (var i = 0; i < 70; i++) {
      final id = 'p$i';
      polity.add(id);
      await seed(id, 'Polity', i.isEven ? 'Parliament' : 'Judiciary');
    }
    for (var i = 0; i < 30; i++) {
      final id = 'e$i';
      economy.add(id);
      await seed(id, 'Economy', 'Banking');
    }
    await seed('pyq1', 'Polity', 'Parliament', sourceKind: 'pyq');

    final structure = await loadPracticeStructure(db, seasonYear: 2027);

    expect(
      structure.subjectGroups.keys,
      unorderedEquals(['Polity', 'Economy']),
    );
    expect(
      structure.subjectGroups['Polity'],
      splitIntoTests(
        season: 2027,
        scope: 'subject:Polity',
        uuids: polity,
        maxTests: maxSubjectPracticeTests,
      ),
    );
    expect(
      structure.topicGroups['Polity']!['Parliament'],
      splitIntoTests(
        season: 2027,
        scope: 'topic:Polity:Parliament',
        uuids: [for (var i = 0; i < 70; i += 2) 'p$i'],
        maxTests: maxTopicPracticeTests,
      ),
    );
    expect(
      structure.topicGroups['Economy']!['Banking'],
      splitIntoTests(
        season: 2027,
        scope: 'topic:Economy:Banking',
        uuids: economy,
        maxTests: maxTopicPracticeTests,
      ),
    );
    expect(
      structure.subjectGroups['Polity']!.expand((t) => t),
      isNot(contains('pyq1')),
    );
  });
}
