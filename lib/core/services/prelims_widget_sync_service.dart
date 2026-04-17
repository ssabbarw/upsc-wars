import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../constants/prelims_countdown.dart';

class PrelimsWidgetSyncService {
  PrelimsWidgetSyncService._();

  static const String _androidWidgetProvider = 'PrelimsCountdownWidgetProvider';
  static const String _daysKey = 'prelims_days_label';
  static const String _quoteKey = 'prelims_quote';

  static Future<void> sync() async {
    final now = DateTime.now();
    final daysLabel = PrelimsCountdown.daysLabel(now: now);
    final quote = PrelimsCountdown.quoteForDate(now: now);

    await HomeWidget.saveWidgetData<String>(_daysKey, daysLabel);
    await HomeWidget.saveWidgetData<String>(_quoteKey, quote);

    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
    }
  }
}
