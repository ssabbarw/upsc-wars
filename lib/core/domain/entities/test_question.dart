/// Sentinel for [TestQuestion.copyWith] so `confidence: null` clears the field.
enum _ConfidenceCopyUnset { unset }

class QuestionTableData {
  const QuestionTableData({
    required this.header,
    required this.footer,
    required this.columns,
    required this.rows,
  });

  final String? header;
  final String? footer;
  final List<String> columns;
  final List<List<String>> rows;
}

/// Cell from a Firestore table row (array, or map with column / col_i / list_i keys).
String questionTableCell(Map<Object?, Object?> row, String column, int index) {
  final byCol = row[column];
  if (byCol != null && byCol.toString().isNotEmpty) return byCol.toString();
  final byIndex = row['col_$index'];
  if (byIndex != null && byIndex.toString().isNotEmpty) return byIndex.toString();
  if (index == 0) {
    final v = row['list_i'];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  if (index == 1) {
    final v = row['list_ii'];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return '';
}

/// Normalizes table `rows` to lists of cells so exam UI can render map-shaped CA rows.
List<List<String>> questionTableRowsAsCells(
  Object? rowsRaw,
  List<String> columns,
) {
  if (rowsRaw is! List) return const [];
  final out = <List<String>>[];
  for (final row in rowsRaw) {
    if (row is List) {
      out.add(row.map((e) => e?.toString() ?? '').toList());
    } else if (row is Map) {
      final cells = row['cells'];
      if (cells is List) {
        out.add(cells.map((e) => e?.toString() ?? '').toList());
        continue;
      }
      if (columns.isEmpty) continue;
      out.add([
        for (var i = 0; i < columns.length; i++)
          questionTableCell(row, columns[i], i),
      ]);
    }
  }
  return out;
}

class TestQuestion {
  const TestQuestion({
    required this.uuid,
    required this.subject,
    required this.topic,
    required this.negativeFraming,
    required this.displayText,
    required this.displayTextHi,
    required this.optionA,
    required this.optionAHi,
    required this.optionB,
    required this.optionBHi,
    required this.optionC,
    required this.optionCHi,
    required this.optionD,
    required this.optionDHi,
    required this.correctOption,
    required this.questionType,
    required this.trapType,
    required this.hasTable,
    required this.tableData,
    required this.tableDataHi,
    required this.position,
    required this.selectedOption,
    required this.status,
    required this.flagged,
    required this.timeSpentSecs,
    required this.confidence,
    required this.conceptAnchor,
    required this.finalExplanation,
    required this.finalExplanationHi,
    required this.eliminationLogic,
    required this.eliminationLogicHi,
    required this.statementAnalysis,
    required this.statementAnalysisHi,
    required this.strongDistractor,
    required this.strongDistractorHi,
    required this.upscTrapExplanation,
    required this.upscTrapExplanationHi,
    required this.conceptsUsed,
  });

  final String uuid;
  final String subject;
  final String topic;
  final bool negativeFraming;
  final String displayText;
  final String displayTextHi;
  final String optionA;
  final String optionAHi;
  final String optionB;
  final String optionBHi;
  final String optionC;
  final String optionCHi;
  final String optionD;
  final String optionDHi;
  final String correctOption;
  final String? questionType;
  final String? trapType;
  final bool hasTable;
  final QuestionTableData? tableData;
  final QuestionTableData? tableDataHi;
  final int position;
  final String? selectedOption;
  final String status;
  final bool flagged;
  final int? timeSpentSecs;
  /// `AnswerConfidence.*` or null if not captured.
  final String? confidence;
  final String? conceptAnchor;
  final String? finalExplanation;
  final String? finalExplanationHi;
  final List<String> eliminationLogic;
  final List<String> eliminationLogicHi;
  final List<StatementAnalysisItem> statementAnalysis;
  final List<StatementAnalysisItem> statementAnalysisHi;
  final String? strongDistractor;
  final String? strongDistractorHi;
  final String? upscTrapExplanation;
  final String? upscTrapExplanationHi;
  final List<String> conceptsUsed;

  TestQuestion copyWith({
    String? selectedOption,
    String? status,
    bool? flagged,
    int? timeSpentSecs,
    Object? confidence = _ConfidenceCopyUnset.unset,
  }) {
    final String? nextConfidence;
    if (identical(confidence, _ConfidenceCopyUnset.unset)) {
      nextConfidence = this.confidence;
    } else {
      nextConfidence = confidence as String?;
    }

    return TestQuestion(
      uuid: uuid,
      subject: subject,
      topic: topic,
      negativeFraming: negativeFraming,
      displayText: displayText,
      displayTextHi: displayTextHi,
      optionA: optionA,
      optionAHi: optionAHi,
      optionB: optionB,
      optionBHi: optionBHi,
      optionC: optionC,
      optionCHi: optionCHi,
      optionD: optionD,
      optionDHi: optionDHi,
      correctOption: correctOption,
      questionType: questionType,
      trapType: trapType,
      hasTable: hasTable,
      tableData: tableData,
      tableDataHi: tableDataHi,
      position: position,
      selectedOption: selectedOption ?? this.selectedOption,
      status: status ?? this.status,
      flagged: flagged ?? this.flagged,
      timeSpentSecs: timeSpentSecs ?? this.timeSpentSecs,
      confidence: nextConfidence,
      conceptAnchor: conceptAnchor,
      finalExplanation: finalExplanation,
      finalExplanationHi: finalExplanationHi,
      eliminationLogic: eliminationLogic,
      eliminationLogicHi: eliminationLogicHi,
      statementAnalysis: statementAnalysis,
      statementAnalysisHi: statementAnalysisHi,
      strongDistractor: strongDistractor,
      strongDistractorHi: strongDistractorHi,
      upscTrapExplanation: upscTrapExplanation,
      upscTrapExplanationHi: upscTrapExplanationHi,
      conceptsUsed: conceptsUsed,
    );
  }
}

class StatementAnalysisItem {
  const StatementAnalysisItem({
    required this.label,
    required this.isCorrect,
    required this.reason,
  });

  final String label;
  final bool isCorrect;
  final String reason;
}
