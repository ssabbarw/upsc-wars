import 'app_constants.dart';

/// Feedback and support links (Settings, contact sheet).
///
/// Values live in [AppConstants]; this type keeps existing imports working.
abstract final class CreatorContact {
  CreatorContact._();

  static String get email => AppConstants.supportEmail;

  static String get telegramDirectUrl => AppConstants.developerTelegramUrl;

  static String get telegramGroupUrl => AppConstants.groupTelegramUrl;

  static Uri mailtoFeedbackUri() => AppConstants.supportMailtoUri();
}
