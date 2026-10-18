import 'package:flutter/material.dart';

import 'app_toast.dart';

void showTopSnackBar(
  BuildContext context, {
  required Widget content,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  final resolvedContent = content is Text
      ? Text(
          content.data ?? '',
          key: content.key,
          style: (content.style ?? const TextStyle()).copyWith(
            color: Colors.white,
          ),
          strutStyle: content.strutStyle,
          textAlign: content.textAlign,
          textDirection: content.textDirection,
          locale: content.locale,
          softWrap: content.softWrap,
          overflow: content.overflow,
          maxLines: content.maxLines,
          semanticsLabel: content.semanticsLabel,
          textWidthBasis: content.textWidthBasis,
          textHeightBehavior: content.textHeightBehavior,
          selectionColor: content.selectionColor,
        )
      : content;
  AppToast.show(
    context,
    child: resolvedContent,
    duration: duration,
    top: true,
    action: action == null
        ? null
        : AppToastAction(label: action.label, onPressed: action.onPressed),
  );
}
