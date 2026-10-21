import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/deep_link/share_link_url_builder.dart';
import '../daily_ca_share_constants.dart';
import '../domain/daily_ca_schedule.dart';

/// Public HTTPS link for Telegram / Universal Links.
///
/// Pass [isoDate] for a fixed paper, or omit / use `today` for the live paper.
Uri dailyCaShareUri([String? dateSegment]) {
  final raw = (dateSegment ?? DailyCaShareConstants.todaySegment).trim();
  final seg = DailyCaShareConstants.isTodaySegment(raw)
      ? DailyCaShareConstants.todaySegment
      : raw;
  return Uri(
    scheme: 'https',
    host: shareLinkWebHost,
    path: '/${DailyCaShareConstants.publicPathSegment}/$seg',
  );
}

/// Share today's (or a specific day's) Daily CA link.
Future<void> shareDailyCaPaper({String? isoDate}) async {
  final useToday =
      isoDate == null ||
      isoDate.trim().isEmpty ||
      DailyCaShareConstants.isTodaySegment(isoDate);
  final uri = dailyCaShareUri(
    useToday ? DailyCaShareConstants.todaySegment : isoDate!.trim(),
  );

  String headline;
  if (useToday) {
    headline = "Today's Current Affairs quiz";
  } else {
    final date = DailyCaSchedule.parseIsoDate(isoDate!.trim());
    headline =
        'Daily Current Affairs — ${DateFormat('d MMM yyyy').format(date)}';
  }

  final text = '$headline\n$uri';
  await SharePlus.instance.share(
    ShareParams(text: text, title: headline),
  );
}
