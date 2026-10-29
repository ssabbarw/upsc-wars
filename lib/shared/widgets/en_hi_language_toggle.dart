import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/providers/app_language_helpers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

/// EN | हि switch used across the app. The selected side updates immediately.
///
/// [minHeight] is accepted so existing call sites keep compiling. The control
/// matches the Home header switch.
class EnHiLanguageToggle extends StatefulWidget {
  const EnHiLanguageToggle({
    super.key,
    required this.language,
    required this.onChanged,
    this.borderColor,
    this.minHeight = 32,
  });

  /// Current language: `'en'` or `'hi'`.
  final String language;

  /// Called with `'en'` or `'hi'` after the highlight has flipped.
  final ValueChanged<String> onChanged;

  final Color? borderColor;
  final double minHeight;

  @override
  State<EnHiLanguageToggle> createState() => _EnHiLanguageToggleState();
}

class _EnHiLanguageToggleState extends State<EnHiLanguageToggle> {
  late String _language = normalizeAppLanguage(widget.language);
  var _busy = false;

  @override
  void didUpdateWidget(covariant EnHiLanguageToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = normalizeAppLanguage(widget.language);
    if (!_busy && next != _language) {
      _language = next;
    }
    if (_busy && next == _language) {
      _busy = false;
    }
  }

  void _select(String lang) {
    if (_busy) return;
    final next = normalizeAppLanguage(lang);
    if (next == _language) return;
    HapticFeedback.selectionClick();
    setState(() {
      _language = next;
      _busy = true;
    });
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isHindi = _language == 'hi';
    final borderColor =
        widget.borderColor ?? scheme.outlineVariant.withValues(alpha: 0.7);

    Widget segment(String label, String lang, bool selected) {
      return Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selected || _busy ? null : () => _select(lang),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : AppColors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSm().copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            segment('EN', 'en', !isHindi),
            segment('हि', 'hi', isHindi),
          ],
        ),
      ),
    );
  }
}
