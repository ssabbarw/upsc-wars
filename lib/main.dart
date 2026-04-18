import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/upsc_wars_app.dart';
import 'core/providers/prefs_provider.dart';
import 'core/services/battle_messaging_service.dart';
import 'core/services/prelims_notification_service.dart';
import 'core/services/prelims_widget_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Firebase.initializeApp();
  // Capture tap-to-open payload before runApp. On Android, reading
  // getInitialMessage too late can leave data unavailable for routing.
  final openedFromNotification =
      await FirebaseMessaging.instance.getInitialMessage();
  if (openedFromNotification != null) {
    BattleMessagingService.setPendingOpenedNotification(openedFromNotification);
  }
  unawaited(PrelimsWidgetSyncService.sync());
  final launchPrefs = await SharedPreferences.getInstance();
  if (launchPrefs.getBool(PrefKeys.prelimsPersistentNotification) ?? true) {
    unawaited(PrelimsNotificationService.syncPersistentNotification());
  }
  runApp(const ProviderScope(child: UpscWarsApp()));
}
