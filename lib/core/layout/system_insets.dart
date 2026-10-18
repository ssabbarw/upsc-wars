import 'package:flutter/material.dart';

/// Height of the system navigation bar or home indicator.
double systemBottomInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom;

/// [base] spacing plus [systemBottomInset].
double paddedBottomInset(BuildContext context, [double base = 0]) =>
    base + systemBottomInset(context);

/// Bottom padding for modal sheets: keyboard, system nav bar, and optional base.
double sheetBottomPadding(
  BuildContext context, {
  double base = 0,
  bool includeKeyboard = true,
}) {
  final keyboard = includeKeyboard
      ? MediaQuery.viewInsetsOf(context).bottom
      : 0.0;
  return keyboard + paddedBottomInset(context, base);
}
