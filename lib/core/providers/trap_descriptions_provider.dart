import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trap_descriptions_provider.g.dart';

/// One entry from trap_descriptions.json.
class TrapDescription {
  const TrapDescription({
    required this.trapType,
    required this.displayName,
    required this.blurb,
    required this.description,
    this.blurbHi,
    this.descriptionHi,
  });

  final String trapType;
  final String displayName;
  final String blurb;
  final String description;
  final String? blurbHi;
  final String? descriptionHi;

  String blurbFor(String language) =>
      _localized(language, hi: blurbHi, en: blurb);

  String descriptionFor(String language) =>
      _localized(language, hi: descriptionHi, en: description);

  static String _localized(String language, {required String en, String? hi}) {
    if (language == 'hi') {
      final trimmed = hi?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return en;
  }

  factory TrapDescription.fromJson(Map<String, dynamic> json) {
    final description = json['description'] as String;
    final blurb = (json['blurb'] as String?)?.trim();
    return TrapDescription(
      trapType: json['trap_type'] as String,
      displayName: json['display_name'] as String,
      blurb: (blurb != null && blurb.isNotEmpty) ? blurb : description,
      description: description,
      blurbHi: _optionalHi(json['blurb_hi']),
      descriptionHi: _optionalHi(json['description_hi']),
    );
  }
}

String? _optionalHi(Object? value) {
  final trimmed = (value as String?)?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

/// Loads the trap descriptions JSON once and keeps it alive.
/// Returns a map of trap-type slug → [TrapDescription].
@Riverpod(keepAlive: true)
Future<Map<String, TrapDescription>> trapDescriptions(Ref ref) async {
  final raw = await rootBundle.loadString('assets/data/trap_descriptions.json');
  final list = json.decode(raw) as List<dynamic>;
  return {
    for (final item in list.cast<Map<String, dynamic>>())
      item['trap_type'] as String: TrapDescription.fromJson(item),
  };
}
