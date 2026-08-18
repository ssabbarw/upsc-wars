import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../domain/llm_admin_settings.dart';

class LlmModelDropdown extends StatelessWidget {
  const LlmModelDropdown({
    super.key,
    required this.label,
    required this.models,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final List<LlmModelOption> models;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ids = {for (final m in models) m.id};
    final selected = value != null && ids.contains(value)
        ? value
        : (models.isNotEmpty ? models.first.id : null);
    final selectedOption = models.where((m) => m.id == selected).firstOrNull;

    return DropdownButtonFormField<String>(
      key: ValueKey(selected),
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: selectedOption?.blurb,
        helperMaxLines: 2,
      ),
      items: [
        for (final m in models)
          DropdownMenuItem(
            value: m.id,
            child: Text(m.label, style: AppTextStyles.bodySm()),
          ),
      ],
      onChanged: enabled && selected != null
          ? (next) {
              if (next != null) onChanged(next);
            }
          : null,
      dropdownColor: scheme.surface,
    );
  }
}
