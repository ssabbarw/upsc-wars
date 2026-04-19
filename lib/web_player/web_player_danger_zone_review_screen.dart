import 'package:flutter/material.dart';

import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/history/screens/session_review_screen.dart';

/// Same idea as in-app [DangerZoneReviewScreen]: pager over wrong + confident
/// attempts only.
class WebPlayerDangerZoneReviewScreen extends StatefulWidget {
  const WebPlayerDangerZoneReviewScreen({super.key, required this.questions});

  final List<TestQuestion> questions;

  @override
  State<WebPlayerDangerZoneReviewScreen> createState() =>
      _WebPlayerDangerZoneReviewScreenState();
}

class _WebPlayerDangerZoneReviewScreenState
    extends State<WebPlayerDangerZoneReviewScreen> {
  int _index = 0;
  String _uiLang = 'en';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.questions.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.chevron_left),
                ),
                const Spacer(),
                Text(
                  'No Danger Zone items',
                  style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Wrong answers without a confidence pick, or where you marked '
                  '"Guessing", do not appear here.',
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final q = widget.questions[_index];
    final total = widget.questions.length;
    final current = _index + 1;
    final confLabel = q.confidence == null
        ? 'Confident'
        : AnswerConfidence.displayLabel(q.confidence!);

    return Scaffold(
      body: SafeArea(
        child: ReviewBody(
          title: 'Danger Zone Review',
          showRevisionBadge: false,
          progressRight: '${q.subject} · ${q.topic}',
          question: q,
          current: current,
          total: total,
          isBookmarked: false,
          isQueued: false,
          confidenceSessionId: 'web_player_danger_zone',
          onToggleBookmark: () async {},
          onPrev: () {
            if (_index > 0) setState(() => _index--);
          },
          onNext: () {
            if (current == total) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            } else {
              setState(() => _index++);
            }
          },
          onAddToRevision: null,
          isRevisionMode: true,
          uiLanguage: _uiLang,
          onLanguageChanged: (lang) => setState(() => _uiLang = lang),
          confidenceBanner: 'You were $confLabel',
        ),
      ),
    );
  }
}
