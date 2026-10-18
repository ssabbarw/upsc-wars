import 'package:flutter/material.dart';

/// One bilingual term ↔ answer pair.
class MemoryPair {
  const MemoryPair({
    required this.termEn,
    required this.termHi,
    required this.answerEn,
    required this.answerHi,
  });

  final String termEn;
  final String termHi;
  final String answerEn;
  final String answerHi;

  String termForLang(String lang) => lang == 'hi' ? termHi : termEn;

  String answerForLang(String lang) => lang == 'hi' ? answerHi : answerEn;
}

/// Static catalog entry (hardcoded for v1).
class MemoryPairSetDefinition {
  const MemoryPairSetDefinition({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.displaySubjectEn,
    required this.displaySubjectHi,
    required this.unlockSubjectSlug,
    required this.unlockQuestionsRequired,
    required this.difficulty,
    required this.icon,
    required this.accentColor,
    required this.pairs,
  });

  final String id;
  final String nameEn;
  final String nameHi;
  final String displaySubjectEn;
  final String displaySubjectHi;

  /// [SubjectConstants] slug used for unlock progress.
  final String unlockSubjectSlug;
  final int unlockQuestionsRequired;
  final MemoryPairDifficulty difficulty;
  final IconData icon;
  final Color accentColor;
  final List<MemoryPair> pairs;

  String nameForLang(String lang) => lang == 'hi' ? nameHi : nameEn;

  String subjectLabelForLang(String lang) =>
      lang == 'hi' ? displaySubjectHi : displaySubjectEn;

  bool get hasPlayablePairs => pairs.isNotEmpty;
}

enum MemoryPairDifficulty { easy, medium, hard }

extension MemoryPairDifficultyX on MemoryPairDifficulty {
  String get id => name;

  String get label => switch (this) {
    MemoryPairDifficulty.easy => 'Easy',
    MemoryPairDifficulty.medium => 'Medium',
    MemoryPairDifficulty.hard => 'Hard',
  };

  int get pairCount => switch (this) {
    MemoryPairDifficulty.easy => 6,
    MemoryPairDifficulty.medium => 8,
    MemoryPairDifficulty.hard => 10,
  };

  Color chipColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      MemoryPairDifficulty.easy =>
        isDark ? const Color(0xFF3D9E6A) : const Color(0xFF1D9E75),
      MemoryPairDifficulty.medium =>
        isDark ? const Color(0xFFC98A2E) : const Color(0xFFB45309),
      MemoryPairDifficulty.hard =>
        isDark ? const Color(0xFFD45C5C) : const Color(0xFFDC2626),
    };
  }

  Color chipBackground(BuildContext context) =>
      chipColor(context).withValues(alpha: 0.12);
}

/// Outcome of one play session (single round).
class MemoryPairGameResult {
  const MemoryPairGameResult({
    required this.seconds,
    required this.errors,
    required this.pairsCount,
    required this.weakPairs,
  });

  final int seconds;
  final int errors;
  final int pairsCount;
  final List<MemoryPair> weakPairs;
}

/// Persisted stats for one set + difficulty.
class MemoryPairSetStats {
  const MemoryPairSetStats({
    required this.setId,
    required this.difficulty,
    this.bestSeconds,
    this.lastPlayedAt,
    this.lastErrors = 0,
  });

  final String setId;
  final MemoryPairDifficulty difficulty;
  final int? bestSeconds;
  final DateTime? lastPlayedAt;
  final int lastErrors;
}

/// Set row enriched with unlock + stats for the list UI.
class MemoryPairSetListItem {
  const MemoryPairSetListItem({
    required this.definition,
    required this.isUnlocked,
    required this.unlockProgress,
    required this.unlockRequired,
    required this.bestSeconds,
    required this.lastPlayedAt,
  });

  final MemoryPairSetDefinition definition;
  final bool isUnlocked;
  final int unlockProgress;
  final int unlockRequired;
  final int? bestSeconds;
  final DateTime? lastPlayedAt;
}
