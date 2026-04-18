import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return SelectableText(
      data,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
      textWidthBasis: textWidthBasis ?? TextWidthBasis.parent,
      textHeightBehavior: textHeightBehavior,
      semanticsLabel: semanticsLabel,
      contextMenuBuilder: _contextMenuBuilder,
    );
  }
}
