import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// English topic name → Hindi label for Hindi-medium display.
///
/// Stored topic keys stay English. A missing entry falls back to that key.
final topicHindiNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  return loadTopicHindiNames();
});

Map<String, String> _cached = const {};

Future<Map<String, String>> loadTopicHindiNames() async {
  if (_cached.isNotEmpty) return _cached;
  final raw = await rootBundle.loadString(
    'assets/data/topic_translations.json',
  );
  final decoded = json.decode(raw) as Map<String, dynamic>;
  _cached = {
    for (final entry in decoded.entries)
      if ((entry.value as String).trim().isNotEmpty)
        entry.key: (entry.value as String).trim(),
  };
  return _cached;
}

/// Hindi label when [language] is `hi` and a translation exists.
/// Otherwise [englishName], which is also the stored key.
String localizedTopicName(
  String englishName, {
  required String language,
  Map<String, String>? hindiNames,
}) {
  if (language != 'hi') return englishName;
  final translated = (hindiNames ?? _cached)[englishName]?.trim() ?? '';
  if (translated.isEmpty) return englishName;
  return translated;
}

/// Prefer a database translation, then the asset, then the English key.
String resolvedTopicDisplayName({
  required String englishName,
  required String currentDisplayName,
  required String language,
  Map<String, String>? hindiNames,
}) {
  final current = currentDisplayName.trim();
  if (language == 'hi' && current.isNotEmpty && current != englishName) {
    return current;
  }
  return localizedTopicName(
    englishName,
    language: language,
    hindiNames: hindiNames,
  );
}
