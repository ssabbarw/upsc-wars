import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/trap_example.dart';

/// Hand-written demo MCQs, keyed by trap type.
final trapExamplesProvider = FutureProvider<Map<String, TrapExample>>((
  ref,
) async {
  final raw = await rootBundle.loadString('assets/data/trap_examples.json');
  final list = json.decode(raw) as List<dynamic>;
  return {
    for (final item in list.cast<Map<String, dynamic>>())
      item['trap_type'] as String: TrapExample.fromJson(item),
  };
});

/// The demo MCQ for one trap type, or null when none is written yet.
final trapExampleProvider = FutureProvider.family<TrapExample?, String>((
  ref,
  trapType,
) async {
  final examples = await ref.watch(trapExamplesProvider.future);
  return examples[trapType];
});
