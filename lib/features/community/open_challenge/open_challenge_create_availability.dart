import '../../../core/providers/prefs_provider.dart';
import '../../../l10n/l10n.dart';

/// Local 24h cooldown after publishing an open challenge (same device).
class OpenChallengeCreateAvailability {
  const OpenChallengeCreateAvailability({
    required this.allowed,
    this.unlocksAt,
  });

  final bool allowed;
  final DateTime? unlocksAt;

  static const cooldown = Duration(hours: 24);

  factory OpenChallengeCreateAvailability.fromPrefs(PrefsService prefs) {
    final ms = prefs.openChallengeLastPublishedAtMs;
    if (ms == null) {
      return const OpenChallengeCreateAvailability(allowed: true);
    }
    final published = DateTime.fromMillisecondsSinceEpoch(ms);
    final until = published.add(cooldown);
    if (!DateTime.now().isBefore(until)) {
      return const OpenChallengeCreateAvailability(allowed: true);
    }
    return OpenChallengeCreateAvailability(allowed: false, unlocksAt: until);
  }

  Duration? get _remaining {
    final u = unlocksAt;
    if (u == null) return null;
    final d = u.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  /// Short fragment for inline copy, e.g. "about 6h 12m".
  String get etaShort {
    final d = _remaining;
    if (d == null) return '';
    if (d.inMinutes < 1) return appL10n.ocAMoment;
    if (d.inHours < 1) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h >= 24) return '${d.inDays}d';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// One line for tooltips / compact rows.
  String get tooltipLine => appL10n.ocTooltipLine(etaShort);

  /// Cards + Community hint under Create.
  String get bodyCopy => appL10n.ocBodyCopy(etaShort);

  /// Subject picker footer when blocked.
  String get pickSubjectCopy => appL10n.ocPickCopy(etaShort);
}
