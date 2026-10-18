import 'package:cloud_firestore/cloud_firestore.dart';

import 'daily_ca_repository.dart';
import '../../../l10n/l10n.dart';

String get _notAvailableCopy => appL10n.dcaNotAvailableCopy;
String get _genericLoadCopy => appL10n.dcaGenericLoadCopy;

/// Snackbar copy. Never includes Firebase, Firestore, or collection names.
String dailyCaUserFacingErrorMessage(Object error) {
  if (dailyCaErrorIsNotAvailable(error) ||
      dailyCaErrorIsPermissionDenied(error)) {
    return _notAvailableCopy;
  }
  return _genericLoadCopy;
}

/// Log-only message. May include Firestore paths and codes — do not show in UI.
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
