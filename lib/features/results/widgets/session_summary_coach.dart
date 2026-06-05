import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_result.dart';
import 'session_summary_compact.dart';

/// Post-test session summary (compact layout for all sessions).
class SessionSummaryCoachContent extends ConsumerWidget {
  const SessionSummaryCoachContent({
    super.key,
    required this.sessionId,
    required this.result,
    required this.displaySubjectName,
    this.maxHeight = 600,
  });

  final String sessionId;
  final SessionResult result;
  final String displaySubjectName;
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SessionSummaryCompactView(
      sessionId: sessionId,
      result: result,
      displaySubjectName: displaySubjectName,
      maxHeight: maxHeight,
    );
  }
}
