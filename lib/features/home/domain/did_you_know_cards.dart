/// Static catalog for the post-activation Did You Know drip.
library;

import 'home_recommendation_snapshot.dart';

enum DidYouKnowAction {
  openWeakAreasHub,
  openRevisionQueue,
  openCommunityBattles,
  showExplanationsSheet,
}

class DidYouKnowCardDef {
  const DidYouKnowCardDef({
    required this.id,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.action,
  });

  final String id;
  final String title;
  final String body;
  final String ctaLabel;
  final DidYouKnowAction action;
}

const kDidYouKnowCards = <DidYouKnowCardDef>[
  DidYouKnowCardDef(
    id: 'confident_mistakes',
    title: 'Confident mistakes cost real marks',
    body:
        'UPSC Wars detects topics where you feel sure but still get questions wrong — the leaks other apps miss.',
    ctaLabel: 'See how it works',
    action: DidYouKnowAction.openWeakAreasHub,
  ),
  DidYouKnowCardDef(
    id: 'trap_explanations',
    title: 'Explanations go deeper than the answer',
    body:
        'Every question includes trap analysis, elimination logic, and statement breakdowns — not just A/B/C/D.',
    ctaLabel: 'See an example',
    action: DidYouKnowAction.showExplanationsSheet,
  ),
  DidYouKnowCardDef(
    id: 'revision_queue',
    title: 'Revision that prioritises real risk',
    body:
        'Wrong answers land in your revision queue so you revisit high-risk mistakes before they fade.',
    ctaLabel: 'View revision queue',
    action: DidYouKnowAction.openRevisionQueue,
  ),
  DidYouKnowCardDef(
    id: 'battles',
    title: 'Practice with other aspirants',
    body:
        'Challenge someone to a 1-on-1 MCQ battle and feel the prelims-time pressure.',
    ctaLabel: 'Try a battle',
    action: DidYouKnowAction.openCommunityBattles,
  ),
];

DidYouKnowCardDef? didYouKnowCardById(String id) {
  for (final c in kDidYouKnowCards) {
    if (c.id == id) return c;
  }
  return null;
}

bool isDidYouKnowCardEligible(
  DidYouKnowCardDef card,
  HomeRecommendationSnapshot snapshot,
) {
  switch (card.id) {
    case 'confident_mistakes':
      return snapshot.confidentMistakeCount > 0;
    case 'trap_explanations':
      return snapshot.completedSessionCount > 0 && snapshot.wrongAnswerCount > 0;
    case 'revision_queue':
      return snapshot.revisionQueueCount > kDidYouKnowRevisionQueueMinCount;
    case 'battles':
      return snapshot.completedSessionCount >=
          kDidYouKnowBattlesMinCompletedSessions;
    default:
      return false;
  }
}

DidYouKnowCardDef? nextDidYouKnowCard(
  Set<String> dismissedIds,
  HomeRecommendationSnapshot snapshot,
) {
  for (final c in kDidYouKnowCards) {
    if (dismissedIds.contains(c.id)) continue;
    if (!isDidYouKnowCardEligible(c, snapshot)) continue;
    return c;
  }
  return null;
}
