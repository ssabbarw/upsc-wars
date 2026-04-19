import 'test_question.dart';

Map<String, dynamic> statementAnalysisItemToMap(StatementAnalysisItem s) => {
  'label': s.label,
  'isCorrect': s.isCorrect,
  'reason': s.reason,
};

Map<String, dynamic>? questionTableDataToMap(QuestionTableData? t) {
  if (t == null) return null;
  return {
    'header': t.header,
    'footer': t.footer,
    'columns': t.columns,
    'rows': t.rows,
  };
}

/// JSON-safe map for Firestore + web share (same schema as web `uuids[]` items).
Map<String, dynamic> testQuestionToShareMap(TestQuestion q) {
  return {
    'uuid': q.uuid,
    'subject': q.subject,
    'topic': q.topic,
    'negativeFraming': q.negativeFraming,
    'displayText': q.displayText,
    'displayTextHi': q.displayTextHi,
    'optionA': q.optionA,
    'optionAHi': q.optionAHi,
    'optionB': q.optionB,
    'optionBHi': q.optionBHi,
    'optionC': q.optionC,
    'optionCHi': q.optionCHi,
    'optionD': q.optionD,
    'optionDHi': q.optionDHi,
    'correctOption': q.correctOption,
    'questionType': q.questionType,
    'trapType': q.trapType,
    'hasTable': q.hasTable,
    'tableData': questionTableDataToMap(q.tableData),
    'tableDataHi': questionTableDataToMap(q.tableDataHi),
    'position': q.position,
    'conceptAnchor': q.conceptAnchor,
    'finalExplanation': q.finalExplanation,
    'finalExplanationHi': q.finalExplanationHi,
    'eliminationLogic': q.eliminationLogic,
    'eliminationLogicHi': q.eliminationLogicHi,
    'statementAnalysis': q.statementAnalysis.map(statementAnalysisItemToMap).toList(),
    'statementAnalysisHi':
        q.statementAnalysisHi.map(statementAnalysisItemToMap).toList(),
    'strongDistractor': q.strongDistractor,
    'strongDistractorHi': q.strongDistractorHi,
    'upscTrapExplanation': q.upscTrapExplanation,
    'upscTrapExplanationHi': q.upscTrapExplanationHi,
    'conceptsUsed': q.conceptsUsed,
  };
}
