class LlmModelOption {
  const LlmModelOption({
    required this.id,
    required this.label,
    this.blurb = '',
  });

  final String id;
  final String label;
  final String blurb;

  factory LlmModelOption.fromMap(Map<String, dynamic> map) {
    return LlmModelOption(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      blurb: (map['blurb'] ?? '').toString(),
    );
  }
}

/// Fallback if the callable is not deployed yet.
const kFallbackLlmModels = [
  LlmModelOption(
    id: 'claude-haiku-4-5-20251001',
    label: 'Haiku 4.5',
    blurb: 'Fast and cheap. Weaker traps.',
  ),
  LlmModelOption(
    id: 'claude-sonnet-4-6',
    label: 'Sonnet 4.6',
    blurb: 'Recommended default for Shots.',
  ),
  LlmModelOption(
    id: 'claude-sonnet-5',
    label: 'Sonnet 5',
    blurb: 'Latest balanced. Stronger than 4.6.',
  ),
  LlmModelOption(
    id: 'claude-opus-4-6',
    label: 'Opus 4.6',
    blurb: 'Stronger reasoning. Slower.',
  ),
  LlmModelOption(
    id: 'claude-opus-5',
    label: 'Opus 5',
    blurb: 'Latest strong. Slow and pricey.',
  ),
  LlmModelOption(
    id: 'claude-fable-5',
    label: 'Fable 5',
    blurb: 'Frontier. Slowest and ~3× Opus cost.',
  ),
];

const kDefaultShotsModel = 'claude-sonnet-4-6';
const kDefaultCaModel = 'claude-sonnet-4-6';

class LlmAdminSettings {
  const LlmAdminSettings({
    required this.models,
    required this.shotsModel,
    required this.caModel,
    required this.shotsKeySet,
    required this.caKeySet,
    required this.shotsKeyHint,
    required this.caKeyHint,
    required this.shotsKeyFromEnv,
    required this.caKeyFromEnv,
  });

  final List<LlmModelOption> models;
  final String shotsModel;
  final String caModel;
  final bool shotsKeySet;
  final bool caKeySet;
  final String shotsKeyHint;
  final String caKeyHint;
  final bool shotsKeyFromEnv;
  final bool caKeyFromEnv;

  factory LlmAdminSettings.fromMap(Map<String, dynamic> map) {
    final rawModels = map['models'];
    final parsed = rawModels is List
        ? [
            for (final item in rawModels)
              if (item is Map)
                LlmModelOption.fromMap(Map<String, dynamic>.from(item)),
          ].where((m) => m.id.isNotEmpty).toList()
        : const <LlmModelOption>[];
    return LlmAdminSettings(
      models: parsed.isNotEmpty ? parsed : kFallbackLlmModels,
      shotsModel: (map['shots_model'] ?? kDefaultShotsModel).toString(),
      caModel: (map['ca_model'] ?? kDefaultCaModel).toString(),
      shotsKeySet: map['shots_key_set'] == true,
      caKeySet: map['ca_key_set'] == true,
      shotsKeyHint: (map['shots_key_hint'] ?? '').toString(),
      caKeyHint: (map['ca_key_hint'] ?? '').toString(),
      shotsKeyFromEnv: map['shots_key_from_env'] == true,
      caKeyFromEnv: map['ca_key_from_env'] == true,
    );
  }
}
