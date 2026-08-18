import 'package:share_plus/share_plus.dart';

import '../../../core/deep_link/share_link_url_builder.dart';
import '../domain/fomo_pulse_models.dart';

Uri fomoPulseShareUri(String pulseId) {
  return Uri(
    scheme: 'https',
    host: shareLinkWebHost,
    path: '/fomo-pulse/${pulseId.trim()}',
  );
}

/// Share the briefing + deep link. Never includes options or the answer.
Future<void> shareFomoPulse(
  FomoPulse pulse, {
  bool bragCorrect = false,
  FomoPulseCommunityStats? stats,
}) async {
  final uri = fomoPulseShareUri(pulse.pulseId);
  final title = pulse.title.trim();
  final buf = StringBuffer();
  if (title.isNotEmpty) buf.writeln(title);
  if (bragCorrect) {
    buf.writeln("I didn't fall for it. Can you?");
  } else if (stats != null) {
    buf.writeln(stats.challengeLine);
  } else {
    final body = pulse.body.trim();
    if (body.isNotEmpty) buf.writeln(body);
  }
  buf.write(uri.toString());
  await SharePlus.instance.share(
    ShareParams(
      text: buf.toString().trim(),
      uri: uri,
    ),
  );
}
