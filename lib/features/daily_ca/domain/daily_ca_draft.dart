import '../domain/ca_revision_tags.dart';
import '../domain/daily_ca_schedule.dart';

class DailyCaDraftQuestion {
  const DailyCaDraftQuestion({
    required this.draftId,
    required this.chosen,
    required this.gsSubject,
    required this.topic,
    required this.caTags,
    required this.correctOption,
    required this.questionType,
    required this.preview,
    required this.raw,
  });

  final String draftId;
  final bool chosen;
  final String gsSubject;
  final String topic;
  final List<String> caTags;
  final String correctOption;
  final String questionType;
  final String preview;
  final Map<String, dynamic> raw;

  bool get hasTable =>
      raw['shared'] is Map && (raw['shared'] as Map)['has_table'] == true;

  DailyCaDraftQuestion copyChosen(bool value) {
    final next = Map<String, dynamic>.from(raw);
    next['chosen'] = value;
    next['draft_id'] = draftId;
    return DailyCaDraftQuestion(
      draftId: draftId,
      chosen: value,
      gsSubject: gsSubject,
      topic: topic,
      caTags: caTags,
      correctOption: correctOption,
      questionType: questionType,
      preview: preview,
      raw: next,
    );
  }

  static DailyCaDraftQuestion fromMap(Map<String, dynamic> raw, int index) {
    final meta = raw['meta'] is Map
        ? Map<String, dynamic>.from(raw['meta'] as Map)
        : <String, dynamic>{};
    final shared = raw['shared'] is Map
        ? Map<String, dynamic>.from(raw['shared'] as Map)
        : <String, dynamic>{};
    final en = raw['en'] is Map
        ? Map<String, dynamic>.from(raw['en'] as Map)
        : <String, dynamic>{};
    final draftId = (raw['draft_id'] ?? raw['uuid'] ?? 'd${index + 1}')
        .toString();
    final tags = CaRevisionTags.sanitizeTags(
      meta['ca_tags'] ?? meta['concepts_used'],
    );
    final display = (en['display_text'] ?? '').toString().trim();
    final header = en['table_data'] is Map
        ? (en['table_data'] as Map)['header_text']?.toString() ?? ''
        : '';
    final preview = display.isNotEmpty
        ? display
        : (header.isNotEmpty ? header : 'Question ${index + 1}');
    return DailyCaDraftQuestion(
      draftId: draftId,
      chosen: raw['chosen'] == true,
      gsSubject: (meta['gs_subject'] ?? '').toString(),
      topic: (meta['topic'] ?? '').toString(),
      caTags: tags,
      correctOption: (shared['correct_option'] ?? 'a').toString(),
      questionType: (shared['question_type'] ?? 'direct').toString(),
      preview: preview,
      raw: raw,
    );
  }
}

class DailyCaDraft {
  const DailyCaDraft({
    required this.date,
    required this.status,
    required this.opensAt,
    required this.isWeekendPack,
    required this.chosenIds,
    required this.questions,
  });

  final String date;
  final String status;
  final String opensAt;
  final bool isWeekendPack;
  final List<String> chosenIds;
  final List<DailyCaDraftQuestion> questions;

  bool get isPublished => status == 'published';

  bool isFrozen({DateTime? referenceIst}) {
    return DailyCaSchedule.isPublishedForDate(
      DailyCaSchedule.parseIsoDate(date),
      referenceIst: referenceIst,
    );
  }

  int get chosenCount => questions.where((q) => q.chosen).length;

  static DailyCaDraft fromDoc(String date, Map<String, dynamic> data) {
    final rawQuestions = data['questions'];
    final list = <DailyCaDraftQuestion>[];
    if (rawQuestions is List) {
      for (var i = 0; i < rawQuestions.length; i++) {
        final item = rawQuestions[i];
        if (item is Map) {
          list.add(
            DailyCaDraftQuestion.fromMap(
              Map<String, dynamic>.from(item),
              i,
            ),
          );
        }
      }
    }
    final chosenRaw = data['chosen_uuids'];
    var chosenIds = chosenRaw is List
        ? chosenRaw.map((e) => e.toString()).toList()
        : list.where((q) => q.chosen).map((q) => q.draftId).toList();
    if (chosenIds.isNotEmpty) {
      final want = chosenIds.toSet();
      for (var i = 0; i < list.length; i++) {
        if (want.contains(list[i].draftId) && !list[i].chosen) {
          list[i] = list[i].copyChosen(true);
        }
      }
    }
    return DailyCaDraft(
      date: date,
      status: (data['status'] ?? 'ready').toString(),
      opensAt: (data['opens_at'] ?? '').toString(),
      isWeekendPack: data['is_weekend_pack'] == true,
      chosenIds: chosenIds,
      questions: list,
    );
  }
}
