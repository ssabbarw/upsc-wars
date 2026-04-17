import 'package:flutter/material.dart';

void showTopSnackBar(
  BuildContext context, {
  required Widget content,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  final media = MediaQuery.of(context);
  final topOffset = media.viewPadding.top + kToolbarHeight + 8;
  final bottomMargin = (media.size.height - topOffset - 56).clamp(
    12.0,
    media.size.height - 12.0,
  );

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: content,
      action: action,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(12, 0, 12, bottomMargin),
    ),
  );
}
