import '../../../core/database/user_db.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/parsers/question_display_text_composer.dart';
import '../data/question_correction_mapper.dart';

/// Editable snapshot for the internal question editor.
class QuestionEditorDraft {
  const QuestionEditorDraft({
    required this.uuid,
    required this.subject,
    required this.topic,
    required this.subTopic,
    required this.questionType,
    required this.trapType,
    required this.correctOption,
    required this.conceptAnchor,
    required this.hasTable,
    required this.conceptsUsed,
    required this.stemEn,
    required this.optionAEn,
    required this.optionBEn,
    required this.optionCEn,
    required this.optionDEn,
    required this.stemHi,
    required this.optionAHi,
    required this.optionBHi,
    required this.optionCHi,
    required this.optionDHi,
    required this.finalExplanationBodyEn,
    required this.valueAdditionEn,
    required this.finalExplanationBodyHi,
    required this.valueAdditionHi,
    required this.eliminationLogicEn,
    required this.eliminationLogicHi,
    required this.statementAnalysisEn,
    required this.statementAnalysisHi,
    required this.strongDistractorEn,
    required this.strongDistractorHi,
    required this.upscTrapExplanationEn,
    required this.upscTrapExplanationHi,
  });

  final String uuid;
  final String subject;
  final String topic;
  final String subTopic;
  final String questionType;
  final String trapType;
  final String correctOption;
  final String conceptAnchor;
  final bool hasTable;
  final List<String> conceptsUsed;

  final String stemEn;
  final String optionAEn;
  final String optionBEn;
  final String optionCEn;
  final String optionDEn;

  final String stemHi;
  final String optionAHi;
  final String optionBHi;
  final String optionCHi;
  final String optionDHi;

  final String finalExplanationBodyEn;
  final String valueAdditionEn;
  final String finalExplanationBodyHi;
  final String valueAdditionHi;

  final List<String> eliminationLogicEn;
  final List<String> eliminationLogicHi;
  final List<StatementAnalysisItem> statementAnalysisEn;
  final List<StatementAnalysisItem> statementAnalysisHi;

  final String strongDistractorEn;
  final String strongDistractorHi;
  final String upscTrapExplanationEn;
  final String upscTrapExplanationHi;

  factory QuestionEditorDraft.fromLoaded({
    required Question row,
    required TestQuestion question,
  }) {
    final enParts = FinalExplanationParts.split(question.finalExplanation);
    final hiParts = FinalExplanationParts.split(question.finalExplanationHi);

    return QuestionEditorDraft(
      uuid: question.uuid,
      subject: row.subject,
      topic: row.topic,
      subTopic: row.subTopic,
      questionType: row.questionType,
      trapType: row.trapType ?? '',
      correctOption: row.correctOption,
      conceptAnchor: row.conceptAnchor,
      hasTable: row.hasTable,
      conceptsUsed: List<String>.from(question.conceptsUsed),
      stemEn: question.displayText,
      optionAEn: question.optionA,
      optionBEn: question.optionB,
      optionCEn: question.optionC,
      optionDEn: question.optionD,
      stemHi: question.displayTextHi,
      optionAHi: question.optionAHi,
      optionBHi: question.optionBHi,
      optionCHi: question.optionCHi,
      optionDHi: question.optionDHi,
      finalExplanationBodyEn: enParts.body,
      valueAdditionEn: enParts.valueAddition,
      finalExplanationBodyHi: hiParts.body,
      valueAdditionHi: hiParts.valueAddition,
      eliminationLogicEn: List<String>.from(question.eliminationLogic),
      eliminationLogicHi: List<String>.from(question.eliminationLogicHi),
      statementAnalysisEn: List<StatementAnalysisItem>.from(
        question.statementAnalysis,
      ),
      statementAnalysisHi: List<StatementAnalysisItem>.from(
        question.statementAnalysisHi,
      ),
      strongDistractorEn: question.strongDistractor ?? '',
      strongDistractorHi: question.strongDistractorHi ?? '',
      upscTrapExplanationEn: question.upscTrapExplanation ?? '',
      upscTrapExplanationHi: question.upscTrapExplanationHi ?? '',
    );
  }

