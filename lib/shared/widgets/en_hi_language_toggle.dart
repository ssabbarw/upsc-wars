import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/// Compact EN | हि control. A tap **anywhere** on the widget toggles language
/// (avoids tiny per-segment hit targets).
class EnHiLanguageToggle extends StatelessWidget {
  const EnHiLanguageToggle({
    super.key,
    required this.language,
    required this.onChanged,
    this.minHeight = 32,
  });

  /// Current language: `'en'` or `'hi'`.
  final String language;

  /// Called with the language after a toggle (`'en'` ↔ `'hi'`).
  final ValueChanged<String> onChanged;

  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isHi = language == 'hi';
    final radius = BorderRadius.circular(AppRadius.sm);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(isHi ? 'en' : 'hi'),
        borderRadius: radius,
        child: Ink(
          height: minHeight,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Seg(
                  label: 'EN',
                  selected: !isHi,
                  scheme: scheme,
                  left: true,
                ),
                _Seg(
                  label: 'हि',
                  selected: isHi,
                  scheme: scheme,
                  left: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.scheme,
    required this.left,
  });

  final String label;
  final bool selected;
  final ColorScheme scheme;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.horizontal(
          left: left ? Radius.circular(AppRadius.sm - 1) : Radius.zero,
          right: left ? Radius.zero : Radius.circular(AppRadius.sm - 1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
