import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/llm_admin_cloud_service.dart';
import '../domain/llm_admin_settings.dart';
import '../providers/llm_admin_providers.dart';
import '../widgets/llm_model_dropdown.dart';

class LlmAdminSettingsScreen extends HookConsumerWidget {
  const LlmAdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = useState<LlmAdminSettings?>(null);
    final loading = useState(true);
    final error = useState<String?>(null);
    final saving = useState(false);
    final shotsKeyCtrl = useTextEditingController();
    final caKeyCtrl = useTextEditingController();
    final cloud = ref.watch(llmAdminCloudServiceProvider);

    Future<void> reload() async {
      loading.value = true;
      error.value = null;
      try {
        settings.value = await cloud.getSettings();
      } catch (e) {
        error.value = LlmAdminCloudService.describeError(e);
      } finally {
        loading.value = false;
      }
    }

    useEffect(() {
      unawaited(reload());
      return null;
    }, const []);

    Future<void> persist({
      String? shotsModel,
      String? caModel,
      String? shotsApiKey,
      String? caApiKey,
      bool clearShotsKey = false,
      bool clearCaKey = false,
      required String success,
    }) async {
      saving.value = true;
      try {
        await cloud.setSettings(
          shotsModel: shotsModel,
          caModel: caModel,
          shotsApiKey: shotsApiKey,
          caApiKey: caApiKey,
          clearShotsKey: clearShotsKey,
          clearCaKey: clearCaKey,
        );
        if (shotsApiKey != null) shotsKeyCtrl.clear();
        if (caApiKey != null) caKeyCtrl.clear();
        await reload();
        if (context.mounted) {
          AppToast.showText(context, success);
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.showText(
            context,
            'Could not save: ${LlmAdminCloudService.describeError(e)}',
          );
        }
      } finally {
        saving.value = false;
      }
    }

    final current = settings.value;
    final models = current?.models ?? kFallbackLlmModels;

    return Scaffold(
      appBar: AppBar(title: const Text('LLM & API keys')),
      body: loading.value && current == null
          ? const Center(child: CircularProgressIndicator())
          : error.value != null && current == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error.value!, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => unawaited(reload()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Shots is the hero feature. Default to Sonnet — Haiku is too '
                  'weak for trap quality. Fable is strongest but slow and '
                  'expensive for a single MCQ.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _PipelineCard(
                  title: 'CA Shots',
                  subtitle: 'Breaking-news brief + 1 MCQ push',
                  models: models,
                  modelValue: current?.shotsModel ?? kDefaultShotsModel,
                  onModelChanged: saving.value
                      ? null
                      : (id) => unawaited(
                          persist(
                            shotsModel: id,
                            success: 'Shots model saved.',
                          ),
                        ),
                  keySet: current?.shotsKeySet ?? false,
                  keyFromEnv: current?.shotsKeyFromEnv ?? false,
                  keyHint: current?.shotsKeyHint ?? '',
                  controller: shotsKeyCtrl,
                  saving: saving.value,
                  onSaveKey: () {
                    final key = shotsKeyCtrl.text.trim();
                    if (key.isEmpty) return;
                    unawaited(
                      persist(
                        shotsApiKey: key,
                        success: 'Shots API key saved.',
                      ),
                    );
                  },
                  onClearKey: current?.shotsKeyHint.isNotEmpty == true
                      ? () => unawaited(
                          persist(
                            clearShotsKey: true,
                            success: 'Shots stored key cleared.',
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                _PipelineCard(
                  title: 'Daily CA MCQs',
                  subtitle: 'Nightly harvest and question set',
                  models: models,
                  modelValue: current?.caModel ?? kDefaultCaModel,
                  onModelChanged: saving.value
                      ? null
                      : (id) => unawaited(
                          persist(
                            caModel: id,
                            success: 'Daily CA model saved.',
                          ),
                        ),
                  keySet: current?.caKeySet ?? false,
                  keyFromEnv: current?.caKeyFromEnv ?? false,
                  keyHint: current?.caKeyHint ?? '',
                  controller: caKeyCtrl,
                  saving: saving.value,
                  onSaveKey: () {
                    final key = caKeyCtrl.text.trim();
                    if (key.isEmpty) return;
                    unawaited(
                      persist(
                        caApiKey: key,
                        success: 'Daily CA API key saved.',
                      ),
                    );
                  },
                  onClearKey: current?.caKeyHint.isNotEmpty == true
                      ? () => unawaited(
                          persist(
                            clearCaKey: true,
                            success: 'Daily CA stored key cleared.',
                          ),
                        )
                      : null,
                ),
              ],
            ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({
    required this.title,
    required this.subtitle,
    required this.models,
    required this.modelValue,
    required this.onModelChanged,
    required this.keySet,
    required this.keyFromEnv,
    required this.keyHint,
    required this.controller,
    required this.saving,
    required this.onSaveKey,
    required this.onClearKey,
  });

  final String title;
  final String subtitle;
  final List<LlmModelOption> models;
  final String modelValue;
  final ValueChanged<String>? onModelChanged;
  final bool keySet;
  final bool keyFromEnv;
  final String keyHint;
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSaveKey;
  final VoidCallback? onClearKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = !keySet
        ? 'No API key'
        : keyFromEnv
        ? 'Using env fallback'
        : 'Stored key $keyHint';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LlmModelDropdown(
            label: 'Model',
            models: models,
            value: modelValue,
            enabled: onModelChanged != null,
            onChanged: onModelChanged ?? (_) {},
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            status,
            style: AppTextStyles.caption().copyWith(
              color: keySet ? scheme.primary : scheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            obscureText: true,
            enabled: !saving,
            decoration: const InputDecoration(
              labelText: 'New Anthropic API key',
              helperText: 'Paste to replace. Full keys are never shown again.',
              helperMaxLines: 2,
            ),
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              FilledButton(
                onPressed: saving ? null : onSaveKey,
                child: const Text('Save key'),
              ),
              if (onClearKey != null) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: saving ? null : onClearKey,
                  child: const Text('Clear stored key'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