  QuestionEditorDraft copyWith({
    String? correctOption,
    String? questionType,
    String? trapType,
    String? conceptAnchor,
    String? stemEn,
    String? optionAEn,
    String? optionBEn,
    String? optionCEn,
    String? optionDEn,
    String? stemHi,
    String? optionAHi,
    String? optionBHi,
    String? optionCHi,
    String? optionDHi,
    String? finalExplanationBodyEn,
    String? valueAdditionEn,
    String? finalExplanationBodyHi,
    String? valueAdditionHi,
    List<String>? eliminationLogicEn,
    List<String>? eliminationLogicHi,
    List<StatementAnalysisItem>? statementAnalysisEn,
    List<StatementAnalysisItem>? statementAnalysisHi,
    String? strongDistractorEn,
    String? strongDistractorHi,
    String? upscTrapExplanationEn,
    String? upscTrapExplanationHi,
  }) {
    return QuestionEditorDraft(
      uuid: uuid,
      subject: subject,
      topic: topic,
      subTopic: subTopic,
      questionType: questionType ?? this.questionType,
      trapType: trapType ?? this.trapType,
      correctOption: correctOption ?? this.correctOption,
      conceptAnchor: conceptAnchor ?? this.conceptAnchor,
      hasTable: hasTable,
      conceptsUsed: conceptsUsed,
      stemEn: stemEn ?? this.stemEn,
      optionAEn: optionAEn ?? this.optionAEn,
      optionBEn: optionBEn ?? this.optionBEn,
      optionCEn: optionCEn ?? this.optionCEn,
      optionDEn: optionDEn ?? this.optionDEn,
      stemHi: stemHi ?? this.stemHi,
      optionAHi: optionAHi ?? this.optionAHi,
      optionBHi: optionBHi ?? this.optionBHi,
      optionCHi: optionCHi ?? this.optionCHi,
      optionDHi: optionDHi ?? this.optionDHi,
      finalExplanationBodyEn:
          finalExplanationBodyEn ?? this.finalExplanationBodyEn,
      valueAdditionEn: valueAdditionEn ?? this.valueAdditionEn,
      finalExplanationBodyHi:
          finalExplanationBodyHi ?? this.finalExplanationBodyHi,
      valueAdditionHi: valueAdditionHi ?? this.valueAdditionHi,
      eliminationLogicEn: eliminationLogicEn ?? this.eliminationLogicEn,
      eliminationLogicHi: eliminationLogicHi ?? this.eliminationLogicHi,
      statementAnalysisEn: statementAnalysisEn ?? this.statementAnalysisEn,
      statementAnalysisHi: statementAnalysisHi ?? this.statementAnalysisHi,
      strongDistractorEn: strongDistractorEn ?? this.strongDistractorEn,
      strongDistractorHi: strongDistractorHi ?? this.strongDistractorHi,
      upscTrapExplanationEn:
          upscTrapExplanationEn ?? this.upscTrapExplanationEn,
      upscTrapExplanationHi:
          upscTrapExplanationHi ?? this.upscTrapExplanationHi,
    );
  }

  Map<String, dynamic> toCorrectionMap() =>
      QuestionCorrectionMapper.draftToCorrectionMap(this);

  bool isDirtyComparedTo(QuestionEditorDraft original) {
    if (correctOption != original.correctOption) return true;
    if (questionType != original.questionType) return true;
    if (trapType != original.trapType) return true;
    if (conceptAnchor != original.conceptAnchor) return true;
    if (stemEn != original.stemEn) return true;
    if (stemHi != original.stemHi) return true;
    if (optionAEn != original.optionAEn) return true;
    if (optionBEn != original.optionBEn) return true;
    if (optionCEn != original.optionCEn) return true;
    if (optionDEn != original.optionDEn) return true;
    if (optionAHi != original.optionAHi) return true;
    if (optionBHi != original.optionBHi) return true;
    if (optionCHi != original.optionCHi) return true;
    if (optionDHi != original.optionDHi) return true;
    if (finalExplanationBodyEn != original.finalExplanationBodyEn) return true;
    if (finalExplanationBodyHi != original.finalExplanationBodyHi) return true;
    if (valueAdditionEn != original.valueAdditionEn) return true;
    if (valueAdditionHi != original.valueAdditionHi) return true;
    if (strongDistractorEn != original.strongDistractorEn) return true;
    if (strongDistractorHi != original.strongDistractorHi) return true;
    if (upscTrapExplanationEn != original.upscTrapExplanationEn) return true;
    if (upscTrapExplanationHi != original.upscTrapExplanationHi) return true;
    if (!_listEquals(eliminationLogicEn, original.eliminationLogicEn)) {
      return true;
    }
    if (!_listEquals(eliminationLogicHi, original.eliminationLogicHi)) {
      return true;
    }
    if (!_statementListEquals(
      statementAnalysisEn,
      original.statementAnalysisEn,
    )) {
      return true;
    }
    if (!_statementListEquals(
      statementAnalysisHi,
      original.statementAnalysisHi,
    )) {
      return true;
    }
    return false;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _statementListEquals(
    List<StatementAnalysisItem> a,
    List<StatementAnalysisItem> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.label != right.label ||
          left.isCorrect != right.isCorrect ||
          left.reason != right.reason) {
        return false;
      }
    }
    return true;
  }
}

class QuestionFieldDiff {
  const QuestionFieldDiff({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final String before;
  final String after;

  bool get changed => before.trim() != after.trim();
}
