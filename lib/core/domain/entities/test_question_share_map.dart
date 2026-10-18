import 'test_question.dart';

Map<String, dynamic> statementAnalysisItemToMap(StatementAnalysisItem s) => {
  'label': s.label,
  'isCorrect': s.isCorrect,
  'reason': s.reason,
};

Map<String, dynamic>? questionTableDataToMap(QuestionTableData? t) {
  if (t == null) return null;
  // Firestore rejects nested arrays (e.g. rows as List<List<String>>).
  // Store each row as a map with a string array of cells.
  return {
    'header': t.header,
    'footer': t.footer,
    'columns': t.columns,
    'rows': t.rows.map((row) => <String, dynamic>{'cells': row}).toList(),
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
    'statementAnalysis': q.statementAnalysis
        .map(statementAnalysisItemToMap)
        .toList(),
    'statementAnalysisHi': q.statementAnalysisHi
        .map(statementAnalysisItemToMap)
        .toList(),
    'strongDistractor': q.strongDistractor,
    'strongDistractorHi': q.strongDistractorHi,
    'upscTrapExplanation': q.upscTrapExplanation,
    'upscTrapExplanationHi': q.upscTrapExplanationHi,
    'conceptsUsed': q.conceptsUsed,
  };
}

String _shareStr(Map<dynamic, dynamic> m, String key, [String d = '']) {
  final v = m[key];
  if (v is String) return v;
  if (v != null) return v.toString();
  return d;
}

bool _shareBool(Map<dynamic, dynamic> m, String key, [bool d = false]) {
  final v = m[key];
  if (v is bool) return v;
  return d;
}

List<String> _shareStringList(Object? v) {
  if (v is! List) return const [];
  return v.map((e) => e.toString()).toList();
}

QuestionTableData? _questionTableFromShare(Object? raw) {
  if (raw is! Map) return null;
  final m = Map<dynamic, dynamic>.from(raw);
  final cols = _shareStringList(m['columns']);
  if (cols.isEmpty) return null;
  return QuestionTableData(
    header: m['header'] as String?,
    footer: m['footer'] as String?,
    columns: cols,
    rows: questionTableRowsAsCells(m['rows'], cols),
  );
}

List<StatementAnalysisItem> _statementList(Object? v) {
  if (v is! List) return const [];
  final out = <StatementAnalysisItem>[];
  for (final e in v) {
    if (e is Map) {
      final m = Map<dynamic, dynamic>.from(e);
      out.add(
        StatementAnalysisItem(
          label: _shareStr(m, 'label'),
          isCorrect: _shareBool(m, 'isCorrect'),
          reason: _shareStr(m, 'reason'),
        ),
      );
    }
  }
  return out;
}

/// Rebuilds [TestQuestion] from Firestore / share JSON ([testQuestionToShareMap]).
TestQuestion testQuestionFromShareMap(
  Map<String, dynamic> raw, {
  required int position,
  required String subject,
  required String topic,
}) {
  final m = Map<dynamic, dynamic>.from(raw);
  return TestQuestion(
    uuid: _shareStr(m, 'uuid'),
    subject: _shareStr(m, 'subject', subject),
    topic: _shareStr(m, 'topic', topic),
    negativeFraming: _shareBool(m, 'negativeFraming'),
    displayText: _shareStr(m, 'displayText'),
    displayTextHi: _shareStr(m, 'displayTextHi'),
    optionA: _shareStr(m, 'optionA'),
    optionAHi: _shareStr(m, 'optionAHi'),
    optionB: _shareStr(m, 'optionB'),
    optionBHi: _shareStr(m, 'optionBHi'),
    optionC: _shareStr(m, 'optionC'),
    optionCHi: _shareStr(m, 'optionCHi'),
    optionD: _shareStr(m, 'optionD'),
    optionDHi: _shareStr(m, 'optionDHi'),
    correctOption: _shareStr(m, 'correctOption', 'a'),
    questionType: m['questionType'] as String?,
    trapType: m['trapType'] as String?,
    hasTable: _shareBool(m, 'hasTable'),
    tableData: _questionTableFromShare(m['tableData']),
    tableDataHi: _questionTableFromShare(m['tableDataHi']),
    position: position,
    selectedOption: m['selectedOption'] as String?,
    status: _shareStr(m, 'status', 'unattempted'),
    flagged: _shareBool(m, 'flagged'),
    timeSpentSecs: (m['timeSpentSecs'] is num)
        ? (m['timeSpentSecs'] as num).toInt()
        : null,
    confidence: m['confidence'] as String?,
    conceptAnchor: m['conceptAnchor'] as String?,
    finalExplanation: m['finalExplanation'] as String?,
    finalExplanationHi: m['finalExplanationHi'] as String?,
    eliminationLogic: _shareStringList(m['eliminationLogic']),
    eliminationLogicHi: _shareStringList(m['eliminationLogicHi']),
    statementAnalysis: _statementList(m['statementAnalysis']),
    statementAnalysisHi: _statementList(m['statementAnalysisHi']),
    strongDistractor: m['strongDistractor'] as String?,
    strongDistractorHi: m['strongDistractorHi'] as String?,
    upscTrapExplanation: m['upscTrapExplanation'] as String?,
    upscTrapExplanationHi: m['upscTrapExplanationHi'] as String?,
    conceptsUsed: _shareStringList(m['conceptsUsed']),
  );
}
