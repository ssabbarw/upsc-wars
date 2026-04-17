import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trap_descriptions_provider.g.dart';

/// One entry from trap_descriptions.json.
class TrapDescription {
  const TrapDescription({
    required this.trapType,
    required this.displayName,
    required this.description,
  });

  final String trapType;
  final String displayName;
  final String description;

  factory TrapDescription.fromJson(Map<String, dynamic> json) =>
      TrapDescription(
        trapType: json['trap_type'] as String,
        displayName: json['display_name'] as String,
        description: json['description'] as String,
      );
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
