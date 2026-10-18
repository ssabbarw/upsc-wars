import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/parsers/question_display_text_parser.dart';
import '../../../l10n/l10n.dart';

typedef FomoPulseHistoryData = ({
  List<FomoPulse> pulses,
  Map<String, FomoPulseAttemptState> attempts,
});

class FomoPulseArticlePreview {
  const FomoPulseArticlePreview({
    required this.imageUrl,
    required this.imageSource,
    required this.ogTitle,
    required this.ogDescription,
  });

  final String imageUrl;
  final String imageSource;
  final String ogTitle;
  final String ogDescription;
}

class FomoPulseHarvestCandidate {
  const FomoPulseHarvestCandidate({
    required this.draftId,
    required this.title,
    required this.preview,
    required this.gsSubject,
    required this.sourceUrl,
    required this.newsImportance,
    required this.newsSummary,
    this.upscPoints = const [],
  });

  final String draftId;
  final String title;
  final String preview;
  final String gsSubject;
  final String sourceUrl;
  final int newsImportance;
  final String newsSummary;
  final List<String> upscPoints;

  factory FomoPulseHarvestCandidate.fromMap(Map<String, dynamic> map) {
    final pointsRaw = map['upsc_points'];
    return FomoPulseHarvestCandidate(
      draftId: (map['draft_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      preview: (map['preview'] ?? '').toString(),
      gsSubject: (map['gs_subject'] ?? '').toString(),
      sourceUrl: (map['source_url'] ?? '').toString(),
      newsImportance: (map['news_importance'] as num?)?.toInt() ?? 3,
      newsSummary: (map['news_summary'] ?? '').toString(),
      upscPoints: pointsRaw is List
          ? [
              for (final p in pointsRaw)
                if (p.toString().trim().isNotEmpty) p.toString().trim(),
            ]
          : const [],
    );
  }
}

class FomoPulseArticleArgs {
  const FomoPulseArticleArgs.harvest({
    required this.draftDate,
    required this.candidate,
  }) : url = null,
       savedDraft = null;

  const FomoPulseArticleArgs.url({required this.url, this.savedDraft})
    : draftDate = null,
      candidate = null;

  final String? draftDate;
  final FomoPulseHarvestCandidate? candidate;
  final String? url;

  /// Pre-filled draft from local storage (admin reuse flow).
  final FomoPulseDraft? savedDraft;

  bool get isHarvest => candidate != null && draftDate != null;

  String get sourceUrl => (candidate?.sourceUrl ?? url ?? '').trim();

  String get heading => (candidate?.title ?? '').trim();

  String get summary => (candidate?.newsSummary ?? '').trim();
}

class FomoPulseQuestion {
  const FomoPulseQuestion({
    required this.displayText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.questionType = 'direct',
    this.strongDistractor = '',
    this.eliminationLogic = const [],
    this.upscTrapExplanation = '',
    this.statementAnalysis = const [],
    required this.finalExplanation,
    required this.gsSubject,
    required this.topic,
    required this.newsTrigger,
    this.displayTextHi = '',
    this.optionAHi = '',
    this.optionBHi = '',
    this.optionCHi = '',
    this.optionDHi = '',
    this.strongDistractorHi = '',
    this.eliminationLogicHi = const [],
    this.upscTrapExplanationHi = '',
    this.statementAnalysisHi = const [],
    this.finalExplanationHi = '',
  });

  final String displayText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String questionType;
  final String strongDistractor;
  final List<String> eliminationLogic;
  final String upscTrapExplanation;
  final List<FomoPulseStatementAnalysisItem> statementAnalysis;
  final String finalExplanation;
  final String gsSubject;
  final String topic;
  final String newsTrigger;
  final String displayTextHi;
  final String optionAHi;
  final String optionBHi;
  final String optionCHi;
  final String optionDHi;
  final String strongDistractorHi;
  final List<String> eliminationLogicHi;
  final String upscTrapExplanationHi;
  final List<FomoPulseStatementAnalysisItem> statementAnalysisHi;
  final String finalExplanationHi;

  bool get hasHindi => displayTextHi.trim().isNotEmpty;

  bool get hasSeparateOptions =>
      optionA.trim().isNotEmpty &&
      optionB.trim().isNotEmpty &&
      optionC.trim().isNotEmpty &&
      optionD.trim().isNotEmpty;

  String get stemText => QuestionDisplayTextParser.stemOnly(
    displayText,
    hasSeparateOptions: hasSeparateOptions,
  );

  FomoPulseQuestion localized(bool hindi) {
    if (!hindi || !hasHindi) return this;
    return copyWith(
      displayText: displayTextHi,
      optionA: optionAHi.isNotEmpty ? optionAHi : optionA,
      optionB: optionBHi.isNotEmpty ? optionBHi : optionB,
      optionC: optionCHi.isNotEmpty ? optionCHi : optionC,
      optionD: optionDHi.isNotEmpty ? optionDHi : optionD,
      strongDistractor: strongDistractorHi.isNotEmpty
          ? strongDistractorHi
          : strongDistractor,
      eliminationLogic: eliminationLogicHi.isNotEmpty
          ? eliminationLogicHi
          : eliminationLogic,
      upscTrapExplanation: upscTrapExplanationHi.isNotEmpty
          ? upscTrapExplanationHi
          : upscTrapExplanation,
      statementAnalysis: statementAnalysisHi.isNotEmpty
          ? statementAnalysisHi
          : statementAnalysis,
      finalExplanation: finalExplanationHi.isNotEmpty
          ? finalExplanationHi
          : finalExplanation,
    );
  }

  FomoPulseQuestion copyWith({
    String? displayText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
    String? questionType,
    String? strongDistractor,
    List<String>? eliminationLogic,
    String? upscTrapExplanation,
    List<FomoPulseStatementAnalysisItem>? statementAnalysis,
    String? finalExplanation,
    String? gsSubject,
    String? topic,
    String? newsTrigger,
    String? displayTextHi,
    String? optionAHi,
    String? optionBHi,
    String? optionCHi,
    String? optionDHi,
    String? strongDistractorHi,
    List<String>? eliminationLogicHi,
    String? upscTrapExplanationHi,
    List<FomoPulseStatementAnalysisItem>? statementAnalysisHi,
    String? finalExplanationHi,
  }) {
    return FomoPulseQuestion(
      displayText: displayText ?? this.displayText,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctOption: correctOption ?? this.correctOption,
      questionType: questionType ?? this.questionType,
      strongDistractor: strongDistractor ?? this.strongDistractor,
      eliminationLogic: eliminationLogic ?? this.eliminationLogic,
      upscTrapExplanation: upscTrapExplanation ?? this.upscTrapExplanation,
      statementAnalysis: statementAnalysis ?? this.statementAnalysis,
      finalExplanation: finalExplanation ?? this.finalExplanation,
      gsSubject: gsSubject ?? this.gsSubject,
      topic: topic ?? this.topic,
      newsTrigger: newsTrigger ?? this.newsTrigger,
      displayTextHi: displayTextHi ?? this.displayTextHi,
      optionAHi: optionAHi ?? this.optionAHi,
      optionBHi: optionBHi ?? this.optionBHi,
      optionCHi: optionCHi ?? this.optionCHi,
      optionDHi: optionDHi ?? this.optionDHi,
      strongDistractorHi: strongDistractorHi ?? this.strongDistractorHi,
      eliminationLogicHi: eliminationLogicHi ?? this.eliminationLogicHi,
      upscTrapExplanationHi:
          upscTrapExplanationHi ?? this.upscTrapExplanationHi,
      statementAnalysisHi: statementAnalysisHi ?? this.statementAnalysisHi,
      finalExplanationHi: finalExplanationHi ?? this.finalExplanationHi,
    );
  }

  factory FomoPulseQuestion.fromMap(Map<String, dynamic>? raw) {
    final q = raw ?? {};
    final en = q['en'] is Map
        ? Map<String, dynamic>.from(q['en'] as Map)
        : <String, dynamic>{};
    final shared = q['shared'] is Map
        ? Map<String, dynamic>.from(q['shared'] as Map)
        : <String, dynamic>{};
    final meta = q['meta'] is Map
        ? Map<String, dynamic>.from(q['meta'] as Map)
        : <String, dynamic>{};
    final hi = q['hi'] is Map
        ? Map<String, dynamic>.from(q['hi'] as Map)
        : <String, dynamic>{};
    return FomoPulseQuestion(
      displayText: (en['display_text'] ?? '').toString(),
      optionA: (en['option_a'] ?? '').toString(),
      optionB: (en['option_b'] ?? '').toString(),
      optionC: (en['option_c'] ?? '').toString(),
      optionD: (en['option_d'] ?? '').toString(),
      correctOption: (shared['correct_option'] ?? 'a').toString(),
      questionType: (shared['question_type'] ?? 'direct').toString(),
      strongDistractor: (en['strong_distractor'] ?? '').toString(),
      eliminationLogic: _stringList(en['elimination_logic']),
      upscTrapExplanation: (en['upsc_trap_explanation'] ?? '').toString(),
      statementAnalysis: _analysisList(en['statement_analysis']),
      finalExplanation: (en['final_explanation'] ?? '').toString(),
      gsSubject: (meta['gs_subject'] ?? '').toString(),
      topic: (meta['topic'] ?? '').toString(),
      newsTrigger: (meta['news_trigger'] ?? '').toString(),
      displayTextHi: (hi['display_text'] ?? '').toString(),
      optionAHi: (hi['option_a'] ?? '').toString(),
      optionBHi: (hi['option_b'] ?? '').toString(),
      optionCHi: (hi['option_c'] ?? '').toString(),
      optionDHi: (hi['option_d'] ?? '').toString(),
      strongDistractorHi: (hi['strong_distractor'] ?? '').toString(),
      eliminationLogicHi: _stringList(hi['elimination_logic']),
      upscTrapExplanationHi: (hi['upsc_trap_explanation'] ?? '').toString(),
      statementAnalysisHi: _analysisList(hi['statement_analysis']),
      finalExplanationHi: (hi['final_explanation'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toServerMap() {
    return {
      'en': {
        'display_text': displayText,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'strong_distractor': strongDistractor,
        'elimination_logic': eliminationLogic,
        'upsc_trap_explanation': upscTrapExplanation,
        'statement_analysis': [for (final s in statementAnalysis) s.toMap()],
        'final_explanation': finalExplanation,
      },
      'shared': {
        'correct_option': correctOption.toLowerCase().trim().isEmpty
            ? 'a'
            : correctOption.toLowerCase().trim().substring(0, 1),
        'question_type': questionType.trim().isEmpty ? 'direct' : questionType,
      },
      'meta': {
        'gs_subject': gsSubject,
        'topic': topic,
        'news_trigger': newsTrigger,
      },
      if (hasHindi)
        'hi': {
          'display_text': displayTextHi,
          'option_a': optionAHi,
          'option_b': optionBHi,
          'option_c': optionCHi,
          'option_d': optionDHi,
          'strong_distractor': strongDistractorHi,
          'elimination_logic': eliminationLogicHi,
          'upsc_trap_explanation': upscTrapExplanationHi,
          'statement_analysis': [
            for (final s in statementAnalysisHi) s.toMap(),
          ],
          'final_explanation': finalExplanationHi,
        },
    };
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final v in raw)
        if (v.toString().trim().isNotEmpty) v.toString().trim(),
    ];
  }

  static List<FomoPulseStatementAnalysisItem> _analysisList(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          FomoPulseStatementAnalysisItem.fromMap(
            Map<String, dynamic>.from(item),
          ),
    ];
  }

  String optionText(String letter) {
    switch (letter.toLowerCase()) {
      case 'a':
        return optionA;
      case 'b':
        return optionB;
      case 'c':
        return optionC;
      case 'd':
        return optionD;
      default:
        return '';
    }
  }
}

class FomoPulseStatementAnalysisItem {
  const FomoPulseStatementAnalysisItem({
    required this.statement,
    required this.isCorrect,
    required this.reason,
  });

  final String statement;
  final bool isCorrect;
  final String reason;

  factory FomoPulseStatementAnalysisItem.fromMap(Map<String, dynamic> map) {
    final verdict = map['is_correct'] ?? map['correct'] ?? map['verdict'];
    final normalized =
        verdict == true ||
        verdict.toString().trim().toLowerCase() == 'true' ||
        verdict.toString().trim().toLowerCase() == 'correct';
    return FomoPulseStatementAnalysisItem(
      statement: (map['statement'] ?? map['label'] ?? '').toString(),
      isCorrect: normalized,
      reason: (map['reason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'statement': statement,
    'is_correct': isCorrect,
    'reason': reason,
  };
}

class FomoPulseDraft {
  const FomoPulseDraft({
    this.sendRecommended = true,
    required this.notificationTitle,
    required this.notificationBody,
    required this.newsSummary,
    required this.sourceUrl,
    required this.question,
    this.harvestDraftDate,
    this.harvestDraftId,
    this.imageUrl = '',
    this.imageSource = '',
    this.upscPoints = const [],
    this.headline = '',
    this.headlineHi = '',
    this.newsSummaryHi = '',
    this.upscPointsHi = const [],
  });

  final bool sendRecommended;
  final String notificationTitle;
  final String notificationBody;
  final String newsSummary;
  final String sourceUrl;
  final FomoPulseQuestion question;
  final String? harvestDraftDate;
  final String? harvestDraftId;
  final String imageUrl;
  final String imageSource;
  final List<String> upscPoints;
  final String headline;
  final String headlineHi;
  final String newsSummaryHi;
  final List<String> upscPointsHi;

  FomoPulseDraft copyWith({
    bool? sendRecommended,
    String? notificationTitle,
    String? notificationBody,
    String? newsSummary,
    FomoPulseQuestion? question,
    String? imageUrl,
    String? imageSource,
    List<String>? upscPoints,
    String? headline,
    String? headlineHi,
    String? newsSummaryHi,
    List<String>? upscPointsHi,
  }) {
    return FomoPulseDraft(
      sendRecommended: sendRecommended ?? this.sendRecommended,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      notificationBody: notificationBody ?? this.notificationBody,
      newsSummary: newsSummary ?? this.newsSummary,
      sourceUrl: sourceUrl,
      question: question ?? this.question,
      harvestDraftDate: harvestDraftDate,
      harvestDraftId: harvestDraftId,
      imageUrl: imageUrl ?? this.imageUrl,
      imageSource: imageSource ?? this.imageSource,
      upscPoints: upscPoints ?? this.upscPoints,
      headline: headline ?? this.headline,
      headlineHi: headlineHi ?? this.headlineHi,
      newsSummaryHi: newsSummaryHi ?? this.newsSummaryHi,
      upscPointsHi: upscPointsHi ?? this.upscPointsHi,
    );
  }

  factory FomoPulseDraft.fromServerMap(Map<String, dynamic> map) {
    final harvest = map['harvest'] is Map
        ? Map<String, dynamic>.from(map['harvest'] as Map)
        : null;
    final points = map['upsc_points'];
    final pointsHi = map['upsc_points_hi'];
    return FomoPulseDraft(
      sendRecommended: map['send'] != false,
      notificationTitle: (map['notification_title'] ?? '').toString(),
      notificationBody: (map['notification_body'] ?? '').toString(),
      headline: (map['headline'] ?? '').toString(),
      headlineHi: (map['headline_hi'] ?? '').toString(),
      newsSummary: (map['news_summary'] ?? '').toString(),
      newsSummaryHi: (map['news_summary_hi'] ?? '').toString(),
      sourceUrl: (map['source_url'] ?? '').toString(),
      question: FomoPulseQuestion.fromMap(
        map['question'] is Map
            ? Map<String, dynamic>.from(map['question'] as Map)
            : null,
      ),
      harvestDraftDate: harvest?['draft_date']?.toString(),
      harvestDraftId: harvest?['draft_id']?.toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      imageSource: (map['image_source'] ?? '').toString(),
      upscPoints: points is List
          ? [
              for (final p in points)
                if (p.toString().trim().isNotEmpty) p.toString().trim(),
            ]
          : const [],
      upscPointsHi: pointsHi is List
          ? [
              for (final p in pointsHi)
                if (p.toString().trim().isNotEmpty) p.toString().trim(),
            ]
          : const [],
    );
  }
}

class FomoPulseAttemptState {
  const FomoPulseAttemptState({
    required this.attempted,
    required this.isCorrect,
    this.selectedOption,
    this.timeSpentSecs,
  });

  final bool attempted;
  final bool isCorrect;
  final String? selectedOption;
  final int? timeSpentSecs;

  Map<String, dynamic> toCompactMap() => {
    'c': isCorrect,
    'o': selectedOption,
    't': timeSpentSecs,
  };

  factory FomoPulseAttemptState.fromCompactMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const FomoPulseAttemptState(attempted: false, isCorrect: false);
    }
    return FomoPulseAttemptState(
      attempted: true,
      isCorrect: map['c'] == true,
      selectedOption: map['o']?.toString(),
      timeSpentSecs: (map['t'] as num?)?.toInt(),
    );
  }
}

class FomoPulseCommunityStats {
  const FomoPulseCommunityStats({
    required this.attemptCount,
    required this.correctCount,
  });

  final int attemptCount;
  final int correctCount;

  int get wrongCount => (attemptCount - correctCount).clamp(0, attemptCount);

  int get correctPct =>
      attemptCount == 0 ? 0 : ((correctCount / attemptCount) * 100).round();

  int get fellPct => (100 - correctPct).clamp(0, 100);

  String get breakdownLine {
    if (attemptCount <= 0) return appL10n.fpNoAttempts;
    return appL10n.fpBreakdown(attemptCount, correctCount, wrongCount);
  }

  String get trapLine {
    if (attemptCount <= 0) return appL10n.fpNoAttempts;
    return appL10n.fpTrap(attemptCount, fellPct);
  }

  String get challengeLine =>
      attemptCount <= 0 ? appL10n.fpBeFirst : appL10n.fpCanYou(trapLine);

  factory FomoPulseCommunityStats.fromMap(Map<String, dynamic> map) {
    final attempts = (map['attempt_count'] as num?)?.toInt() ?? 0;
    final correctFromCount = (map['correct_count'] as num?)?.toInt();
    if (correctFromCount != null) {
      return FomoPulseCommunityStats(
        attemptCount: attempts,
        correctCount: correctFromCount.clamp(0, attempts < 0 ? 0 : attempts),
      );
    }
    final pct = (map['correct_pct'] as num?)?.toInt() ?? 0;
    final correct = attempts == 0
        ? 0
        : ((pct.clamp(0, 100) / 100) * attempts).round();
    return FomoPulseCommunityStats(
      attemptCount: attempts,
      correctCount: correct,
    );
  }
}

class FomoPulse {
  const FomoPulse({
    required this.pulseId,
    required this.title,
    required this.body,
    required this.newsSummary,
    required this.sourceUrl,
    required this.question,
    required this.sentAt,
    required this.expiresAt,
    required this.attemptCount,
    required this.correctCount,
    this.imageUrl = '',
    this.imageSource = '',
    this.upscPoints = const [],
    this.headline = '',
    this.headlineHi = '',
    this.newsSummaryHi = '',
    this.upscPointsHi = const [],
  });

  final String pulseId;
  final String title;
  final String body;
  final String newsSummary;
  final String sourceUrl;
  final FomoPulseQuestion question;
  final DateTime? sentAt;
  final DateTime? expiresAt;
  final int attemptCount;
  final int correctCount;
  final String imageUrl;
  final String imageSource;
  final List<String> upscPoints;
  final String headline;
  final String headlineHi;
  final String newsSummaryHi;
  final List<String> upscPointsHi;

  FomoPulse copyWith({
    String? title,
    String? body,
    String? newsSummary,
    String? sourceUrl,
    FomoPulseQuestion? question,
    DateTime? sentAt,
    DateTime? expiresAt,
    int? attemptCount,
    int? correctCount,
    String? imageUrl,
    String? imageSource,
    List<String>? upscPoints,
    String? headline,
    String? headlineHi,
    String? newsSummaryHi,
    List<String>? upscPointsHi,
  }) {
    return FomoPulse(
      pulseId: pulseId,
      title: title ?? this.title,
      body: body ?? this.body,
      newsSummary: newsSummary ?? this.newsSummary,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      question: question ?? this.question,
      sentAt: sentAt ?? this.sentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      attemptCount: attemptCount ?? this.attemptCount,
      correctCount: correctCount ?? this.correctCount,
      imageUrl: imageUrl ?? this.imageUrl,
      imageSource: imageSource ?? this.imageSource,
      upscPoints: upscPoints ?? this.upscPoints,
      headline: headline ?? this.headline,
      headlineHi: headlineHi ?? this.headlineHi,
      newsSummaryHi: newsSummaryHi ?? this.newsSummaryHi,
      upscPointsHi: upscPointsHi ?? this.upscPointsHi,
    );
  }

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  bool get hasHindiCopy =>
      headlineHi.trim().isNotEmpty || newsSummaryHi.trim().isNotEmpty;

  String _copy({
    required bool preferHindi,
    required String hi,
    required String en,
  }) {
    if (preferHindi && hi.trim().isNotEmpty) return hi.trim();
    return en.trim();
  }

  /// List + in-app title: `headline` / `headline_hi`, else the push title.
  String displayHeadline({required bool preferHindi}) {
    final fromHeadline = _copy(
      preferHindi: preferHindi,
      hi: headlineHi,
      en: headline,
    );
    if (fromHeadline.isNotEmpty) return fromHeadline;
    return title;
  }

  String listTitle({required bool preferHindi}) =>
      displayHeadline(preferHindi: preferHindi);

  static final _leadingBriefingLabel = RegExp(
    r'^\*{0,2}\s*(what happened|क्या हुआ)\s*:?\s*\*{0,2}\s*',
    caseSensitive: false,
  );

  static String _briefingWithoutLabel(String raw) =>
      raw.replaceFirst(_leadingBriefingLabel, '').trim();

  /// List + detail briefing: `news_summary` / `news_summary_hi`.
  String listBody({required bool preferHindi}) => _briefingWithoutLabel(
    _copy(preferHindi: preferHindi, hi: newsSummaryHi, en: newsSummary),
  );

  int get wrongCount => (attemptCount - correctCount).clamp(0, attemptCount);

  FomoPulseCommunityStats get communityCounts => FomoPulseCommunityStats(
    attemptCount: attemptCount,
    correctCount: correctCount,
  );

  /// Null when [attemptCount] is below [minAttempts].
  /// Pass 1 to show raw counts to everyone; [FomoPulseConstants.minStatsAttempts]
  /// still gates share FOMO copy.
  FomoPulseCommunityStats? communityStats({int minAttempts = 1}) {
    if (attemptCount < minAttempts) return null;
    return communityCounts;
  }

  factory FomoPulse.fromFirestore(String id, Map<String, dynamic> data) {
    return FomoPulse(
      pulseId: id,
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      headline: (data['headline'] ?? '').toString(),
      headlineHi: (data['headline_hi'] ?? '').toString(),
      newsSummary: (data['news_summary'] ?? '').toString(),
      sourceUrl: (data['source_url'] ?? '').toString(),
      question: FomoPulseQuestion.fromMap(
        data['question'] is Map
            ? Map<String, dynamic>.from(data['question'] as Map)
            : null,
      ),
      sentAt: _ts(data['sent_at']),
      expiresAt: _ts(data['expires_at']),
      attemptCount: (data['attempt_count'] as num?)?.toInt() ?? 0,
      correctCount: (data['correct_count'] as num?)?.toInt() ?? 0,
      imageUrl: (data['image_url'] ?? '').toString(),
      imageSource: (data['image_source'] ?? '').toString(),
      upscPoints: _stringList(data['upsc_points']),
      newsSummaryHi: (data['news_summary_hi'] ?? '').toString(),
      upscPointsHi: _stringList(data['upsc_points_hi']),
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'pulse_id': pulseId,
      'title': title,
      'body': body,
      'headline': headline,
      'headline_hi': headlineHi,
      'news_summary': newsSummary,
      'source_url': sourceUrl,
      'question': question.toServerMap(),
      'sent_at_ms': sentAt?.millisecondsSinceEpoch,
      'expires_at_ms': expiresAt?.millisecondsSinceEpoch,
      'attempt_count': attemptCount,
      'correct_count': correctCount,
      'image_url': imageUrl,
      'image_source': imageSource,
      'upsc_points': upscPoints,
      'news_summary_hi': newsSummaryHi,
      'upsc_points_hi': upscPointsHi,
    };
  }

  factory FomoPulse.fromCacheMap(Map<String, dynamic> data) {
    return FomoPulse(
      pulseId: (data['pulse_id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      headline: (data['headline'] ?? '').toString(),
      headlineHi: (data['headline_hi'] ?? '').toString(),
      newsSummary: (data['news_summary'] ?? '').toString(),
      sourceUrl: (data['source_url'] ?? '').toString(),
      question: FomoPulseQuestion.fromMap(
        data['question'] is Map
            ? Map<String, dynamic>.from(data['question'] as Map)
            : null,
      ),
      sentAt: _ms(data['sent_at_ms']),
      expiresAt: _ms(data['expires_at_ms']),
      attemptCount: (data['attempt_count'] as num?)?.toInt() ?? 0,
      correctCount: (data['correct_count'] as num?)?.toInt() ?? 0,
      imageUrl: (data['image_url'] ?? '').toString(),
      imageSource: (data['image_source'] ?? '').toString(),
      upscPoints: _stringList(data['upsc_points']),
      newsSummaryHi: (data['news_summary_hi'] ?? '').toString(),
      upscPointsHi: _stringList(data['upsc_points_hi']),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final p in raw)
        if (p.toString().trim().isNotEmpty) p.toString().trim(),
    ];
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static DateTime? _ms(dynamic v) {
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return null;
  }
}

class FomoPulseSubmitResult {
  const FomoPulseSubmitResult({
    required this.isCorrect,
    required this.selectedOption,
    required this.correctOption,
    required this.alreadyAttempted,
    required this.timeSpentSecs,
    this.attemptCount = 0,
    this.correctCount = 0,
    this.stats,
  });

  final bool isCorrect;
  final String selectedOption;
  final String correctOption;
  final bool alreadyAttempted;
  final int timeSpentSecs;
  final int attemptCount;
  final int correctCount;
  final FomoPulseCommunityStats? stats;

  factory FomoPulseSubmitResult.fromServerMap(Map<String, dynamic> map) {
    final statsRaw = map['stats'];
    FomoPulseCommunityStats? stats;
    if (statsRaw is Map) {
      stats = FomoPulseCommunityStats.fromMap(
        Map<String, dynamic>.from(statsRaw),
      );
    }
    return FomoPulseSubmitResult(
      isCorrect: map['is_correct'] == true,
      selectedOption: (map['selected_option'] ?? '').toString(),
      correctOption: (map['correct_option'] ?? '').toString(),
      alreadyAttempted: map['already_attempted'] == true,
      timeSpentSecs: (map['time_spent_secs'] as num?)?.toInt() ?? 0,
      attemptCount: (map['attempt_count'] as num?)?.toInt() ?? 0,
      correctCount: (map['correct_count'] as num?)?.toInt() ?? 0,
      stats: stats,
    );
  }
}
