import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app/upsc_wars_app.dart';
import 'core/constants/prelims_debug_flags.dart';
import 'core/services/battle_messaging_service.dart';
import 'core/services/prelims_surfaces_refresh.dart';
import 'core/services/prelims_workmanager_callback.dart';

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
  if (Platform.isAndroid) {
    await Workmanager().initialize(prelimsWorkmanagerCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      PrelimsSurfacesRefresh.periodicTaskUniqueName,
      PrelimsSurfacesRefresh.periodicTaskName,
      frequency: PrelimsDebugFlags.surfacesEveryMinute
          ? const Duration(minutes: 1)
          : const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
  unawaited(PrelimsSurfacesRefresh.refreshAllSurfaces());
  runApp(const ProviderScope(child: UpscWarsApp()));
}
