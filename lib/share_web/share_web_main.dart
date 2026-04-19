import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/share_web/share_web_firebase.dart';
import 'package:upsc_wars/share_web/share_web_shell.dart';

/// Web-only entry: shared practice at `/share/{kind}/{shareId}/`.
///
/// Run: `flutter run -d chrome -t lib/share_web/share_web_main.dart`
/// Build: `flutter build web -t lib/share_web/share_web_main.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    debugPrint('share_web_main is intended for Flutter Web only.');
  }
  await Firebase.initializeApp(options: shareWebFirebaseOptions());
  runApp(const ProviderScope(child: ShareWebRoot()));
}
