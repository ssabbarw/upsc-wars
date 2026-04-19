import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/web_player/web_firebase.dart';
import 'package:upsc_wars/web_player/web_player_shell.dart';

/// Web-only entry: shared practice at `/share/{kind}/{shareId}/` without Drift.
///
/// Run: `flutter run -d chrome -t lib/web_player/web_main.dart`
/// Build: `flutter build web -t lib/web_player/web_main.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    debugPrint('web_main is intended for Flutter Web only.');
  }
  await Firebase.initializeApp(options: webPlayerFirebaseOptions());
  runApp(const ProviderScope(child: WebPlayerRoot()));
}
