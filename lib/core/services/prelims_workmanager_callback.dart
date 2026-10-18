import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'prelims_surfaces_refresh.dart';

@pragma('vm:entry-point')
void prelimsWorkmanagerCallbackDispatcher() {
  Workmanager().executeTask((
    String task,
    Map<String, dynamic>? inputData,
  ) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await PrelimsSurfacesRefresh.refreshAllSurfaces();
    } catch (e, st) {
      debugPrint('PrelimsSurfacesRefresh failed: $e\n$st');
      if (!kIsWeb) {
        try {
          await Firebase.initializeApp();
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
            true,
          );
          await FirebaseCrashlytics.instance.recordError(
            e,
            st,
            reason: 'workmanager:PrelimsSurfacesRefresh',
            fatal: false,
          );
        } catch (reportErr, reportSt) {
          debugPrint(
            'Workmanager Crashlytics report failed: $reportErr\n$reportSt',
          );
        }
      }
      return false;
    }
    return true;
  });
}
