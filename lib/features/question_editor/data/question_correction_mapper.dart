import 'dart:convert';

import '../../../core/domain/entities/test_question.dart';
import '../../../core/parsers/question_display_text_composer.dart';
import '../domain/question_editor_draft.dart';

/// Builds Firestore correction maps and field diffs for the editor.
abstract final class QuestionCorrectionMapper {
  QuestionCorrectionMapper._();

  static Map<String, dynamic> draftToCorrectionMap(QuestionEditorDraft d) {
    final displayEn = QuestionDisplayTextComposer.compose(
      stem: d.stemEn,
      optionA: d.optionAEn,
      optionB: d.optionBEn,
      optionC: d.optionCEn,
      optionD: d.optionDEn,
    );
    final displayHi = QuestionDisplayTextComposer.compose(
      stem: d.stemHi,
      optionA: d.optionAHi,
      optionB: d.optionBHi,
      optionC: d.optionCHi,
      optionD: d.optionDHi,
    );

    return {
      'uuid': d.uuid,
      'meta': {
        'gs_subject': d.subject,
        'subject': d.subject,
        'topic': d.topic,
        'sub_topic': d.subTopic,
        'concepts_used': d.conceptsUsed,
      },
      'shared': {
        'question_type': d.questionType,
        'trap_type': d.trapType.isEmpty ? null : d.trapType,
        'concept_anchor': d.conceptAnchor,
        'correct_option': d.correctOption.toLowerCase(),
        'has_table': d.hasTable,
      },
      'en': _langPayload(
        displayText: displayEn,
        strongDistractor: d.strongDistractorEn,
        eliminationLogic: d.eliminationLogicEn,
        upscTrapExplanation: d.upscTrapExplanationEn,
        body: d.finalExplanationBodyEn,
        valueAddition: d.valueAdditionEn,
        statementAnalysis: d.statementAnalysisEn,
      ),
      'hi': _langPayload(
        displayText: displayHi,
        strongDistractor: d.strongDistractorHi,
        eliminationLogic: d.eliminationLogicHi,
        upscTrapExplanation: d.upscTrapExplanationHi,
        body: d.finalExplanationBodyHi,
        valueAddition: d.valueAdditionHi,
        statementAnalysis: d.statementAnalysisHi,
      ),
    };
  }

  static Map<String, dynamic> _langPayload({
    required String displayText,
    required String strongDistractor,
    required List<String> eliminationLogic,
    required String upscTrapExplanation,
    required String body,
    required String valueAddition,
    required List<StatementAnalysisItem> statementAnalysis,
  }) {
    return {
      'display_text': displayText,
      'strong_distractor': strongDistractor,
      'elimination_logic': eliminationLogic,
      'upsc_trap_explanation': upscTrapExplanation,
      'final_explanation': FinalExplanationParts.join(
        body: body,
        valueAddition: valueAddition,
      ),
      if (statementAnalysis.isNotEmpty)
        'statement_analysis': statementAnalysis
            .map(
              (s) => {
                'statement': s.label,
                'is_correct': s.isCorrect,
                'reason': s.reason,
              },
            )
            .toList(),
    };
  }

  static List<QuestionFieldDiff> diffDrafts(
    QuestionEditorDraft before,
    QuestionEditorDraft after,
  ) {
    String listStr(List<String> v) => v.join('\n');
    String stmtStr(List<StatementAnalysisItem> v) => v
        .map((s) => '${s.label} | ${s.isCorrect ? 'T' : 'F'} | ${s.reason}')
        .join('\n');

    final fields = <QuestionFieldDiff>[
      QuestionFieldDiff(
        label: 'Correct option',
        before: before.correctOption,
        after: after.correctOption,
      ),
      QuestionFieldDiff(
        label: 'Trap type',
        before: before.trapType,
        after: after.trapType,
      ),
      QuestionFieldDiff(
        label: 'EN statement',
        before: before.stemEn,
        after: after.stemEn,
      ),
      QuestionFieldDiff(
        label: 'EN option A',
        before: before.optionAEn,
        after: after.optionAEn,
      ),
      QuestionFieldDiff(
        label: 'EN option B',
        before: before.optionBEn,
        after: after.optionBEn,
      ),
      QuestionFieldDiff(
        label: 'EN option C',
        before: before.optionCEn,
        after: after.optionCEn,
      ),
      QuestionFieldDiff(
        label: 'EN option D',
        before: before.optionDEn,
        after: after.optionDEn,
      ),
      QuestionFieldDiff(
        label: 'EN explanation',
        before: before.finalExplanationBodyEn,
        after: after.finalExplanationBodyEn,
      ),
      QuestionFieldDiff(
        label: 'EN value addition',
        before: before.valueAdditionEn,
        after: after.valueAdditionEn,
      ),
      QuestionFieldDiff(
        label: 'EN elimination',
        before: listStr(before.eliminationLogicEn),
        after: listStr(after.eliminationLogicEn),
      ),
      QuestionFieldDiff(
        label: 'EN statement analysis',
        before: stmtStr(before.statementAnalysisEn),
        after: stmtStr(after.statementAnalysisEn),
      ),
      QuestionFieldDiff(
        label: 'EN strong distractor',
        before: before.strongDistractorEn,
        after: after.strongDistractorEn,
      ),
      QuestionFieldDiff(
        label: 'EN trap explanation',
        before: before.upscTrapExplanationEn,
        after: after.upscTrapExplanationEn,
      ),
      QuestionFieldDiff(
        label: 'HI statement',
        before: before.stemHi,
        after: after.stemHi,
      ),
      QuestionFieldDiff(
        label: 'HI option A',
        before: before.optionAHi,
        after: after.optionAHi,
      ),
      QuestionFieldDiff(
        label: 'HI option B',
        before: before.optionBHi,
        after: after.optionBHi,
      ),
      QuestionFieldDiff(
        label: 'HI option C',
        before: before.optionCHi,
        after: after.optionCHi,
      ),
      QuestionFieldDiff(
        label: 'HI option D',
        before: before.optionDHi,
        after: after.optionDHi,
      ),
      QuestionFieldDiff(
        label: 'HI explanation',
        before: before.finalExplanationBodyHi,
        after: after.finalExplanationBodyHi,
      ),
      QuestionFieldDiff(
        label: 'HI value addition',
        before: before.valueAdditionHi,
        after: after.valueAdditionHi,
      ),
      QuestionFieldDiff(
        label: 'HI elimination',
        before: listStr(before.eliminationLogicHi),
        after: listStr(after.eliminationLogicHi),
      ),
      QuestionFieldDiff(
        label: 'HI statement analysis',
        before: stmtStr(before.statementAnalysisHi),
        after: stmtStr(after.statementAnalysisHi),
      ),
      QuestionFieldDiff(
        label: 'HI strong distractor',
        before: before.strongDistractorHi,
        after: after.strongDistractorHi,
      ),
      QuestionFieldDiff(
        label: 'HI trap explanation',
        before: before.upscTrapExplanationHi,
        after: after.upscTrapExplanationHi,
      ),
    ];

    return fields.where((f) => f.changed).toList();
  }

  /// Parses correction maps from Firestore `question_corrections/active`.
  static List<Map<String, dynamic>> parseActiveCorrections(
    Map<String, dynamic> data,
  ) {
    final raw = data['corrections'];
    if (raw is Map) {
      return raw.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  static int readActiveRevision(Map<String, dynamic>? data) {
    if (data == null) return 0;
    final rev = data['revision'];
    if (rev is int) return rev;
    if (rev is num) return rev.toInt();
    return 0;
  }

  static String debugJson(Object? value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
