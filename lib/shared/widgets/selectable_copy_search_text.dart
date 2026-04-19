import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Inline spans for strings that use markdown-style `**bold**` (markers are not shown).
List<InlineSpan> doubleAsteriskBoldInlineSpans(String data, TextStyle baseStyle) {
  final spans = <InlineSpan>[];
  final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
  var i = 0;
  while (i < data.length) {
    final open = data.indexOf('**', i);
    if (open < 0) {
      if (i < data.length) {
        spans.add(TextSpan(text: data.substring(i)));
      }
      break;
    }
    if (open > i) {
      spans.add(TextSpan(text: data.substring(i, open)));
    }
    final close = data.indexOf('**', open + 2);
    if (close < 0) {
      spans.add(TextSpan(text: data.substring(open)));
      break;
    }
    spans.add(TextSpan(text: data.substring(open + 2, close), style: boldStyle));
    i = close + 2;
  }
  if (spans.isEmpty) {
    spans.add(const TextSpan(text: ''));
  }
  return spans;
}

/// Question and explanation copy: selectable with Copy (system) and Search Google
/// in the text selection toolbar.
class SelectableCopySearchText extends StatelessWidget {
  const SelectableCopySearchText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.strutStyle,
    this.textDirection,
    this.textScaler,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.semanticsLabel,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final TextScaler? textScaler;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final String? semanticsLabel;

  static Widget _contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final baseItems = List<ContextMenuButtonItem>.from(
      editableTextState.contextMenuButtonItems,
    );
    final sel = editableTextState.textEditingValue.selection;
    final plain = editableTextState.textEditingValue.text;
    final selected =
        sel.isValid && !sel.isCollapsed ? sel.textInside(plain).trim() : '';
    if (selected.isNotEmpty) {
      baseItems.add(
        ContextMenuButtonItem(
          label: 'Search Google',
          onPressed: () {
            ContextMenuController.removeAny();
            unawaited(_openGoogleSearch(selected));
          },
        ),
      );
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: baseItems,
    );
  }

  static Future<void> _openGoogleSearch(String query) async {
    final uri = Uri.https('www.google.com', '/search', {'q': query});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    return SelectableText.rich(
      TextSpan(
        style: effectiveStyle,
        children: doubleAsteriskBoldInlineSpans(data, effectiveStyle),
      ),
      strutStyle: strutStyle,
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
      textWidthBasis: textWidthBasis ?? TextWidthBasis.parent,
      textHeightBehavior: textHeightBehavior,
      semanticsLabel: semanticsLabel ?? (data.contains('**') ? data.replaceAll('**', '') : null),
      contextMenuBuilder: _contextMenuBuilder,
    );
  }
}
