/// Daily motivational lines for the session summary countdown card.
/// Picked deterministically via [quoteForDate] so the same quote shows all day.
abstract final class PrelimsMotivationQuotes {
  PrelimsMotivationQuotes._();

  static const List<String> lines = [
    'Success is the sum of small efforts, repeated day in and day out. — Robert Collier',
    'The expert in anything was once a beginner. — Helen Hayes',
    'Don\'t watch the clock; do what it does. Keep going. — Sam Levenson',
    'Believe you can and you\'re halfway there. — Theodore Roosevelt',
    'The only way to do great work is to love what you do. — Steve Jobs',
    'Every accomplishment starts with the decision to try.',
    'Your limitation—it\'s only your imagination.',
    'Great things never come from comfort zones.',
    'Discipline is choosing between what you want now and what you want most.',
    'Small progress is still progress.',
    'Energy and persistence conquer all things. — Benjamin Franklin',
    'Start where you are. Use what you have. Do what you can. — Arthur Ashe',
    'The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt',
    'It always seems impossible until it\'s done. — Nelson Mandela',
    'Quality is not an act, it is a habit. — Aristotle',
    'You don\'t have to be extreme, just consistent.',
    'Focus on being better than yesterday.',
    'Courage doesn\'t always roar. Sometimes it is the quiet voice at the end of the day saying I will try again tomorrow.',
    'The secret of getting ahead is getting started. — Mark Twain',
    'Push yourself, because no one else is going to do it for you.',
    'Difficult roads often lead to beautiful destinations.',
    'Fall seven times, stand up eight.',
    'One day or day one. You decide.',
  ];

  /// Stable quote for the calendar day (local device).
  static String quoteForDate(DateTime date) {
    if (lines.isEmpty) return '';
    final start = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(start).inDays + 1;
    return lines[dayOfYear % lines.length];
  }
}
