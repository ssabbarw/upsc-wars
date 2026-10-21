/// Public Daily CA share links: `https://upscwars.in/daily-ca/{date|today}`.
abstract final class DailyCaShareConstants {
  DailyCaShareConstants._();

  /// HTTPS path segment and custom-scheme host.
  static const publicPathSegment = 'daily-ca';

  /// Evergreen Telegram-friendly segment → current live paper (IST schedule).
  static const todaySegment = 'today';

  static const deepLinkHost = publicPathSegment;

  static const hubLocation = '/$publicPathSegment';

  static const entryShare = 'share';

  static final dateIdPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static bool isPublicPathSegment(String raw) =>
      raw.trim().toLowerCase() == publicPathSegment;

  static bool isValidDateId(String raw) => dateIdPattern.hasMatch(raw.trim());

  static bool isTodaySegment(String raw) =>
      raw.trim().toLowerCase() == todaySegment;

  /// True for `YYYY-MM-DD` or `today`.
  static bool isShareableDateSegment(String raw) {
    final s = raw.trim();
    return isTodaySegment(s) || isValidDateId(s);
  }

  /// In-app route for a shared / dated paper.
  ///
  /// [dateSegment] is `today` or `YYYY-MM-DD`.
  static String dateLocation(
    String dateSegment, {
    String? source,
    bool start = false,
  }) {
    final seg = dateSegment.trim().toLowerCase() == todaySegment
        ? todaySegment
        : dateSegment.trim();
    final q = <String, String>{
      if (source != null && source.trim().isNotEmpty) 'src': source.trim(),
      if (start) 'start': '1',
    };
    final path = '$hubLocation/$seg';
    if (q.isEmpty) return path;
    return Uri(path: path, queryParameters: q).toString();
  }
}
