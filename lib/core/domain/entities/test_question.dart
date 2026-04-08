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

class TestQuestion {
  const TestQuestion({
    required this.uuid,
    required this.displayText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    required this.questionType,
    required this.trapType,
    required this.hasTable,
    required this.tableData,
    required this.position,
    required this.selectedOption,
    required this.status,
    required this.flagged,
    required this.timeSpentSecs,
    required this.conceptAnchor,
    required this.finalExplanation,
    required this.eliminationLogic,
    required this.statementAnalysis,
    required this.strongDistractor,
    required this.upscTrapExplanation,
    required this.conceptsUsed,
  });

  final String uuid;
  final String displayText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String? questionType;
  final String? trapType;
  final bool hasTable;
  final QuestionTableData? tableData;
  final int position;
  final String? selectedOption;
  final String status;
  final bool flagged;
  final int? timeSpentSecs;
  final String? conceptAnchor;
  final String? finalExplanation;
  final List<String> eliminationLogic;
  final List<StatementAnalysisItem> statementAnalysis;
  final String? strongDistractor;
  final String? upscTrapExplanation;
  final List<String> conceptsUsed;

  TestQuestion copyWith({
    String? selectedOption,
    String? status,
    bool? flagged,
    int? timeSpentSecs,
  }) {
    return TestQuestion(
      uuid: uuid,
      displayText: displayText,
      optionA: optionA,
      optionB: optionB,
      optionC: optionC,
      optionD: optionD,
      correctOption: correctOption,
      questionType: questionType,
      trapType: trapType,
      hasTable: hasTable,
      tableData: tableData,
      position: position,
      selectedOption: selectedOption ?? this.selectedOption,
      status: status ?? this.status,
      flagged: flagged ?? this.flagged,
      timeSpentSecs: timeSpentSecs ?? this.timeSpentSecs,
      conceptAnchor: conceptAnchor,
      finalExplanation: finalExplanation,
      eliminationLogic: eliminationLogic,
      statementAnalysis: statementAnalysis,
      strongDistractor: strongDistractor,
      upscTrapExplanation: upscTrapExplanation,
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
