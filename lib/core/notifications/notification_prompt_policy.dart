/// Where the notification-permission sheet is being considered.
enum NotificationPromptSurface {
  dailyWar,
  dailyCa,
  community,
  postFirstTest,
  generic,
}

/// Automatic = screen-open strategy. Explicit = user tapped a notify CTA.
enum NotificationPromptKind { automatic, explicit }

/// Copy for the pre-permission sheet. Hero is contextual; [alsoLine] names
/// the other notification uses so one prompt covers the whole product.
class NotificationPromptCopy {
  const NotificationPromptCopy({
    required this.title,
    required this.body,
    required this.alsoLine,
    required this.cta,
  });

  final String title;
  final String body;
  final String alsoLine;
  final String cta;

  static const notNow = 'Not now';
  static const footer = 'You can change this anytime in Settings.';

  static NotificationPromptCopy forSurface(NotificationPromptSurface surface) {
    return switch (surface) {
      NotificationPromptSurface.dailyWar => const NotificationPromptCopy(
        title: 'Get pinged before tonight’s War',
        body:
            'One reminder, 30 minutes before the 9 PM Daily War — so you’re never scrambling in when it starts.',
        alsoLine:
            'You’ll also get Daily CA, practice reminders, and battle invites.',
        cta: 'Turn on reminders',
      ),
      NotificationPromptSurface.dailyCa => const NotificationPromptCopy(
        title: 'Get pinged when today’s CA is live',
        body:
            'A morning nudge when the Daily Current Affairs paper is ready — so you don’t miss yesterday’s news.',
        alsoLine:
            'You’ll also get Daily War reminders, practice pings, and battle invites.',
        cta: 'Turn on reminders',
      ),
      NotificationPromptSurface.community => const NotificationPromptCopy(
        title: 'Get pinged for battles and replies',
        body:
            'Know when someone challenges you or replies in chat, without checking Community.',
        alsoLine:
            'You’ll also get Daily War, current affairs, and practice reminders.',
        cta: 'Turn on alerts',
      ),
      NotificationPromptSurface.postFirstTest => const NotificationPromptCopy(
        title: 'Get pinged to practice tomorrow',
        body:
            'A daily reminder so this doesn’t stay a one-off — show up again without having to remember.',
        alsoLine:
            'You’ll also get Daily War, current affairs, and community invites.',
        cta: 'Turn on reminders',
      ),
      NotificationPromptSurface.generic => const NotificationPromptCopy(
        title: 'Stay on track with useful pings',
        body:
            'Daily War, current affairs, practice reminders, and community invites — only the ones that help you show up.',
        alsoLine: 'You can turn these off anytime.',
        cta: 'Turn on reminders',
      ),
    };
  }
}

/// When we may show the in-app education sheet (OS dialog is never auto-fired).
abstract final class NotificationPromptPolicy {
  static const maxAutomaticShows = 2;
  static const automaticCooldown = Duration(hours: 24);
  static const screenSettleDelay = Duration(milliseconds: 800);

  /// [notificationsAlreadyEnabled] and OS ineligibility are handled by the
  /// caller. This only gates frequency for automatic prompts.
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
