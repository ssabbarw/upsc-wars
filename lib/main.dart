import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app/upsc_wars_app.dart';
import 'core/services/prelims_widget_sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(PrelimsWidgetSyncService.sync());
  runApp(const ProviderScope(child: UpscWarsApp()));
}
