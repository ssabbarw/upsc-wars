/// Server traffic bots use `@upscwars.bot` (see `functions/bots/names.js`).
const kTrafficBotEmailDomain = 'upscwars.bot';

bool isTrafficBotEmail(String? email) {
  final e = email?.trim().toLowerCase() ?? '';
  return e.endsWith('@$kTrafficBotEmailDomain');
}

/// Daily War submissions use roster ids like `bot_priya_k04`.
bool isTrafficBotUid(String? uid) {
  final id = uid?.trim() ?? '';
  return id.startsWith('bot_');
}

bool isTrafficBot({String? email, String? uid}) {
  return isTrafficBotEmail(email) || isTrafficBotUid(uid);
}
