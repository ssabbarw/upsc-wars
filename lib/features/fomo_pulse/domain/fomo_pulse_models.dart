import 'package:cloud_firestore/cloud_firestore.dart';

typedef FomoPulseHistoryData = ({
  List<FomoPulse> pulses,
  Map<String, FomoPulseAttemptState> attempts,
});

class FomoPulseHarvestCandidate {
  const FomoPulseHarvestCandidate({
    required this.draftId,
    required this.title,
    required this.preview,
    required this.gsSubject,
    required this.sourceUrl,
    required this.newsImportance,
    required this.newsSummary,
  });

  final String draftId;
  final String title;
  final String preview;
  final String gsSubject;
  final String sourceUrl;
  final int newsImportance;
  final String newsSummary;

  factory FomoPulseHarvestCandidate.fromMap(Map<String, dynamic> map) {
    return FomoPulseHarvestCandidate(
      draftId: (map['draft_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      preview: (map['preview'] ?? '').toString(),
      gsSubject: (map['gs_subject'] ?? '').toString(),
      sourceUrl: (map['source_url'] ?? '').toString(),
      newsImportance: (map['news_importance'] as num?)?.toInt() ?? 3,
      newsSummary: (map['news_summary'] ?? '').toString(),
    );
  }
}

class FomoPulseQuestion {
  const FomoPulseQuestion({
    required this.displayText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    required this.finalExplanation,
    required this.gsSubject,
    required this.topic,
    required this.newsTrigger,
  });

  final String displayText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String finalExplanation;
  final String gsSubject;
  final String topic;
  final String newsTrigger;

  FomoPulseQuestion copyWith({
    String? displayText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
    String? finalExplanation,
    String? gsSubject,
    String? topic,
    String? newsTrigger,
  }) {
    return FomoPulseQuestion(
      displayText: displayText ?? this.displayText,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctOption: correctOption ?? this.correctOption,
      finalExplanation: finalExplanation ?? this.finalExplanation,
      gsSubject: gsSubject ?? this.gsSubject,
      topic: topic ?? this.topic,
      newsTrigger: newsTrigger ?? this.newsTrigger,
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
    return FomoPulseQuestion(
      displayText: (en['display_text'] ?? '').toString(),
      optionA: (en['option_a'] ?? '').toString(),
      optionB: (en['option_b'] ?? '').toString(),
      optionC: (en['option_c'] ?? '').toString(),
      optionD: (en['option_d'] ?? '').toString(),
      correctOption: (shared['correct_option'] ?? 'a').toString(),
      finalExplanation: (en['final_explanation'] ?? '').toString(),
      gsSubject: (meta['gs_subject'] ?? '').toString(),
      topic: (meta['topic'] ?? '').toString(),
      newsTrigger: (meta['news_trigger'] ?? '').toString(),
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
        'final_explanation': finalExplanation,
      },
      'shared': {
        'correct_option': correctOption.toLowerCase().trim().isEmpty
            ? 'a'
            : correctOption.toLowerCase().trim().substring(0, 1),
        'question_type': 'direct',
      },
      'meta': {
        'gs_subject': gsSubject,
        'topic': topic,
        'news_trigger': newsTrigger,
      },
    };
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

class FomoPulseDraft {
  const FomoPulseDraft({
    required this.notificationTitle,
    required this.notificationBody,
    required this.newsSummary,
    required this.sourceUrl,
    required this.question,
    this.harvestDraftDate,
    this.harvestDraftId,
  });

  final String notificationTitle;
  final String notificationBody;
  final String newsSummary;
  final String sourceUrl;
  final FomoPulseQuestion question;
  final String? harvestDraftDate;
  final String? harvestDraftId;

  factory FomoPulseDraft.fromServerMap(Map<String, dynamic> map) {
    final harvest = map['harvest'] is Map
        ? Map<String, dynamic>.from(map['harvest'] as Map)
        : null;
    return FomoPulseDraft(
      notificationTitle: (map['notification_title'] ?? '').toString(),
      notificationBody: (map['notification_body'] ?? '').toString(),
      newsSummary: (map['news_summary'] ?? '').toString(),
      sourceUrl: (map['source_url'] ?? '').toString(),
      question: FomoPulseQuestion.fromMap(
        map['question'] is Map
            ? Map<String, dynamic>.from(map['question'] as Map)
            : null,
      ),
      harvestDraftDate: harvest?['draft_date']?.toString(),
      harvestDraftId: harvest?['draft_id']?.toString(),
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
    required this.correctPct,
  });

  final int attemptCount;
  final int correctPct;

  String get line => '$correctPct% got it right · $attemptCount attempted';
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
    );
  }

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  FomoPulseCommunityStats? communityStats({int minAttempts = 20}) {
    if (attemptCount < minAttempts) return null;
    final pct = attemptCount == 0
        ? 0
        : ((correctCount / attemptCount) * 100).round();
    return FomoPulseCommunityStats(
      attemptCount: attemptCount,
      correctPct: pct,
    );
  }

  factory FomoPulse.fromFirestore(String id, Map<String, dynamic> data) {
    return FomoPulse(
      pulseId: id,
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
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
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'pulse_id': pulseId,
      'title': title,
      'body': body,
      'news_summary': newsSummary,
      'source_url': sourceUrl,
      'question': question.toServerMap(),
      'sent_at_ms': sentAt?.millisecondsSinceEpoch,
      'expires_at_ms': expiresAt?.millisecondsSinceEpoch,
      'attempt_count': attemptCount,
      'correct_count': correctCount,
    };
  }

  factory FomoPulse.fromCacheMap(Map<String, dynamic> data) {
    return FomoPulse(
      pulseId: (data['pulse_id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
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
    );
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
      final m = Map<String, dynamic>.from(statsRaw);
      stats = FomoPulseCommunityStats(
        attemptCount: (m['attempt_count'] as num?)?.toInt() ?? 0,
        correctPct: (m['correct_pct'] as num?)?.toInt() ?? 0,
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
