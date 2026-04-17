import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app/upsc_wars_app.dart';
import 'core/services/prelims_notification_service.dart';
import 'core/services/prelims_widget_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Firebase.initializeApp();
  unawaited(PrelimsWidgetSyncService.sync());
  unawaited(PrelimsNotificationService.showPersistentCountdown());
  runApp(const ProviderScope(child: UpscWarsApp()));
}
