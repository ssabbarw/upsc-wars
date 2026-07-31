/// One statement in the onboarding fact-or-bluff demo (English only; the
/// demo has no language toggle, unlike the full game).
class OnboardingFactOrBluffStatement {
  const OnboardingFactOrBluffStatement({
    required this.statement,
    required this.isFact,
    required this.explanation,
  });

  final String statement;
  final bool isFact;
  final String explanation;
}

/// Three statements curated from the full Fact or Bluff pool for the
/// onboarding demo. Ordered for a deliberate arc: an easy win first, then a
/// widely believed bluff (the "confident mistake" moment the score-story page
/// set up), then a fact that most people hesitate on.
const List<OnboardingFactOrBluffStatement> kOnboardingFactOrBluffStatements = [
  OnboardingFactOrBluffStatement(
    statement: 'The Rigveda is the oldest of the four Vedas.',
    isFact: true,
    explanation:
        'Fact. The Rigveda is the earliest Veda, followed by the Sama, '
        'Yajur and Atharva Vedas.',
  ),
  OnboardingFactOrBluffStatement(
    statement: 'The iron pillar at Mehrauli was erected by Ashoka.',
    isFact: false,
    explanation:
        'Bluff. The pillar names a king "Chandra", widely identified as '
        'Gupta ruler Chandragupta II — not Ashoka.',
  ),
  OnboardingFactOrBluffStatement(
    statement:
        'The script of the Indus Valley Civilisation has never been '
        'deciphered.',
    isFact: true,
    explanation:
        'Fact. Despite thousands of recovered seals, the Indus script '
        'remains undeciphered.',
  ),
];
