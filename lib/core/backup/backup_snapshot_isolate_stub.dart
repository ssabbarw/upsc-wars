import 'backup_snapshot.dart';

/// Web has no file-backed DB or isolates; the service never calls this there.
Future<BackupSnapshot> buildPendingSnapshotInBackground({
  required String dbPath,
  required int limit,
}) => throw UnsupportedError('Background backup snapshot needs dart:io');
