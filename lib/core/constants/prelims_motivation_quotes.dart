/// Motivational lines for Prelims countdown surfaces (card + status-bar notif).
///
/// Picked deterministically via [quoteForDate] so the same quote holds for a
/// calendar day, then cycles to the next.
abstract final class PrelimsMotivationQuotes {
  PrelimsMotivationQuotes._();

  static const List<String> lines = [
    // Time & urgency
    'The trouble is, you think you have time. — Buddha',
    'Don\'t watch the clock; do what it does. Keep going. — Sam Levenson',
    'One day or day one. You decide.',
    'The secret of getting ahead is getting started. — Mark Twain',

    // Consistency over intensity
    'Success is the sum of small efforts, repeated day in and day out. — Robert Collier',
    'You don\'t have to be extreme, just consistent.',
    'Small progress is still progress.',
    'Quality is not an act, it is a habit. — Aristotle',
    'Discipline is choosing between what you want now and what you want most.',

    // Prelims / exam mindset
    'Revision beats re-reading. Close the book and recall.',
    'Wrong answers today are marks saved on D-day.',
    'Eliminate first. Guess last. Trust the process.',
    'One calm mock is worth a week of anxious scrolling.',
    'Prelims rewards clarity under pressure — practice that.',
    'Current affairs compound. A little every day beats a binge.',
    'Your notes are only useful if you revisit them.',
    'Accuracy over speed — then speed will follow.',

    // Resilience
    'Fall seven times, stand up eight.',
    'It always seems impossible until it\'s done. — Nelson Mandela',
    'Courage doesn\'t always roar. Sometimes it says: try again tomorrow.',
    'Difficult roads often lead to beautiful destinations.',
    'Energy and persistence conquer all things. — Benjamin Franklin',

    // Focus
    'Focus on being better than yesterday.',
    'Great things never come from comfort zones.',
    'Start where you are. Use what you have. Do what you can. — Arthur Ashe',
    'Push yourself, because no one else is going to do it for you.',
    'Believe you can and you\'re halfway there. — Theodore Roosevelt',
    'The expert in anything was once a beginner. — Helen Hayes',
  ];

  /// Stable quote for the calendar day (local device).
  static String quoteForDate(DateTime date) {
    if (lines.isEmpty) return '';
    final start = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(start).inDays + 1;
    return lines[dayOfYear % lines.length];
  }
}
