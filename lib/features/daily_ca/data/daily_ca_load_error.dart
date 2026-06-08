import 'package:cloud_firestore/cloud_firestore.dart';

import 'daily_ca_repository.dart';

/// User-visible + log-friendly message for daily CA load failures.
String dailyCaLoadErrorMessage(Object error) {
  if (error is DailyCaNotAvailableException) {
    return error.toString();
  }
  if (error is DailyCaPermissionDeniedException) {
    return error.toString();
  }
  if (error is FirebaseException) {
    return 'Firestore ${error.code}: ${error.message ?? error.toString()}';
  }
  return '${error.runtimeType}: $error';
}

bool dailyCaErrorIsPermissionDenied(Object error) {
  if (error is DailyCaPermissionDeniedException) return true;
  if (error is FirebaseException) {
    return error.code.toLowerCase() == 'permission-denied';
  }
  final text = error.toString();
  return text.contains('PERMISSION_DENIED') ||
      text.contains('permission-denied');
}

bool dailyCaErrorIsNotAvailable(Object error) =>
    error is DailyCaNotAvailableException;
