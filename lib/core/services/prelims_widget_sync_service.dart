import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../constants/prelims_countdown.dart';
import '../constants/prelims_debug_flags.dart';

class PrelimsWidgetSyncService {
  PrelimsWidgetSyncService._();

  static const String _androidWidgetProvider = 'PrelimsCountdownWidgetProvider';
  static const String _iosWidgetKind = 'PrelimsCountdownWidget';
  static const String _iosAppGroupId = 'group.tinyminyapps.upsc.wars';
  static const String _timerKey = 'prelims_timer_label';
  static const String _quoteKey = 'prelims_quote';
  static const String _debugMinuteRefreshKey = 'prelims_debug_minute_refresh';

  static Future<void> sync() async {
    final now = DateTime.now();
    final days = PrelimsCountdown.daysLeft(now: now);
    final timerLabel = PrelimsDebugFlags.surfacesEveryMinute
        ? '$days @${DateFormat('HH:mm').format(now)}'
        : days.toString();
    final quote = PrelimsCountdown.quoteForDate(now: now);

    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_iosAppGroupId);
    }

    await HomeWidget.saveWidgetData<String>(_timerKey, timerLabel);
    await HomeWidget.saveWidgetData<String>(_quoteKey, quote);
    await HomeWidget.saveWidgetData<String>(
      _debugMinuteRefreshKey,
      PrelimsDebugFlags.surfacesEveryMinute ? '1' : '0',
    );

    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
    } else if (Platform.isIOS) {
      await HomeWidget.updateWidget(iOSName: _iosWidgetKind);
    }
  }
}
