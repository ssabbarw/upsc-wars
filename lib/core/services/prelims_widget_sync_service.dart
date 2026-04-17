import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../constants/prelims_countdown.dart';

class PrelimsWidgetSyncService {
  PrelimsWidgetSyncService._();

  static const String _androidWidgetProvider = 'PrelimsCountdownWidgetProvider';
  static const String _timerKey = 'prelims_timer_label';
  static const String _quoteKey = 'prelims_quote';

  static Future<void> sync() async {
    final now = DateTime.now();
    final timerLabel = PrelimsCountdown.daysLeft(now: now).toString();
    final quote = PrelimsCountdown.quoteForDate(now: now);

    await HomeWidget.saveWidgetData<String>(_timerKey, timerLabel);
    await HomeWidget.saveWidgetData<String>(_quoteKey, quote);

    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
    }
  }
}
