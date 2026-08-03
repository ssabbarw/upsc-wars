/// Demo MCQ + outcome copy for first-run onboarding Screen 3.
class OnboardingMcqOption {
  const OnboardingMcqOption({
    required this.letter,
    required this.text,
    required this.isCorrect,
  });

  final String letter;
  final String text;
  final bool isCorrect;
}

enum OnboardingMcqOutcome { correct, wrong, skipped }

/// How sure the user said they were before revealing the answer.
enum OnboardingMcqConfidence { confident, guessing }

class OnboardingMcqContent {
  const OnboardingMcqContent({
    required this.eyebrow,
    required this.prompt,
    required this.question,
    required this.options,
    required this.trapTitle,
    required this.trapBodyCorrect,
    required this.trapBodyWrong,
    required this.headlineCorrectConfident,
    required this.headlineCorrectGuess,
    required this.headlineWrongConfident,
    required this.headlineWrongGuess,
    required this.promiseCorrectConfident,
    required this.promiseCorrectGuess,
    required this.promiseWrongConfident,
    required this.promiseWrongGuess,
    required this.skippedHeadline,
    required this.eliminations,
    required this.promiseSkipped,
    required this.richerNote,
  });

  final String eyebrow;
  final String prompt;
  final String question;
  final List<OnboardingMcqOption> options;
  final String trapTitle;
  final String trapBodyCorrect;
  final String trapBodyWrong;
  final String headlineCorrectConfident;
  final String headlineCorrectGuess;
  final String headlineWrongConfident;
  final String headlineWrongGuess;
  final String promiseCorrectConfident;
  final String promiseCorrectGuess;
  final String promiseWrongConfident;
  final String promiseWrongGuess;
  final String skippedHeadline;
  final List<({bool keep, String text})> eliminations;
  final String promiseSkipped;
  final String richerNote;
}

const kOnboardingMcq = OnboardingMcqContent(
  eyebrow: 'Quick Check · Modern History',
  prompt: 'Try one. Mark your answer.',
  question: 'Who was the first Governor-General of India?',
  options: [
    OnboardingMcqOption(
      letter: 'a',
      text: 'Warren Hastings',
      isCorrect: false,
    ),
    OnboardingMcqOption(
      letter: 'b',
      text: 'Lord William Bentinck',
      isCorrect: true,
    ),
    OnboardingMcqOption(
      letter: 'c',
      text: 'Lord Mountbatten',
      isCorrect: false,
    ),
    OnboardingMcqOption(
      letter: 'd',
      text: 'Lord Canning',
      isCorrect: false,
    ),
  ],
  trapTitle: 'Trap: Entity-Swap',
  trapBodyCorrect:
      'Hastings → first GG of Bengal. Bentinck → first GG of India. '
      'Mountbatten → first GG of independent India. Canning → first Viceroy. '
      'Every option is a real “first.”',
  trapBodyWrong:
      'Hastings was first GG of Bengal (1773). Bentinck was first GG of '
      'India (1833). Each option here is the “first” of something real — '
      'UPSC changed one word.',
  headlineCorrectConfident: 'Confident and right — you own this topic.',
  headlineCorrectGuess: 'A guess — and it landed.',
  headlineWrongConfident: 'Confident and wrong — this is a weak zone.',
  headlineWrongGuess: 'You got this one wrong.',
  promiseCorrectConfident:
      'Viceroys & Governor-Generals looks like a strength. We confirm your '
      'strong zones so you stop over-revising what you already know.',
  promiseCorrectGuess:
      'You’re likely to make correct guesses from Viceroys & '
      'Governor-Generals. We spot topics where your instincts are right — '
      'so you take smarter chances in the exam.',
  promiseWrongConfident:
      'You should revise the chapter on Viceroys & Governor-Generals. '
      'Confident-wrong answers cost the most marks — we flag every one '
      'of them for revision.',
  promiseWrongGuess:
      'You should probably revise the chapter on Viceroys & '
      'Governor-Generals. We track these misses topic-by-topic so your '
      'revision targets itself.',
  skippedHeadline: 'No idea? Here’s how to eliminate without knowing.',
  eliminations: [
    (keep: false, text: '(a) Hastings — first GG of Bengal, not India.'),
    (keep: true, text: '(b) Bentinck — first GG of India, 1833.'),
    (
      keep: false,
      text: '(c) Mountbatten — first GG of independent India.',
    ),
    (keep: false, text: '(d) Canning — first Viceroy, not GG.'),
  ],
  promiseSkipped:
      'This is elimination logic. Every question has it — so you always '
      'know why, not just what.',
  richerNote:
      'Real questions have much richer explanations and statement analysis.',
);
