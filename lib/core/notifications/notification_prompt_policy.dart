/// Where the notification-permission sheet is being considered.
enum NotificationPromptSurface {
  dailyWar,
  dailyCa,
  community,
  generic,
}

/// Automatic = capped/cooldown strategy. Explicit = user tapped a notify CTA.
enum NotificationPromptKind { automatic, explicit }

/// Copy for the pre-permission sheet. Hero is contextual; [alsoLine] names
/// the other notification uses so one prompt covers the whole product.
class NotificationPromptCopy {
  const NotificationPromptCopy({
    required this.title,
    required this.body,
    required this.alsoLine,
    required this.cta,
    this.bullets = const [],
  });

  final String title;
  final String body;
  final String alsoLine;
  final String cta;
  final List<String> bullets;

  static const notNow = 'Not now';
  static const footer = 'You can change this anytime in Settings.';

  static NotificationPromptCopy forSurface(NotificationPromptSurface surface) {
    return switch (surface) {
      NotificationPromptSurface.dailyWar => const NotificationPromptCopy(
        title: 'Get pinged before tonight’s Daily Battle',
        body:
            'One reminder, 30 minutes before the 9 PM Daily Battle — so you’re never scrambling in when it starts.',
        alsoLine:
            'You’ll also get Daily CA, Daily Drill, and community invites.',
        cta: 'Turn on reminders',
      ),
      NotificationPromptSurface.dailyCa => const NotificationPromptCopy(
        title: 'Get pinged when today’s CA is live',
        body:
            'A morning nudge when the Daily Current Affairs paper is ready — so you don’t miss yesterday’s news.',
        alsoLine:
            'You’ll also get Daily Drill reminders, CA Shots, and community invites.',
        cta: 'Turn on reminders',
      ),
      NotificationPromptSurface.community => const NotificationPromptCopy(
        title: 'Get pinged for battles and replies',
        body:
            'Know when someone challenges you or replies in chat, without checking Community.',
        alsoLine: 'You’ll also get Daily Drill, current affairs, and CA Shots.',
        cta: 'Turn on alerts',
      ),
      NotificationPromptSurface.generic => const NotificationPromptCopy(
        title: 'Stay on track with useful pings',
        body:
            'Daily Drill, current affairs, CA Shots, and community invites — only the ones that help you show up.',
        alsoLine: 'You can turn these off anytime.',
        cta: 'Turn on reminders',
      ),
    };
  }
}

/// Timing helpers for the education sheet / post-onboarding settle delay.
abstract final class NotificationPromptPolicy {
  static const maxAutomaticShows = 2;
  static const automaticCooldown = Duration(hours: 24);
  static const screenSettleDelay = Duration(milliseconds: 800);

  /// Frequency gate for automatic education-sheet shows.
  static bool shouldShowAutomatic({
    required int automaticShownCount,
    required DateTime? lastAutomaticShownAt,
    required DateTime now,
  }) {
    if (automaticShownCount >= maxAutomaticShows) return false;
    final last = lastAutomaticShownAt;
    if (last != null && now.difference(last) < automaticCooldown) {
      return false;
    }
    return true;
  }
}
