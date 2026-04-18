import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'prelims_surfaces_refresh.dart';

@pragma('vm:entry-point')
void prelimsWorkmanagerCallbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    try {
      await PrelimsSurfacesRefresh.refreshAllSurfaces();
    } catch (e, st) {
      debugPrint('PrelimsSurfacesRefresh failed: $e\n$st');
      return false;
    }
    return true;
  });
}
