import 'package:flutter/material.dart';

import 'subject_insights.dart';

/// Per-subject aggregate row used in the cross-subject Progress overview.
class SubjectOverviewRow {
  const SubjectOverviewRow({
    required this.subject,
    required this.displayName,
    required this.icon,
    required this.wrongCountLast30Days,
    required this.totalAttempted,
    required this.totalCorrect,
  });

  final String subject;
  final String displayName;
  final IconData icon;

  /// Wrong answers in the last 30 days.
  final int wrongCountLast30Days;

  /// Total answered questions (all-time, correct + wrong only).
  final int totalAttempted;

  /// Total correct answers (all-time).
  final int totalCorrect;

  bool get hasAttempts => totalAttempted > 0;

  /// All-time accuracy as a percentage (0–100), or null if never attempted.
  double? get accuracyPercent =>
      totalAttempted > 0 ? (totalCorrect / totalAttempted) * 100 : null;

  RiskTier get riskTier => riskTierForWrongCount(wrongCountLast30Days);
}
