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

/// Remote-config (and similar) gates for [NotificationPromptCopy] bullets.
class NotificationPromptFlags {
  const NotificationPromptFlags({
    this.dailyCa = false,
    this.caShots = false,
    this.dailyWar = false,
    this.community = false,
  });

  final bool dailyCa;
  final bool caShots;
  final bool dailyWar;
  final bool community;
}

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

  static NotificationPromptCopy forSurface(
    NotificationPromptSurface surface, {
    NotificationPromptFlags flags = const NotificationPromptFlags(),
    bool skippedDemoReview = false,
  }) {
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
      NotificationPromptSurface.postFirstTest => skippedDemoReview
          ? NotificationPromptCopy(
              title: 'No time for the explanations right now?',
              body:
                  'That’s fine. We can ping you later to review — and to try '
                  'the rest of UPSC Wars.',
              bullets: _postFirstTestBullets(flags),
              alsoLine:
                  'Turn on notifications and we’ll nudge you when it’s a good time.',
              cta: 'Notify me',
            )
          : NotificationPromptCopy(
              title: 'Liked this test — and the explanations?',
              body: "That's the demo. Here's what else is waiting:",
              bullets: _postFirstTestBullets(flags),
              alsoLine:
                  "Turn on notifications and we'll nudge you to revise the ones you got wrong.",
              cta: 'Notify me',
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

  static List<String> _postFirstTestBullets(NotificationPromptFlags flags) {
    return [
      'Revision games for topics that keep slipping',
      if (flags.community) '1v1 battles with other aspirants',
      if (flags.dailyCa)
        'Daily Current Affairs Test — yesterday’s news, scored',
      if (flags.caShots)
        'CA Shots — a news brief + 1 MCQ when something breaks',
      if (flags.dailyWar)
        'Daily Battle at 9 PM — same paper, All-India rank',
      'Year-wise solved PYQs, with the same explanations',
    ];
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
