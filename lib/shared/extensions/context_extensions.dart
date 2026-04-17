import 'package:flutter/material.dart';

extension BuildContextThemeX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
