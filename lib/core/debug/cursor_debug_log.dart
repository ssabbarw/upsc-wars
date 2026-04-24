import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Minimal NDJSON logger for Cursor debug-mode sessions.
///
/// Do not log secrets/PII.
class CursorDebugLog {
  CursorDebugLog._();

  static const String _sessionId = '3fd9a5';
  static const String _path = '.cursor/debug-3fd9a5.log';

  static Future<void> write({
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, Object?> data = const {},
    String runId = 'pre-fix',
  }) async {
    if (kIsWeb) return;
    try {
      final payload = <String, Object?>{
        'sessionId': _sessionId,
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final line = '${jsonEncode(payload)}\n';
      final file = File(_path);
      await file.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (_) {
      // Swallow: never crash app for debug logging.
    }
  }

}
