import 'package:intl/intl.dart';

String formatIntCount(int value) =>
    NumberFormat.decimalPattern('en_IN').format(value);
