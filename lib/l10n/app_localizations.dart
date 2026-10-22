import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get commonExit;

  /// No description provided for @commonLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get commonLogOut;

  /// No description provided for @languagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get languagePickerTitle;

  /// No description provided for @languagePickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One setting for the whole app and the questions.'**
  String get languagePickerSubtitle;

  /// No description provided for @languagePickerHintEn.
  ///
  /// In en, this message translates to:
  /// **'App and questions both in English.'**
  String get languagePickerHintEn;

  /// No description provided for @languagePickerHintHi.
  ///
  /// In en, this message translates to:
  /// **'App and questions both in Hindi.'**
  String get languagePickerHintHi;

  /// No description provided for @languagePickerPracticeTest.
  ///
  /// In en, this message translates to:
  /// **'Practice test'**
  String get languagePickerPracticeTest;

  /// No description provided for @readingSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get readingSizeSmall;

  /// No description provided for @readingSizeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get readingSizeDefault;

  /// No description provided for @readingSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get readingSizeMedium;

  /// No description provided for @readingSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get readingSizeLarge;

  /// No description provided for @readingSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get readingSizeExtraLarge;

  /// No description provided for @routerExitDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit app?'**
  String get routerExitDialogTitle;

  /// No description provided for @routerExitDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You will leave {appName}.'**
  String routerExitDialogBody(String appName);

  /// No description provided for @settingsSeriesUnlocked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 series unlocked} other{{count} series unlocked}}'**
  String settingsSeriesUnlocked(int count);

  /// No description provided for @settingsBlockedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String settingsBlockedCount(int count);

  /// No description provided for @settingsLanguageSubtitleEn.
  ///
  /// In en, this message translates to:
  /// **'App and questions in English'**
  String get settingsLanguageSubtitleEn;

  /// No description provided for @settingsLanguageSubtitleHi.
  ///
  /// In en, this message translates to:
  /// **'App and questions in Hindi'**
  String get settingsLanguageSubtitleHi;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSectionSupport;

  /// No description provided for @settingsSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsSendFeedback;

  /// No description provided for @settingsTelegramDirect.
  ///
  /// In en, this message translates to:
  /// **'Telegram (direct)'**
  String get settingsTelegramDirect;

  /// No description provided for @settingsTelegramGroup.
  ///
  /// In en, this message translates to:
  /// **'Telegram (group)'**
  String get settingsTelegramGroup;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutUs.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get settingsAboutUs;

  /// No description provided for @settingsAboutUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What we’re building, why it exists'**
  String get settingsAboutUsSubtitle;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get settingsRateApp;

  /// No description provided for @settingsOpenAppStore.
  ///
  /// In en, this message translates to:
  /// **'Open App Store'**
  String get settingsOpenAppStore;

  /// No description provided for @settingsOpenPlayStore.
  ///
  /// In en, this message translates to:
  /// **'Open Play Store'**
  String get settingsOpenPlayStore;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsFooter.
  ///
  /// In en, this message translates to:
  /// **'Built with care for every serious aspirant.'**
  String get settingsFooter;

  /// No description provided for @settingsStoreOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the store. Try again later.'**
  String get settingsStoreOpenFailed;

  /// No description provided for @settingsHeaderTagline.
  ///
  /// In en, this message translates to:
  /// **'Make the app feel like yours.'**
  String get settingsHeaderTagline;

  /// No description provided for @settingsNoOneBlocked.
  ///
  /// In en, this message translates to:
  /// **'No one blocked'**
  String get settingsNoOneBlocked;

  /// No description provided for @settingsBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get settingsBlockedUsers;

  /// No description provided for @settingsLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get settingsLoggingOut;

  /// No description provided for @settingsSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device'**
  String get settingsSignOutSubtitle;

  /// No description provided for @settingsLogOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogOutConfirmTitle;

  /// No description provided for @settingsLogOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogOutConfirmBody;

  /// No description provided for @settingsLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get settingsLinkOpenFailed;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comfortable contrast for long sessions.'**
  String get settingsDarkModeSubtitle;

  /// No description provided for @settingsReadingSize.
  ///
  /// In en, this message translates to:
  /// **'Reading size'**
  String get settingsReadingSize;

  /// No description provided for @settingsReadingSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Question text and explanations.'**
  String get settingsReadingSizeSubtitle;

  /// No description provided for @settingsReadingSmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller'**
  String get settingsReadingSmaller;

  /// No description provided for @settingsReadingLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get settingsReadingLarger;

  /// No description provided for @settingsPreview.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get settingsPreview;

  /// No description provided for @settingsConfidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Confidence before reveal'**
  String get settingsConfidenceTitle;

  /// No description provided for @settingsConfidenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask “how sure are you?” before showing answers.'**
  String get settingsConfidenceSubtitle;

  /// No description provided for @settingsStatusBarReminder.
  ///
  /// In en, this message translates to:
  /// **'Status bar reminder'**
  String get settingsStatusBarReminder;

  /// No description provided for @settingsAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Available on Android.'**
  String get settingsAndroidOnly;

  /// No description provided for @settingsStatusBarReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the days-until-Prelims count visible.'**
  String get settingsStatusBarReminderSubtitle;

  /// No description provided for @routerGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get routerGoHome;

  /// No description provided for @routerLinkFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Link could not be opened'**
  String get routerLinkFailedTitle;

  /// No description provided for @routerErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Oh snap'**
  String get routerErrorTitle;

  /// No description provided for @routerLinkFailedBody.
  ///
  /// In en, this message translates to:
  /// **'This link could not be opened.\nPlease try again.'**
  String get routerLinkFailedBody;

  /// No description provided for @routerErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.\nPlease try again.'**
  String get routerErrorBody;

  /// No description provided for @revisionQueueEmptyLine.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the queue yet'**
  String get revisionQueueEmptyLine;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @revisionIncorrectMcqs.
  ///
  /// In en, this message translates to:
  /// **'Incorrect MCQs'**
  String get revisionIncorrectMcqs;

  /// No description provided for @revisionBookmarkedMcqs.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked MCQs'**
  String get revisionBookmarkedMcqs;

  /// No description provided for @revisionCountIncorrect.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 incorrect} other{{count} incorrect}}'**
  String revisionCountIncorrect(int count);

  /// No description provided for @revisionCountBookmark.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bookmark} other{{count} bookmarks}}'**
  String revisionCountBookmark(int count);

  /// No description provided for @ritualCaShotsWhen.
  ///
  /// In en, this message translates to:
  /// **'Through the day'**
  String get ritualCaShotsWhen;

  /// No description provided for @ritualCaShotsBody.
  ///
  /// In en, this message translates to:
  /// **'Breaking news brief + 1 MCQ. Two minutes when a shot lands.'**
  String get ritualCaShotsBody;

  /// No description provided for @ritualDailyCaWhen.
  ///
  /// In en, this message translates to:
  /// **'Opens 6 AM'**
  String get ritualDailyCaWhen;

  /// No description provided for @ritualDailyCaBody.
  ///
  /// In en, this message translates to:
  /// **'Yesterday\'s news as a scored paper. Revise any past day.'**
  String get ritualDailyCaBody;

  /// No description provided for @ritualDailyWarWhen.
  ///
  /// In en, this message translates to:
  /// **'9 PM · Mon–Fri'**
  String get ritualDailyWarWhen;

  /// No description provided for @ritualDailyWarBody.
  ///
  /// In en, this message translates to:
  /// **'All-India live static GS paper. Same questions, then the rank.'**
  String get ritualDailyWarBody;

  /// No description provided for @homeStreakMilestoneToast.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak. Keep showing up.'**
  String homeStreakMilestoneToast(int count);

  /// No description provided for @homeStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String homeStreakDays(int count);

  /// No description provided for @homeGreetingNamed.
  ///
  /// In en, this message translates to:
  /// **'Hey, {name}'**
  String homeGreetingNamed(String name);

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// No description provided for @homeTrapsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trap} other{{count} traps}}'**
  String homeTrapsCount(int count);

  /// No description provided for @homeCaughtByTraps.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been caught by {count, plural, =1{1 trap type} other{{count} trap types}}'**
  String homeCaughtByTraps(int count);

  /// No description provided for @homeStartNQuestionTest.
  ///
  /// In en, this message translates to:
  /// **'Start {count}-question test'**
  String homeStartNQuestionTest(int count);

  /// No description provided for @homeCountAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String homeCountAvailable(int count);

  /// No description provided for @activationLeftAt.
  ///
  /// In en, this message translates to:
  /// **'You left at question {done} of {total}. Pick up where you stopped.'**
  String activationLeftAt(int done, int total);

  /// No description provided for @homeAnsweredOf.
  ///
  /// In en, this message translates to:
  /// **'You\'ve answered {done} of {total} questions.'**
  String homeAnsweredOf(int done, int total);

  /// No description provided for @homeResumeProgress.
  ///
  /// In en, this message translates to:
  /// **'Resume · {done} of {total} done'**
  String homeResumeProgress(int done, int total);

  /// No description provided for @restoreProgressTests.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tests'**
  String restoreProgressTests(int done, int total);

  /// No description provided for @revisionPickPool.
  ///
  /// In en, this message translates to:
  /// **'Pick a pool. You’ll get a short random test from those questions — up to {count} at a time.'**
  String revisionPickPool(int count);

  /// No description provided for @homeOpenChallengeBy.
  ///
  /// In en, this message translates to:
  /// **'Open challenge by {name}'**
  String homeOpenChallengeBy(String name);

  /// No description provided for @homeGoalOthersLive.
  ///
  /// In en, this message translates to:
  /// **'{goal} · +{count} live'**
  String homeGoalOthersLive(String goal, int count);

  /// No description provided for @homeChallengeGoalMixed.
  ///
  /// In en, this message translates to:
  /// **'{who, select, poster{Beat their score of {score}/10 across mixed subjects} other{Beat the top score of {score}/10 across mixed subjects}}'**
  String homeChallengeGoalMixed(String who, int score);

  /// No description provided for @homeChallengeGoalSubject.
  ///
  /// In en, this message translates to:
  /// **'{who, select, poster{Beat their score of {score}/10 in {subject}} other{Beat the top score of {score}/10 in {subject}}}'**
  String homeChallengeGoalSubject(String who, int score, String subject);

  /// No description provided for @homeDangerLocked.
  ///
  /// In en, this message translates to:
  /// **'Questions you got wrong while sure. Unlocks at {total} questions.'**
  String homeDangerLocked(int total);

  /// No description provided for @homeDangerLockedProgress.
  ///
  /// In en, this message translates to:
  /// **'Questions you got wrong while sure. Unlocks at {total} questions. — {scored}/{total} so far.'**
  String homeDangerLockedProgress(int total, int scored);

  /// No description provided for @homeWeekReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{mistakes} questions where you slipped last week.'**
  String homeWeekReviewCount(int mistakes);

  /// No description provided for @homeDrillSubjectBit.
  ///
  /// In en, this message translates to:
  /// **'10 {subject} questions with instant feedback.'**
  String homeDrillSubjectBit(String subject);

  /// No description provided for @homeDrillOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'{counts}. Open again if you want another set.'**
  String homeDrillOpenAgain(String counts);

  /// No description provided for @homeDrillShortSet.
  ///
  /// In en, this message translates to:
  /// **'{counts}. A short set from misses or bookmarks.'**
  String homeDrillShortSet(String counts);

  /// No description provided for @homeStreak3Toast.
  ///
  /// In en, this message translates to:
  /// **'3-day streak — the habit is sticking.'**
  String get homeStreak3Toast;

  /// No description provided for @homeQuestionBankUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Question bank unavailable'**
  String get homeQuestionBankUnavailable;

  /// No description provided for @homeQuestionBankUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The question database could not be opened. Reinstall the app or ensure storage is available, then restart.'**
  String get homeQuestionBankUnavailableBody;

  /// No description provided for @homeGreetingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Hey there'**
  String get homeGreetingGeneric;

  /// No description provided for @homeResumeDemoTest.
  ///
  /// In en, this message translates to:
  /// **'Resume demo test'**
  String get homeResumeDemoTest;

  /// No description provided for @homeStartWithDemoTest.
  ///
  /// In en, this message translates to:
  /// **'Start with the demo test'**
  String get homeStartWithDemoTest;

  /// No description provided for @homeRateReview.
  ///
  /// In en, this message translates to:
  /// **'Rate & review'**
  String get homeRateReview;

  /// No description provided for @homePickAnySubject.
  ///
  /// In en, this message translates to:
  /// **'PICK ANY SUBJECT'**
  String get homePickAnySubject;

  /// No description provided for @homeSubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get homeSubjects;

  /// No description provided for @homePyqByYear.
  ///
  /// In en, this message translates to:
  /// **'PYQ by year'**
  String get homePyqByYear;

  /// No description provided for @homeQuestionsYouSaved.
  ///
  /// In en, this message translates to:
  /// **'Questions you saved'**
  String get homeQuestionsYouSaved;

  /// No description provided for @activationStartHere.
  ///
  /// In en, this message translates to:
  /// **'START HERE'**
  String get activationStartHere;

  /// No description provided for @activationTakeDemo.
  ///
  /// In en, this message translates to:
  /// **'Take the 5-minute demo test'**
  String get activationTakeDemo;

  /// No description provided for @activationPickUp.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off.'**
  String get activationPickUp;

  /// No description provided for @activationDemoPitch.
  ///
  /// In en, this message translates to:
  /// **'See how a trap question fools confident aspirants — and how Danger Zone catches it.'**
  String get activationDemoPitch;

  /// No description provided for @activationStartTest.
  ///
  /// In en, this message translates to:
  /// **'Start the test'**
  String get activationStartTest;

  /// No description provided for @activationHideTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide for now?'**
  String get activationHideTitle;

  /// No description provided for @activationHideBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll bring this back tomorrow.'**
  String get activationHideBody;

  /// No description provided for @activationHideConfirm.
  ///
  /// In en, this message translates to:
  /// **'Hide for now'**
  String get activationHideConfirm;

  /// No description provided for @activationKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get activationKeepGoing;

  /// No description provided for @drillSubjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily practice subject'**
  String get drillSubjectTitle;

  /// No description provided for @drillSubjectBody.
  ///
  /// In en, this message translates to:
  /// **'Choose what your daily drill focuses on.'**
  String get drillSubjectBody;

  /// No description provided for @revisionEmptyPools.
  ///
  /// In en, this message translates to:
  /// **'Questions you get wrong or bookmark will appear here. Then you can take a short random test from either pool.'**
  String get revisionEmptyPools;

  /// No description provided for @revisionPoolWrongBody.
  ///
  /// In en, this message translates to:
  /// **'A random test from questions you answered incorrectly.'**
  String get revisionPoolWrongBody;

  /// No description provided for @revisionPoolSavedBody.
  ///
  /// In en, this message translates to:
  /// **'A random test from questions you have bookmarked.'**
  String get revisionPoolSavedBody;

  /// No description provided for @ritualsIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily loop'**
  String get ritualsIntroTitle;

  /// No description provided for @ritualsIntroOne.
  ///
  /// In en, this message translates to:
  /// **'On Home. Same place every day.'**
  String get ritualsIntroOne;

  /// No description provided for @ritualsIntroTwo.
  ///
  /// In en, this message translates to:
  /// **'Two things on Home. Same place every day.'**
  String get ritualsIntroTwo;

  /// No description provided for @ritualsIntroThree.
  ///
  /// In en, this message translates to:
  /// **'Three things on Home. Same place every day.'**
  String get ritualsIntroThree;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @restorePaused.
  ///
  /// In en, this message translates to:
  /// **'Restore paused'**
  String get restorePaused;

  /// No description provided for @restoreFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not restore your data.'**
  String get restoreFailedBody;

  /// No description provided for @restoreDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is back'**
  String get restoreDoneTitle;

  /// No description provided for @restoreDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Restored your tests.'**
  String get restoreDoneBody;

  /// No description provided for @restoreInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Restoring your data…'**
  String get restoreInProgressTitle;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @restoreKeepUsing.
  ///
  /// In en, this message translates to:
  /// **'You can keep using the app while this finishes.'**
  String get restoreKeepUsing;

  /// No description provided for @homeNoQuestionsYet.
  ///
  /// In en, this message translates to:
  /// **'No questions answered yet.'**
  String get homeNoQuestionsYet;

  /// No description provided for @commonResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get commonResume;

  /// No description provided for @demoInProgress.
  ///
  /// In en, this message translates to:
  /// **'Demo in progress'**
  String get demoInProgress;

  /// No description provided for @commonStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get commonStartOver;

  /// No description provided for @demoTry.
  ///
  /// In en, this message translates to:
  /// **'Try a demo test'**
  String get demoTry;

  /// No description provided for @demoTrySuffix.
  ///
  /// In en, this message translates to:
  /// **' — see the edge UPSC Wars gives you'**
  String get demoTrySuffix;

  /// No description provided for @demoRemindTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Remind me tomorrow'**
  String get demoRemindTomorrow;

  /// No description provided for @demoNotNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Not now?'**
  String get demoNotNowTitle;

  /// No description provided for @demoNotNowBody.
  ///
  /// In en, this message translates to:
  /// **'This 5-minute demo finds questions you feel sure about but get wrong — the edge UPSC Wars is built around. We’ll nudge you again tomorrow until you finish one test.'**
  String get demoNotNowBody;

  /// No description provided for @demoTryDiagnostic.
  ///
  /// In en, this message translates to:
  /// **'Try the diagnostic instead'**
  String get demoTryDiagnostic;

  /// No description provided for @demoIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Find where UPSC Wars gives you an edge'**
  String get demoIntroTitle;

  /// No description provided for @demoIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Take this demo — current affairs mixed with static, with instant feedback after each answer.'**
  String get demoIntroBody;

  /// No description provided for @demoPoint1Title.
  ///
  /// In en, this message translates to:
  /// **'8 MCQs · no timer'**
  String get demoPoint1Title;

  /// No description provided for @demoPoint1Body.
  ///
  /// In en, this message translates to:
  /// **'Current affairs plus static — see the explanation as you go.'**
  String get demoPoint1Body;

  /// No description provided for @demoPoint2Title.
  ///
  /// In en, this message translates to:
  /// **'Mark your confidence'**
  String get demoPoint2Title;

  /// No description provided for @demoPoint2Body.
  ///
  /// In en, this message translates to:
  /// **'Sure, educated guess, or unsure — we spot what feels right but isn’t.'**
  String get demoPoint2Body;

  /// No description provided for @demoPoint3Title.
  ///
  /// In en, this message translates to:
  /// **'Rich insights when you finish'**
  String get demoPoint3Title;

  /// No description provided for @demoPoint3Body.
  ///
  /// In en, this message translates to:
  /// **'Confident mistakes, trap patterns, and what to revise next.'**
  String get demoPoint3Body;

  /// No description provided for @demoPoint4Title.
  ///
  /// In en, this message translates to:
  /// **'Explanations that actually teach'**
  String get demoPoint4Title;

  /// No description provided for @demoPoint4Body.
  ///
  /// In en, this message translates to:
  /// **'Traps, elimination, statement analysis — not just right or wrong.'**
  String get demoPoint4Body;

  /// No description provided for @demoLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let’s go'**
  String get demoLetsGo;

  /// No description provided for @demoSkipToHome.
  ///
  /// In en, this message translates to:
  /// **'Skip to home'**
  String get demoSkipToHome;

  /// No description provided for @todayCaLive.
  ///
  /// In en, this message translates to:
  /// **'Live now — based on yesterday\'s news.'**
  String get todayCaLive;

  /// No description provided for @todayCaNotDone.
  ///
  /// In en, this message translates to:
  /// **'Current affairs test from yesterday\'s news.'**
  String get todayCaNotDone;

  /// No description provided for @todayDone.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get todayDone;

  /// No description provided for @todayQuizDoneOpenAnswers.
  ///
  /// In en, this message translates to:
  /// **'Quiz done — open answers'**
  String get todayQuizDoneOpenAnswers;

  /// No description provided for @todaySignInOpenChallenge.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join an open challenge.'**
  String get todaySignInOpenChallenge;

  /// No description provided for @todayDangerUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Questions you got wrong while sure — trap patterns.'**
  String get todayDangerUnlocked;

  /// No description provided for @todayWhatIsThis.
  ///
  /// In en, this message translates to:
  /// **'What is this?'**
  String get todayWhatIsThis;

  /// No description provided for @todayCaShotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Breaking news brief + 1 MCQ based on it.'**
  String get todayCaShotSubtitle;

  /// No description provided for @todayPaperQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Current affairs quiz'**
  String get todayPaperQuizTitle;

  /// No description provided for @todayPaperQuizBody.
  ///
  /// In en, this message translates to:
  /// **'Based on yesterday\'s news. Same questions for everyone — then All-India Rank.'**
  String get todayPaperQuizBody;

  /// No description provided for @todayOpenPaper.
  ///
  /// In en, this message translates to:
  /// **'Open paper'**
  String get todayOpenPaper;

  /// No description provided for @todayWeekDone.
  ///
  /// In en, this message translates to:
  /// **'Week review done'**
  String get todayWeekDone;

  /// No description provided for @todayWeekDoneBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve gone through last week\'s mistakes. Streak intact.'**
  String get todayWeekDoneBody;

  /// No description provided for @todaySeeResults.
  ///
  /// In en, this message translates to:
  /// **'See results'**
  String get todaySeeResults;

  /// No description provided for @todayWeekEmpty.
  ///
  /// In en, this message translates to:
  /// **'No mistakes this week'**
  String get todayWeekEmpty;

  /// No description provided for @todayWeekEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No mistakes from last week — you\'re clean.'**
  String get todayWeekEmptyBody;

  /// No description provided for @todayQuickPracticeInstead.
  ///
  /// In en, this message translates to:
  /// **'Quick practice instead'**
  String get todayQuickPracticeInstead;

  /// No description provided for @todayWeekReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review last week\'s mistakes'**
  String get todayWeekReviewTitle;

  /// No description provided for @todayStartReview.
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get todayStartReview;

  /// No description provided for @todayDrillDone.
  ///
  /// In en, this message translates to:
  /// **'Drill done'**
  String get todayDrillDone;

  /// No description provided for @todayDrillTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s drill'**
  String get todayDrillTitle;

  /// No description provided for @todayDrillBody.
  ///
  /// In en, this message translates to:
  /// **'10 questions with instant feedback.'**
  String get todayDrillBody;

  /// No description provided for @todayDrillInBooks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s drill is in the books.'**
  String get todayDrillInBooks;

  /// No description provided for @todayOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'Open again'**
  String get todayOpenAgain;

  /// No description provided for @commonStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get commonStart;

  /// No description provided for @progressPerfectWeek.
  ///
  /// In en, this message translates to:
  /// **'Perfect week — all 7 days sealed 🔥'**
  String get progressPerfectWeek;

  /// No description provided for @progressDaysSealed.
  ///
  /// In en, this message translates to:
  /// **'{count} of 7 days sealed this week'**
  String progressDaysSealed(int count);

  /// No description provided for @progressWrongAnswersAllTime.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{wrong answer (all-time) · } other{wrong answers (all-time) · }}'**
  String progressWrongAnswersAllTime(int count);

  /// No description provided for @progressAttemptedAccuracy.
  ///
  /// In en, this message translates to:
  /// **'{attempted} attempted · {accuracy} accuracy'**
  String progressAttemptedAccuracy(int attempted, String accuracy);

  /// No description provided for @progressWrongAllTime.
  ///
  /// In en, this message translates to:
  /// **'{count} wrong (all-time)'**
  String progressWrongAllTime(int count);

  /// No description provided for @profileAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Current app version: {version}'**
  String profileAppVersion(String version);

  /// No description provided for @progressTabHistory.
  ///
  /// In en, this message translates to:
  /// **'Test History'**
  String get progressTabHistory;

  /// No description provided for @progressLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load overview.'**
  String get progressLoadFailed;

  /// No description provided for @progressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your performance across all subjects'**
  String get progressSubtitle;

  /// No description provided for @progressSubjectsPractised.
  ///
  /// In en, this message translates to:
  /// **' subjects practised'**
  String get progressSubjectsPractised;

  /// No description provided for @progressSortMostMistakes.
  ///
  /// In en, this message translates to:
  /// **'Most mistakes'**
  String get progressSortMostMistakes;

  /// No description provided for @progressNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get progressNotStarted;

  /// No description provided for @profileMadeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with love '**
  String get profileMadeWithLove;

  /// No description provided for @profileInDelhi.
  ///
  /// In en, this message translates to:
  /// **' in Delhi'**
  String get profileInDelhi;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get profileYourProfile;

  /// No description provided for @profileSignInPitch.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join the community, participate in battles, and build your profile.'**
  String get profileSignInPitch;

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get authSigningIn;

  /// No description provided for @authContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueApple;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoWebHint.
  ///
  /// In en, this message translates to:
  /// **'Profile photo can be changed in the Android or iOS app.'**
  String get profilePhotoWebHint;

  /// No description provided for @profileNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get profileNoEmail;

  /// No description provided for @profileAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get profileAuthentication;

  /// No description provided for @profileAccountConnected.
  ///
  /// In en, this message translates to:
  /// **'Account connected'**
  String get profileAccountConnected;

  /// No description provided for @profileDataSecure.
  ///
  /// In en, this message translates to:
  /// **'Your account data remains secure'**
  String get profileDataSecure;

  /// No description provided for @profileTelegramSlash.
  ///
  /// In en, this message translates to:
  /// **'Telegram username should not contain /'**
  String get profileTelegramSlash;

  /// No description provided for @profileInstagramSlash.
  ///
  /// In en, this message translates to:
  /// **'Instagram username should not contain /'**
  String get profileInstagramSlash;

  /// No description provided for @profileCommunityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Community profile updated'**
  String get profileCommunityUpdated;

  /// No description provided for @profileCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Profile'**
  String get profileCommunityTitle;

  /// No description provided for @profileCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Complete these fields so aspirants can connect with you.'**
  String get profileCommunityBody;

  /// No description provided for @profileOptionalSubject.
  ///
  /// In en, this message translates to:
  /// **'Optional Subject'**
  String get profileOptionalSubject;

  /// No description provided for @profileInstagramLabel.
  ///
  /// In en, this message translates to:
  /// **'Instagram (without @)'**
  String get profileInstagramLabel;

  /// No description provided for @profileTelegramLabel.
  ///
  /// In en, this message translates to:
  /// **'Telegram (without @)'**
  String get profileTelegramLabel;

  /// No description provided for @profileUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get profileUpdating;

  /// No description provided for @profileUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get profileUpdate;

  /// No description provided for @riskLower.
  ///
  /// In en, this message translates to:
  /// **'Lower risk'**
  String get riskLower;

  /// No description provided for @riskMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium risk'**
  String get riskMedium;

  /// No description provided for @riskHigher.
  ///
  /// In en, this message translates to:
  /// **'Higher risk'**
  String get riskHigher;

  /// No description provided for @testQuestionOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Q{current} of {total}'**
  String testQuestionOfTotal(int current, int total);

  /// No description provided for @historySessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String historySessionsCount(int count);

  /// No description provided for @historyScoreDone.
  ///
  /// In en, this message translates to:
  /// **'{score} done'**
  String historyScoreDone(String score);

  /// No description provided for @reviewCorrectWrong.
  ///
  /// In en, this message translates to:
  /// **'{correct} correct · {wrong} wrong'**
  String reviewCorrectWrong(int correct, int wrong);

  /// No description provided for @reviewQuestionOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String reviewQuestionOfTotal(int current, int total);

  /// No description provided for @testCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get testCorrect;

  /// No description provided for @testNotThisTime.
  ///
  /// In en, this message translates to:
  /// **'Not this time'**
  String get testNotThisTime;

  /// No description provided for @testHintCorrect.
  ///
  /// In en, this message translates to:
  /// **'The real learning is in the explanation — elimination, statement analysis, and the trap option.'**
  String get testHintCorrect;

  /// No description provided for @testHintWrong.
  ///
  /// In en, this message translates to:
  /// **'Read how to kill the other options — that\'s the real practice.'**
  String get testHintWrong;

  /// No description provided for @testShowExplanation.
  ///
  /// In en, this message translates to:
  /// **'Show explanation'**
  String get testShowExplanation;

  /// No description provided for @testConfidenceIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'From now on, let\'s also check how sure you are.'**
  String get testConfidenceIntroTitle;

  /// No description provided for @testConfidenceWhy.
  ///
  /// In en, this message translates to:
  /// **'Why? '**
  String get testConfidenceWhy;

  /// No description provided for @testConfidenceWhyBody.
  ///
  /// In en, this message translates to:
  /// **'To catch your confident mistakes.'**
  String get testConfidenceWhyBody;

  /// No description provided for @testHowSure.
  ///
  /// In en, this message translates to:
  /// **'How sure are you?'**
  String get testHowSure;

  /// No description provided for @testHowSureBody.
  ///
  /// In en, this message translates to:
  /// **'Pick before you see the answer — this builds your Danger Zone map.'**
  String get testHowSureBody;

  /// No description provided for @testLeaveDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave demo?'**
  String get testLeaveDemoTitle;

  /// No description provided for @testLeaveDemoBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be saved. Resume from Home when you\'re ready.'**
  String get testLeaveDemoBody;

  /// No description provided for @testLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get testLeave;

  /// No description provided for @testGoBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Go back?'**
  String get testGoBackTitle;

  /// No description provided for @testLeaveTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave test?'**
  String get testLeaveTestTitle;

  /// No description provided for @testGoBackBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? Your progress will be lost.'**
  String get testGoBackBody;

  /// No description provided for @testLeaveTestBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be saved and you can resume later.'**
  String get testLeaveTestBody;

  /// No description provided for @testGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get testGoBack;

  /// No description provided for @testSessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found'**
  String get testSessionNotFound;

  /// No description provided for @commonSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWrong;

  /// No description provided for @testSessionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load test session.'**
  String get testSessionLoadFailed;

  /// No description provided for @testTimerPausedNotice.
  ///
  /// In en, this message translates to:
  /// **'Timer paused while app was closed. Remaining time may not be accurate.'**
  String get testTimerPausedNotice;

  /// No description provided for @testBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get testBookmarked;

  /// No description provided for @testBookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get testBookmarkRemoved;

  /// No description provided for @testGridHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any number to jump to that question'**
  String get testGridHint;

  /// No description provided for @testGridCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get testGridCurrent;

  /// No description provided for @testGridAttempted.
  ///
  /// In en, this message translates to:
  /// **'Attempted'**
  String get testGridAttempted;

  /// No description provided for @testGridFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get testGridFlagged;

  /// No description provided for @testGridNotVisited.
  ///
  /// In en, this message translates to:
  /// **'Not visited'**
  String get testGridNotVisited;

  /// No description provided for @testGridSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get testGridSkipped;

  /// No description provided for @testSubmitTest.
  ///
  /// In en, this message translates to:
  /// **'Submit Test'**
  String get testSubmitTest;

  /// No description provided for @testSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get testSubmit;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @testPrev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get testPrev;

  /// No description provided for @testNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get testNext;

  /// No description provided for @demoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the demo test.'**
  String get demoLoadFailed;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get historyLoadFailed;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get historyEmpty;

  /// No description provided for @historyNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No sessions found'**
  String get historyNoneFound;

  /// No description provided for @historyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Complete a test to see your history here'**
  String get historyEmptyHint;

  /// No description provided for @historyChangeFilters.
  ///
  /// In en, this message translates to:
  /// **'Try changing your filters'**
  String get historyChangeFilters;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @historyAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get historyAbandoned;

  /// No description provided for @historyInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get historyInProgress;

  /// No description provided for @historyRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get historyRestart;

  /// No description provided for @reviewShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this test'**
  String get reviewShareTitle;

  /// No description provided for @reviewShareBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Share to send this question (or the whole test) to friends.\n\nFound an error in a question? Use Share to report it to the UPSC Wars developer.'**
  String get reviewShareBody;

  /// No description provided for @reviewQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'QUESTION'**
  String get reviewQuestionLabel;

  /// No description provided for @reviewPrevArrow.
  ///
  /// In en, this message translates to:
  /// **'← Prev'**
  String get reviewPrevArrow;

  /// No description provided for @reviewNextArrow.
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get reviewNextArrow;

  /// No description provided for @reviewRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get reviewRemoveBookmark;

  /// No description provided for @reviewInRevisionQueue.
  ///
  /// In en, this message translates to:
  /// **'In revision queue'**
  String get reviewInRevisionQueue;

  /// No description provided for @reviewAddToRevisionQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to revision queue'**
  String get reviewAddToRevisionQueue;

  /// No description provided for @reviewCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get reviewCorrectAnswer;

  /// No description provided for @reviewIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get reviewIncorrect;

  /// No description provided for @reviewTimesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up'**
  String get reviewTimesUp;

  /// No description provided for @reviewSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get reviewSkipped;

  /// No description provided for @reviewYourPick.
  ///
  /// In en, this message translates to:
  /// **'Your pick'**
  String get reviewYourPick;

  /// No description provided for @onbSublinePrefix.
  ///
  /// In en, this message translates to:
  /// **'We analyze every answer to '**
  String get onbSublinePrefix;

  /// No description provided for @onbSublinePhrase.
  ///
  /// In en, this message translates to:
  /// **'identify the topics that help or hurt'**
  String get onbSublinePhrase;

  /// No description provided for @onbSublineSuffix.
  ///
  /// In en, this message translates to:
  /// **' your score.'**
  String get onbSublineSuffix;

  /// No description provided for @onbFeatureExplanation.
  ///
  /// In en, this message translates to:
  /// **'Rich explanation'**
  String get onbFeatureExplanation;

  /// No description provided for @onbFeatureStatement.
  ///
  /// In en, this message translates to:
  /// **'Statement analysis'**
  String get onbFeatureStatement;

  /// No description provided for @onbFeatureElimination.
  ///
  /// In en, this message translates to:
  /// **'Elimination technique'**
  String get onbFeatureElimination;

  /// No description provided for @onbFeatureDistractor.
  ///
  /// In en, this message translates to:
  /// **'Strong distractor option'**
  String get onbFeatureDistractor;

  /// No description provided for @onbThesisEyebrow.
  ///
  /// In en, this message translates to:
  /// **'THE UPSC REALITY'**
  String get onbThesisEyebrow;

  /// No description provided for @onbConfidentWrong.
  ///
  /// In en, this message translates to:
  /// **'Confident\n& Wrong'**
  String get onbConfidentWrong;

  /// No description provided for @onbConfidentWrongBody.
  ///
  /// In en, this message translates to:
  /// **'Topics you are confident about and get wrong.'**
  String get onbConfidentWrongBody;

  /// No description provided for @onbGuessRight.
  ///
  /// In en, this message translates to:
  /// **'Guess\n& Right'**
  String get onbGuessRight;

  /// No description provided for @onbGuessRightBody.
  ///
  /// In en, this message translates to:
  /// **'Topics where your guesses are right more often.'**
  String get onbGuessRightBody;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next  →'**
  String get onbNext;

  /// No description provided for @onbLead.
  ///
  /// In en, this message translates to:
  /// **'Prelims isn\'t about knowing everything.'**
  String get onbLead;

  /// No description provided for @onbAccent.
  ///
  /// In en, this message translates to:
  /// **'UPSC Wars shows you where you stand.'**
  String get onbAccent;

  /// No description provided for @onbAvoidMistakes.
  ///
  /// In en, this message translates to:
  /// **'Avoid costly mistakes.'**
  String get onbAvoidMistakes;

  /// No description provided for @onbReviseTopics.
  ///
  /// In en, this message translates to:
  /// **'Revise these topics.'**
  String get onbReviseTopics;

  /// No description provided for @onbAttemptMore.
  ///
  /// In en, this message translates to:
  /// **'Attempt more from these topics'**
  String get onbAttemptMore;

  /// No description provided for @onbGainMarks.
  ///
  /// In en, this message translates to:
  /// **'Gain +ve marks.'**
  String get onbGainMarks;

  /// No description provided for @onbDepthEyebrow.
  ///
  /// In en, this message translates to:
  /// **'THE UPSC EDGE'**
  String get onbDepthEyebrow;

  /// No description provided for @onbDepthTitle.
  ///
  /// In en, this message translates to:
  /// **'Each question in\nUPSC Wars has:'**
  String get onbDepthTitle;

  /// No description provided for @aboutWhyBody.
  ///
  /// In en, this message translates to:
  /// **'I prepared for UPSC myself and realised that most aspirants solve thousands of MCQs but still don’t know where they are actually losing marks.\n\nSometimes the problem is not lack of knowledge — it is overconfidence, risky guessing, weak revision, and repeated mistakes.\n\nAt the same time, preparation is also about knowing where you can safely take smart risks and attempt more with confidence.\n\nThat is why I built UPSC Wars.'**
  String get aboutWhyBody;

  /// No description provided for @aboutGoalBody.
  ///
  /// In en, this message translates to:
  /// **'So your preparation becomes smarter, not just harder.\n\nMy goal is simple:\n\nHelp aspirants prepare like someone who clears Prelims.\n\nBuilt independently. No coaching institute. No big team. Just a serious attempt to make UPSC preparation better.'**
  String get aboutGoalBody;

  /// No description provided for @aboutConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Your feedback directly improves UPSC Wars.\n\nIf something feels missing, confusing, or useful, please message me. I read every feedback personally.\n\n📩 upscwars@gmail.com'**
  String get aboutConnectBody;

  /// No description provided for @aboutReviewBody.
  ///
  /// In en, this message translates to:
  /// **'If UPSC Wars helped your preparation, please leave a review.\n\nYour review helps more serious aspirants discover the app and helps improve the app faster.'**
  String get aboutReviewBody;

  /// No description provided for @aboutBullet1.
  ///
  /// In en, this message translates to:
  /// **'• Areas where Sure answers or educated guesses often go wrong\n'**
  String get aboutBullet1;

  /// No description provided for @aboutArrow1.
  ///
  /// In en, this message translates to:
  /// **'  → Avoid taking extra risks here\n\n'**
  String get aboutArrow1;

  /// No description provided for @aboutBullet2.
  ///
  /// In en, this message translates to:
  /// **'• Areas where Sure answers or educated guesses are usually correct\n'**
  String get aboutBullet2;

  /// No description provided for @aboutArrow2.
  ///
  /// In en, this message translates to:
  /// **'  → Take smarter risks here\n\n'**
  String get aboutArrow2;

  /// No description provided for @aboutBullet3.
  ///
  /// In en, this message translates to:
  /// **'• Common UPSC trap patterns and tricky question types\n'**
  String get aboutBullet3;

  /// No description provided for @aboutArrow3.
  ///
  /// In en, this message translates to:
  /// **'  → Stay alert and avoid negative marking'**
  String get aboutArrow3;

  /// No description provided for @aboutExAspirant.
  ///
  /// In en, this message translates to:
  /// **'(Ex-aspirant)'**
  String get aboutExAspirant;

  /// No description provided for @aboutWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why I Built UPSC Wars'**
  String get aboutWhyTitle;

  /// No description provided for @aboutHelpsFind.
  ///
  /// In en, this message translates to:
  /// **'It helps you find:'**
  String get aboutHelpsFind;

  /// No description provided for @aboutConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get aboutConnect;

  /// No description provided for @aboutReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get aboutReviews;

  /// No description provided for @aboutRateReview.
  ///
  /// In en, this message translates to:
  /// **'Rate/Review UPSC Wars'**
  String get aboutRateReview;

  /// No description provided for @aboutFeedbackEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback on Email'**
  String get aboutFeedbackEmail;

  /// No description provided for @aboutFeedbackTelegram.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback on Telegram'**
  String get aboutFeedbackTelegram;

  /// No description provided for @aboutLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get aboutLinkFailed;

  /// No description provided for @resultsAccuracyVsLast.
  ///
  /// In en, this message translates to:
  /// **'{sign}{value}% accuracy vs your last test'**
  String resultsAccuracyVsLast(String sign, int value);

  /// No description provided for @resultsMarksBreakdown.
  ///
  /// In en, this message translates to:
  /// **'+{earned} earned · {lost}'**
  String resultsMarksBreakdown(String earned, String lost);

  /// No description provided for @resultsZeroLost.
  ///
  /// In en, this message translates to:
  /// **'0 lost'**
  String get resultsZeroLost;

  /// No description provided for @resultsMarksLost.
  ///
  /// In en, this message translates to:
  /// **'−{value} lost'**
  String resultsMarksLost(String value);

  /// No description provided for @resultsAllQuestions.
  ///
  /// In en, this message translates to:
  /// **'All {total} questions'**
  String resultsAllQuestions(int total);

  /// No description provided for @resultsAttemptedSkipped.
  ///
  /// In en, this message translates to:
  /// **'{attempted} attempted · {skipped} skipped'**
  String resultsAttemptedSkipped(int attempted, int skipped);

  /// No description provided for @resultsCountCorrect.
  ///
  /// In en, this message translates to:
  /// **'{count} correct'**
  String resultsCountCorrect(int count);

  /// No description provided for @resultsCountWrong.
  ///
  /// In en, this message translates to:
  /// **'{count} wrong'**
  String resultsCountWrong(int count);

  /// No description provided for @resultsCountSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String resultsCountSkipped(int count);

  /// No description provided for @resultsCorrectOfAttempted.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {attempted} correct'**
  String resultsCorrectOfAttempted(int correct, int attempted);

  /// No description provided for @resultsAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question added to revision queue} other{{count} questions added to revision queue}}'**
  String resultsAddedToQueue(int count);

  /// No description provided for @resultsTotalInQueue.
  ///
  /// In en, this message translates to:
  /// **'{count} total in queue'**
  String resultsTotalInQueue(int count);

  /// No description provided for @resultsPctWrong.
  ///
  /// In en, this message translates to:
  /// **'{pct}% wrong ({wrong}/{attempted})'**
  String resultsPctWrong(int pct, int wrong, int attempted);

  /// No description provided for @resultsReviewAll.
  ///
  /// In en, this message translates to:
  /// **'Review all questions ({count})'**
  String resultsReviewAll(int count);

  /// No description provided for @resultsTimingLine.
  ///
  /// In en, this message translates to:
  /// **'Avg {avg}s per question · Fastest {min}s · Slowest {max}s'**
  String resultsTimingLine(int avg, int min, int max);

  /// No description provided for @resultsYourScore.
  ///
  /// In en, this message translates to:
  /// **'Your score: {pct}%'**
  String resultsYourScore(int pct);

  /// No description provided for @resultsNameYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String resultsNameYou(String name);

  /// No description provided for @resultsAttemptToEarn.
  ///
  /// In en, this message translates to:
  /// **'Attempt questions to earn marks'**
  String get resultsAttemptToEarn;

  /// No description provided for @resultsNetMarks.
  ///
  /// In en, this message translates to:
  /// **'Net marks'**
  String get resultsNetMarks;

  /// No description provided for @resultsNoneAttempted.
  ///
  /// In en, this message translates to:
  /// **'None attempted'**
  String get resultsNoneAttempted;

  /// No description provided for @resultsNoAttemptsYet.
  ///
  /// In en, this message translates to:
  /// **'No attempts yet'**
  String get resultsNoAttemptsYet;

  /// No description provided for @resultsAttemptAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Attempt accuracy'**
  String get resultsAttemptAccuracy;

  /// No description provided for @resultsNoneAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'No incorrect answers added from this test.'**
  String get resultsNoneAddedToQueue;

  /// No description provided for @resultsGoToQueue.
  ///
  /// In en, this message translates to:
  /// **'Go to queue'**
  String get resultsGoToQueue;

  /// No description provided for @resultsWorstTopics.
  ///
  /// In en, this message translates to:
  /// **'Most inaccurate topics'**
  String get resultsWorstTopics;

  /// No description provided for @resultsBestTopics.
  ///
  /// In en, this message translates to:
  /// **'Top topic accuracy'**
  String get resultsBestTopics;

  /// No description provided for @commonShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get commonShowLess;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonViewAll;

  /// No description provided for @resultsBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get resultsBackToHome;

  /// No description provided for @resultsMoreInsights.
  ///
  /// In en, this message translates to:
  /// **'More insights'**
  String get resultsMoreInsights;

  /// No description provided for @resultsAreYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get resultsAreYouSure;

  /// No description provided for @resultsReturnHome.
  ///
  /// In en, this message translates to:
  /// **'You will return to the home screen.'**
  String get resultsReturnHome;

  /// No description provided for @resultsGoToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get resultsGoToHome;

  /// No description provided for @resultsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load results'**
  String get resultsLoadFailed;

  /// No description provided for @resultsShareTest.
  ///
  /// In en, this message translates to:
  /// **'Share test'**
  String get resultsShareTest;

  /// No description provided for @resultsSessionSummary.
  ///
  /// In en, this message translates to:
  /// **'Session summary'**
  String get resultsSessionSummary;

  /// No description provided for @resultsTop5Shared.
  ///
  /// In en, this message translates to:
  /// **'Top 5 for this shared test'**
  String get resultsTop5Shared;

  /// No description provided for @resultsLeaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'It\'s empty.'**
  String get resultsLeaderboardEmpty;

  /// No description provided for @resultsLeaderboardFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load leaderboard.'**
  String get resultsLeaderboardFailed;

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get shareLinkCopied;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Test'**
  String get shareTitle;

  /// No description provided for @shareQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get shareQuestion;

  /// No description provided for @shareEntireTest.
  ///
  /// In en, this message translates to:
  /// **'Entire Test'**
  String get shareEntireTest;

  /// No description provided for @shareGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating link...'**
  String get shareGenerating;

  /// No description provided for @shareInfoFriends.
  ///
  /// In en, this message translates to:
  /// **'You can share this link with your friends.'**
  String get shareInfoFriends;

  /// No description provided for @shareInfoReport.
  ///
  /// In en, this message translates to:
  /// **'You can use this link to report any error in this question to the upsc wars team.'**
  String get shareInfoReport;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @shareContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get shareContactUs;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate link'**
  String get shareFailed;

  /// No description provided for @resultsReviewYourMistakes.
  ///
  /// In en, this message translates to:
  /// **'Review your mistakes'**
  String get resultsReviewYourMistakes;

  /// No description provided for @resultsRealExamCost.
  ///
  /// In en, this message translates to:
  /// **'Real exam cost: −{marks} marks'**
  String resultsRealExamCost(String marks);

  /// No description provided for @resultsTopRisk.
  ///
  /// In en, this message translates to:
  /// **'Top risk area: {topic}'**
  String resultsTopRisk(String topic);

  /// No description provided for @resultsTopRiskPct.
  ///
  /// In en, this message translates to:
  /// **'Top risk area: {topic} ({pct}% of your loss)'**
  String resultsTopRiskPct(String topic, int pct);

  /// No description provided for @resultsConfidentMistakesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Confident Mistake} other{{count} Confident Mistakes}}'**
  String resultsConfidentMistakesTitle(int count);

  /// No description provided for @resultsReviewConfidentCta.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Review 1 confident mistake} other{Review {count} confident mistakes}}'**
  String resultsReviewConfidentCta(int count);

  /// No description provided for @resultsEduMistakesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Educated Guess Mistake} other{{count} Educated Guess Mistakes}}'**
  String resultsEduMistakesTitle(int count);

  /// No description provided for @resultsReviewEduCta.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Review 1 educated guess} other{Review {count} educated guesses}}'**
  String resultsReviewEduCta(int count);

  /// No description provided for @resultsMixedMistakesTitle.
  ///
  /// In en, this message translates to:
  /// **'{sure} Confident · {edu} Educated guess'**
  String resultsMixedMistakesTitle(int sure, int edu);

  /// No description provided for @resultsIncompleteHeadline.
  ///
  /// In en, this message translates to:
  /// **'{attempted} of {total} attempted'**
  String resultsIncompleteHeadline(int attempted, int total);

  /// No description provided for @resultsLeftUnanswered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You left 1 question unanswered. Finish full tests for better insights.} other{You left {count} questions unanswered. Finish full tests for better insights.}}'**
  String resultsLeftUnanswered(int count);

  /// No description provided for @resultsQrMixed.
  ///
  /// In en, this message translates to:
  /// **'You lost marks on {total} questions — some you were sure about'**
  String resultsQrMixed(int total);

  /// No description provided for @resultsQrSure.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You lost marks on 1 question — you were sure about it} other{You lost marks on {count} questions — you were sure about them}}'**
  String resultsQrSure(int count);

  /// No description provided for @resultsQrEdu.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You lost marks on 1 question — your educated guess didn\'\'t pay off} other{You lost marks on {count} questions — your educated guess didn\'\'t pay off}}'**
  String resultsQrEdu(int count);

  /// No description provided for @resultsCaseASubtitle.
  ///
  /// In en, this message translates to:
  /// **'You were sure, but incorrect. These are rank killers.'**
  String get resultsCaseASubtitle;

  /// No description provided for @resultsCaseBSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your elimination strategy failed more often than it worked.'**
  String get resultsCaseBSubtitle;

  /// No description provided for @resultsCaseCSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You lost marks from both overconfidence and risky elimination.'**
  String get resultsCaseCSubtitle;

  /// No description provided for @resultsCaseDSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong answers were pure guesses. You still lost marks worth reviewing.'**
  String get resultsCaseDSubtitle;

  /// No description provided for @resultsNoConfidentMistakes.
  ///
  /// In en, this message translates to:
  /// **'No confident mistakes'**
  String get resultsNoConfidentMistakes;

  /// No description provided for @resultsExcellentEyebrow.
  ///
  /// In en, this message translates to:
  /// **'EXCELLENT SESSION'**
  String get resultsExcellentEyebrow;

  /// No description provided for @resultsCaseESubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you were confident, you stayed accurate. Keep the momentum.'**
  String get resultsCaseESubtitle;

  /// No description provided for @resultsExcellentTitle.
  ///
  /// In en, this message translates to:
  /// **'Excellent session'**
  String get resultsExcellentTitle;

  /// No description provided for @resultsPracticeMore.
  ///
  /// In en, this message translates to:
  /// **'Practice more'**
  String get resultsPracticeMore;

  /// No description provided for @resultsCaseFSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You left questions unanswered. Finish full tests for better insights.'**
  String get resultsCaseFSubtitle;

  /// No description provided for @resultsIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Incomplete session'**
  String get resultsIncompleteTitle;

  /// No description provided for @resultsLockedEyebrow.
  ///
  /// In en, this message translates to:
  /// **'INSIGHTS LOCKED'**
  String get resultsLockedEyebrow;

  /// No description provided for @resultsCaseGSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable confidence tracking to unlock personalised insights.'**
  String get resultsCaseGSubtitle;

  /// No description provided for @resultsLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights locked'**
  String get resultsLockedTitle;

  /// No description provided for @resultsEnableTracking.
  ///
  /// In en, this message translates to:
  /// **'Enable confidence tracking'**
  String get resultsEnableTracking;

  /// No description provided for @resultsCaseHSubtitle.
  ///
  /// In en, this message translates to:
  /// **'As this test was attempted without marking confidence.'**
  String get resultsCaseHSubtitle;

  /// No description provided for @resultsInsightsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Confidence insights not available'**
  String get resultsInsightsUnavailable;

  /// No description provided for @resultsRetryWithConfidence.
  ///
  /// In en, this message translates to:
  /// **'Retry with confidence marking'**
  String get resultsRetryWithConfidence;

  /// No description provided for @resultsCaseISubtitle.
  ///
  /// In en, this message translates to:
  /// **'You submitted without answering any questions. Try again when you are ready.'**
  String get resultsCaseISubtitle;

  /// No description provided for @resultsNoQuestionsAttempted.
  ///
  /// In en, this message translates to:
  /// **'No questions attempted'**
  String get resultsNoQuestionsAttempted;

  /// No description provided for @resultsRetryTest.
  ///
  /// In en, this message translates to:
  /// **'Retry test'**
  String get resultsRetryTest;

  /// No description provided for @resultsFinishMore.
  ///
  /// In en, this message translates to:
  /// **'Finish more of the test before calling it a clean session.'**
  String get resultsFinishMore;

  /// No description provided for @resultsQrTitle.
  ///
  /// In en, this message translates to:
  /// **'QUESTIONS TO REVIEW'**
  String get resultsQrTitle;

  /// No description provided for @resultsQrReveal.
  ///
  /// In en, this message translates to:
  /// **'These questions may reveal:'**
  String get resultsQrReveal;

  /// No description provided for @resultsQrBullet1.
  ///
  /// In en, this message translates to:
  /// **'Concepts that feel familiar but aren\'t fully clear'**
  String get resultsQrBullet1;

  /// No description provided for @resultsQrBullet2.
  ///
  /// In en, this message translates to:
  /// **'Topics where the detail matters and you missed it'**
  String get resultsQrBullet2;

  /// No description provided for @resultsQrBullet3.
  ///
  /// In en, this message translates to:
  /// **'Avoidable exam-day mistakes'**
  String get resultsQrBullet3;

  /// No description provided for @resultsYouWere.
  ///
  /// In en, this message translates to:
  /// **'You were {label}'**
  String resultsYouWere(String label);

  /// No description provided for @resultsNoTierItems.
  ///
  /// In en, this message translates to:
  /// **'No {label} items'**
  String resultsNoTierItems(String label);

  /// No description provided for @resultsWithOutcome.
  ///
  /// In en, this message translates to:
  /// **' with outcome “{outcome}”'**
  String resultsWithOutcome(String outcome);

  /// No description provided for @resultsNoTierBody.
  ///
  /// In en, this message translates to:
  /// **'No scored questions in this session were logged under “{label}”{outcome}.'**
  String resultsNoTierBody(String label, String outcome);

  /// No description provided for @resultsWrongOnly.
  ///
  /// In en, this message translates to:
  /// **' · Wrong only'**
  String get resultsWrongOnly;

  /// No description provided for @resultsCorrectOnly.
  ///
  /// In en, this message translates to:
  /// **' · Correct only'**
  String get resultsCorrectOnly;

  /// No description provided for @resultsLoggedAs.
  ///
  /// In en, this message translates to:
  /// **'Logged as: {tier}{suffix}'**
  String resultsLoggedAs(String tier, String suffix);

  /// No description provided for @resultsLostMarksOn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You lost marks on 1 question} other{You lost marks on {count} questions}}'**
  String resultsLostMarksOn(int count);

  /// No description provided for @resultsWatchOutFor.
  ///
  /// In en, this message translates to:
  /// **'Watch out for:'**
  String get resultsWatchOutFor;

  /// No description provided for @resultsEyebrowSureWrong.
  ///
  /// In en, this message translates to:
  /// **'CONFIDENT · WRONG'**
  String get resultsEyebrowSureWrong;

  /// No description provided for @resultsSureDesc.
  ///
  /// In en, this message translates to:
  /// **'You were sure — and lost marks anyway. \n\nGo through these carefully and check whether you misread the question or your understanding has a gap.'**
  String get resultsSureDesc;

  /// No description provided for @resultsSureBullet3.
  ///
  /// In en, this message translates to:
  /// **'Traps that feel obvious in hindsight'**
  String get resultsSureBullet3;

  /// No description provided for @resultsEyebrowEduWrong.
  ///
  /// In en, this message translates to:
  /// **'EDUCATED GUESS · WRONG'**
  String get resultsEyebrowEduWrong;

  /// No description provided for @resultsEduDesc.
  ///
  /// In en, this message translates to:
  /// **'You had some idea but not enough. These are clean gaps — easier to fix than confident mistakes. You know you need to revise these.'**
  String get resultsEduDesc;

  /// No description provided for @resultsEduBullet1.
  ///
  /// In en, this message translates to:
  /// **'Topics that need focused revision'**
  String get resultsEduBullet1;

  /// No description provided for @resultsEduBullet2.
  ///
  /// In en, this message translates to:
  /// **'Concepts partially encountered but not fully absorbed'**
  String get resultsEduBullet2;

  /// No description provided for @resultsEduBullet3.
  ///
  /// In en, this message translates to:
  /// **'Areas where elimination logic needs strengthening'**
  String get resultsEduBullet3;

  /// No description provided for @resultsReviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load review'**
  String get resultsReviewLoadFailed;

  /// No description provided for @resultsNoDangerItems.
  ///
  /// In en, this message translates to:
  /// **'No Danger Zone items'**
  String get resultsNoDangerItems;

  /// No description provided for @resultsNoDangerBody.
  ///
  /// In en, this message translates to:
  /// **'Wrong answers without a confidence pick, or where you marked \"Pure guess\", do not appear here.'**
  String get resultsNoDangerBody;

  /// No description provided for @resultsInvalidFilter.
  ///
  /// In en, this message translates to:
  /// **'Invalid confidence filter.'**
  String get resultsInvalidFilter;

  /// No description provided for @resultsNoReviewable.
  ///
  /// In en, this message translates to:
  /// **'No reviewable mistakes in this session.'**
  String get resultsNoReviewable;

  /// No description provided for @resultsReviewLoadFailedDot.
  ///
  /// In en, this message translates to:
  /// **'Could not load review.'**
  String get resultsReviewLoadFailedDot;

  /// No description provided for @resultsSureWrongSeg.
  ///
  /// In en, this message translates to:
  /// **'Sure + wrong'**
  String get resultsSureWrongSeg;

  /// No description provided for @resultsEduWrongSeg.
  ///
  /// In en, this message translates to:
  /// **'Edu guess + wrong'**
  String get resultsEduWrongSeg;

  /// No description provided for @resultsReviewConfidentMistakes.
  ///
  /// In en, this message translates to:
  /// **'Review confident mistakes'**
  String get resultsReviewConfidentMistakes;

  /// No description provided for @resultsSwipeBoth.
  ///
  /// In en, this message translates to:
  /// **'Swipe to see both types'**
  String get resultsSwipeBoth;

  /// No description provided for @resultsStartReview.
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get resultsStartReview;

  /// No description provided for @resultsUnlockMapBody.
  ///
  /// In en, this message translates to:
  /// **'You did not log confidence on any of your {answered} scored questions. After each answer, use the three chips under your chosen option — it takes one tap and powers Danger Zone, accuracy by tier, and smarter revision hints.'**
  String resultsUnlockMapBody(int answered);

  /// No description provided for @resultsLogMoreBody.
  ///
  /// In en, this message translates to:
  /// **'You tagged {logged} of {answered} scored questions ({pct}%). Aim for at least half — the more you log, the sharper your insights get.'**
  String resultsLogMoreBody(int logged, int answered, String pct);

  /// No description provided for @resultsSureWarn.
  ///
  /// In en, this message translates to:
  /// **'When you tapped Sure, you were right {pct}% of the time ({correct} / {total}). Aim for about 75%+ on high-conviction picks before Prelims.'**
  String resultsSureWarn(String pct, int correct, int total);

  /// No description provided for @resultsSureOk.
  ///
  /// In en, this message translates to:
  /// **'Sure-tier accuracy {pct}% ({correct} / {total}). That is in a healthy range for conviction answers.'**
  String resultsSureOk(String pct, int correct, int total);

  /// No description provided for @resultsMatrixHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a cell to review those questions only (same session).'**
  String get resultsMatrixHint;

  /// No description provided for @resultsUnlockMap.
  ///
  /// In en, this message translates to:
  /// **'Unlock this map next time'**
  String get resultsUnlockMap;

  /// No description provided for @resultsLogMore.
  ///
  /// In en, this message translates to:
  /// **'Log a bit more next round'**
  String get resultsLogMore;

  /// No description provided for @resultsMatrixCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get resultsMatrixCorrect;

  /// No description provided for @resultsMatrixWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get resultsMatrixWrong;

  /// No description provided for @resultsCoverageHint.
  ///
  /// In en, this message translates to:
  /// **'Questions where you tapped Sure, Educated guess, or Pure guess after answering.'**
  String get resultsCoverageHint;

  /// No description provided for @resultsCoachMistakesTitle.
  ///
  /// In en, this message translates to:
  /// **'Review only your mistakes'**
  String get resultsCoachMistakesTitle;

  /// No description provided for @resultsCoachMistakesBody.
  ///
  /// In en, this message translates to:
  /// **'Just the questions you got wrong — the ones worth going back to.'**
  String get resultsCoachMistakesBody;

  /// No description provided for @resultsCoachAllOr.
  ///
  /// In en, this message translates to:
  /// **'Or review all questions'**
  String get resultsCoachAllOr;

  /// No description provided for @resultsCoachAll.
  ///
  /// In en, this message translates to:
  /// **'Review all questions'**
  String get resultsCoachAll;

  /// No description provided for @resultsCoachAllBody.
  ///
  /// In en, this message translates to:
  /// **'The full paper, including the ones you got right.'**
  String get resultsCoachAllBody;

  /// No description provided for @resultsCoachTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'You don’t have to remember this'**
  String get resultsCoachTopicsTitle;

  /// No description provided for @resultsCoachTopicsBody.
  ///
  /// In en, this message translates to:
  /// **'The same weak and strong topic lists live on every subject. Open a subject from Home anytime.'**
  String get resultsCoachTopicsBody;

  /// No description provided for @resultsCoachGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get resultsCoachGotIt;

  /// No description provided for @resultsCoachNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get resultsCoachNext;

  /// No description provided for @commonQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String commonQuestionCount(int count);

  /// No description provided for @bookmarksSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String bookmarksSavedCount(int count);

  /// No description provided for @revisionStartSession.
  ///
  /// In en, this message translates to:
  /// **'Start revision session'**
  String get revisionStartSession;

  /// No description provided for @revisionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your revision queue is empty'**
  String get revisionEmptyTitle;

  /// No description provided for @revisionEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Questions you get wrong or bookmark will appear here'**
  String get revisionEmptyBody;

  /// No description provided for @revisionNoItemsSubject.
  ///
  /// In en, this message translates to:
  /// **'No items for this subject.'**
  String get revisionNoItemsSubject;

  /// No description provided for @revisionMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get revisionMastered;

  /// No description provided for @revisionInQueue.
  ///
  /// In en, this message translates to:
  /// **'In queue'**
  String get revisionInQueue;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @bookmarksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get bookmarksEmptyTitle;

  /// No description provided for @bookmarksEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Bookmark questions during a test to save them here'**
  String get bookmarksEmptyBody;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @trapsCatalogCount.
  ///
  /// In en, this message translates to:
  /// **'{count} UPSC traps'**
  String trapsCatalogCount(int count);

  /// No description provided for @trapsCaughtOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{caught} of {total} have caught you'**
  String trapsCaughtOfTotal(int caught, int total);

  /// No description provided for @weakGroupSummary.
  ///
  /// In en, this message translates to:
  /// **'{questions} · got wrong {times}'**
  String weakGroupSummary(String questions, String times);

  /// No description provided for @commonTimesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String commonTimesCount(int count);

  /// No description provided for @trapsCaughtByThis.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question caught by this trap} other{{count} questions caught by this trap}}'**
  String trapsCaughtByThis(int count);

  /// No description provided for @weakNeedMore.
  ///
  /// In en, this message translates to:
  /// **'Attempt more questions to start seeing your weak areas for {subject}'**
  String weakNeedMore(String subject);

  /// No description provided for @trapsCaughtCount.
  ///
  /// In en, this message translates to:
  /// **'Caught you {count}×'**
  String trapsCaughtCount(int count);

  /// No description provided for @topicInRevisionQueue.
  ///
  /// In en, this message translates to:
  /// **'{count} in revision queue'**
  String topicInRevisionQueue(int count);

  /// No description provided for @topicDangerLine.
  ///
  /// In en, this message translates to:
  /// **'Sure wrong: {sure} · Educated guess wrong: {edu} (all-time)'**
  String topicDangerLine(int sure, int edu);

  /// No description provided for @topicSeasonDangerLine.
  ///
  /// In en, this message translates to:
  /// **'Sure wrong {sure} · Educated guess wrong {edu}'**
  String topicSeasonDangerLine(int sure, int edu);

  /// No description provided for @topicSortDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get topicSortDanger;

  /// No description provided for @subjectTestInfo.
  ///
  /// In en, this message translates to:
  /// **'{questions} questions · {topics} topics'**
  String subjectTestInfo(String questions, int topics);

  /// No description provided for @pyqNoQuestionsYear.
  ///
  /// In en, this message translates to:
  /// **'No questions are available for {year} yet.'**
  String pyqNoQuestionsYear(String year);

  /// No description provided for @pyqSetOf.
  ///
  /// In en, this message translates to:
  /// **'Set {n} of {total}'**
  String pyqSetOf(int n, int total);

  /// No description provided for @pyqFixedOrder.
  ///
  /// In en, this message translates to:
  /// **'{count} questions (fixed order for this set)'**
  String pyqFixedOrder(int count);

  /// No description provided for @pyqTestN.
  ///
  /// In en, this message translates to:
  /// **'Test {n}'**
  String pyqTestN(int n);

  /// No description provided for @pyqQuestionsRange.
  ///
  /// In en, this message translates to:
  /// **'Questions {from}–{to}'**
  String pyqQuestionsRange(int from, int to);

  /// No description provided for @notifLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load message.\n{error}'**
  String notifLoadFailed(String error);

  /// No description provided for @trapsNoCatalog.
  ///
  /// In en, this message translates to:
  /// **'No trap catalog yet'**
  String get trapsNoCatalog;

  /// No description provided for @commonNoDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get commonNoDataFound;

  /// No description provided for @weakPracticeSubtopic.
  ///
  /// In en, this message translates to:
  /// **'Practice This Sub-topic'**
  String get weakPracticeSubtopic;

  /// No description provided for @weakPracticeTrap.
  ///
  /// In en, this message translates to:
  /// **'Practice This Trap Type'**
  String get weakPracticeTrap;

  /// No description provided for @trapsCaughtZero.
  ///
  /// In en, this message translates to:
  /// **'Caught you 0× — not enough data yet'**
  String get trapsCaughtZero;

  /// No description provided for @trapsSeeExample.
  ///
  /// In en, this message translates to:
  /// **'See example'**
  String get trapsSeeExample;

  /// No description provided for @weakLegend.
  ///
  /// In en, this message translates to:
  /// **'Accuracy = % correct among attempted questions in the topic.\nAttempt = % of topic questions you have attempted.'**
  String get weakLegend;

  /// No description provided for @trapsExampleEyebrow.
  ///
  /// In en, this message translates to:
  /// **'EXAMPLE'**
  String get trapsExampleEyebrow;

  /// No description provided for @trapsExampleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load an example.'**
  String get trapsExampleLoadFailed;

  /// No description provided for @trapsNoExample.
  ///
  /// In en, this message translates to:
  /// **'No example written for this trap yet.'**
  String get trapsNoExample;

  /// No description provided for @trapsSpotted.
  ///
  /// In en, this message translates to:
  /// **'You spotted it.'**
  String get trapsSpotted;

  /// No description provided for @trapsThatsTheTrap.
  ///
  /// In en, this message translates to:
  /// **'That\'s the trap.'**
  String get trapsThatsTheTrap;

  /// No description provided for @trapsTrackingNote.
  ///
  /// In en, this message translates to:
  /// **'We keep track of which traps catch you most, so you can watch for them in the exam.'**
  String get trapsTrackingNote;

  /// No description provided for @topicSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search topics...'**
  String get topicSearchHint;

  /// No description provided for @topicNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No topics match your search.'**
  String get topicNoMatch;

  /// No description provided for @topicLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load topics.'**
  String get topicLoadFailed;

  /// No description provided for @subjectTestChooseBattle.
  ///
  /// In en, this message translates to:
  /// **'Choose a subject to start battle'**
  String get subjectTestChooseBattle;

  /// No description provided for @subjectTestChooseBegin.
  ///
  /// In en, this message translates to:
  /// **'Choose a subject to begin'**
  String get subjectTestChooseBegin;

  /// No description provided for @subjectTestStartBattle.
  ///
  /// In en, this message translates to:
  /// **'Start battle'**
  String get subjectTestStartBattle;

  /// No description provided for @subjectTestLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subjects.'**
  String get subjectTestLoadFailed;

  /// No description provided for @pyqLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load PYQ sets'**
  String get pyqLoadFailed;

  /// No description provided for @commonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get commonCompleted;

  /// No description provided for @notifScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notifScreenTitle;

  /// No description provided for @notifNoAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'No announcement is available right now.'**
  String get notifNoAnnouncement;

  /// No description provided for @notifEmptyAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'This announcement is empty.'**
  String get notifEmptyAnnouncement;

  /// No description provided for @topicsAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{· 1 attempt} other{· {count} attempts}}'**
  String topicsAttempts(int count);

  /// No description provided for @commonDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String commonDaysAgo(int count);

  /// No description provided for @subjCorrectOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{correct}/{total} correct · {pct}%'**
  String subjCorrectOfTotal(int correct, int total, String pct);

  /// No description provided for @subjQuestionsPlain.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String subjQuestionsPlain(int count);

  /// No description provided for @dzStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start session: {error}'**
  String dzStartFailed(String error);

  /// No description provided for @dzTitleOf.
  ///
  /// In en, this message translates to:
  /// **'Danger zone of {label}'**
  String dzTitleOf(String label);

  /// No description provided for @dzTotalLine.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} wrong · about {marks} marks lost (0.66 per wrong answer)'**
  String dzTotalLine(int count, String marks);

  /// No description provided for @dzApproxMarks.
  ///
  /// In en, this message translates to:
  /// **'≈ {marks} marks'**
  String dzApproxMarks(String marks);

  /// No description provided for @subjAllTopicsIn.
  ///
  /// In en, this message translates to:
  /// **'Questions from all topics in {subject}'**
  String subjAllTopicsIn(String subject);

  /// No description provided for @subjPracticeTopicsCount.
  ///
  /// In en, this message translates to:
  /// **'Practice specific topics ({count} topics)'**
  String subjPracticeTopicsCount(int count);

  /// No description provided for @subjCompletedSessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 completed session} other{{count} completed sessions}}'**
  String subjCompletedSessions(int count);

  /// No description provided for @commonWrongLower.
  ///
  /// In en, this message translates to:
  /// **'wrong'**
  String get commonWrongLower;

  /// No description provided for @subjTopicOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open topic: {error}'**
  String subjTopicOpenFailed(String error);

  /// No description provided for @subjAdviceFor.
  ///
  /// In en, this message translates to:
  /// **'ADVICE FOR {subject}'**
  String subjAdviceFor(String subject);

  /// No description provided for @subjSureEduWrong.
  ///
  /// In en, this message translates to:
  /// **'Sure wrong: {sure} · Edu guess wrong: {edu}'**
  String subjSureEduWrong(int sure, int edu);

  /// No description provided for @subjConfidentRate.
  ///
  /// In en, this message translates to:
  /// **'When confident: {rate}% right · vs {global}% overall'**
  String subjConfidentRate(String rate, String global);

  /// No description provided for @subjHistLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load history.'**
  String get subjHistLoadFailed;

  /// No description provided for @subjHistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed sessions yet.'**
  String get subjHistEmptyTitle;

  /// No description provided for @subjHistEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start a test to see your results here.'**
  String get subjHistEmptyBody;

  /// No description provided for @subjStartTest.
  ///
  /// In en, this message translates to:
  /// **'Start a test'**
  String get subjStartTest;

  /// No description provided for @commonLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get commonLoadMore;

  /// No description provided for @topicsNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get topicsNotStarted;

  /// No description provided for @topicsNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No topics found for this subject.'**
  String get topicsNoneFound;

  /// No description provided for @topicsBankInstalling.
  ///
  /// In en, this message translates to:
  /// **'If your question bank is still installing, go back and try again in a moment.'**
  String get topicsBankInstalling;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @subjModeLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get subjModeLearning;

  /// No description provided for @subjModeExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get subjModeExam;

  /// No description provided for @dzNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions in this category.'**
  String get dzNoQuestions;

  /// No description provided for @dzSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong answers with Sure or Educated-guess (all-time)'**
  String get dzSubtitle;

  /// No description provided for @dzCalm.
  ///
  /// In en, this message translates to:
  /// **'No Sure or Educated-guess wrong answers yet.'**
  String get dzCalm;

  /// No description provided for @dzSureWrong.
  ///
  /// In en, this message translates to:
  /// **'Sure — wrong'**
  String get dzSureWrong;

  /// No description provided for @dzSureWrongBody.
  ///
  /// In en, this message translates to:
  /// **'You marked Sure and answered incorrectly.'**
  String get dzSureWrongBody;

  /// No description provided for @dzEduWrong.
  ///
  /// In en, this message translates to:
  /// **'Educated guess — wrong'**
  String get dzEduWrong;

  /// No description provided for @dzEduWrongBody.
  ///
  /// In en, this message translates to:
  /// **'You marked Educated guess and answered incorrectly.'**
  String get dzEduWrongBody;

  /// No description provided for @commonRevise.
  ///
  /// In en, this message translates to:
  /// **'Revise'**
  String get commonRevise;

  /// No description provided for @topicSheetNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions in this topic right now.'**
  String get topicSheetNoQuestions;

  /// No description provided for @topicSheetInsights.
  ///
  /// In en, this message translates to:
  /// **'INSIGHTS'**
  String get topicSheetInsights;

  /// No description provided for @topicSheetDzFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load Danger zone.'**
  String get topicSheetDzFailed;

  /// No description provided for @mockReviseTitle.
  ///
  /// In en, this message translates to:
  /// **'Revise Before Your Next Mock'**
  String get mockReviseTitle;

  /// No description provided for @mockReviseWhy.
  ///
  /// In en, this message translates to:
  /// **'These are topics where your Sure + Incorrect and Educated Guess + Incorrect are higher than your usual average.'**
  String get mockReviseWhy;

  /// No description provided for @mockWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get mockWhatToDo;

  /// No description provided for @mockReviseAction.
  ///
  /// In en, this message translates to:
  /// **'Revise these topics from your notes first before your next mock to reduce costly mistakes and improve your score.'**
  String get mockReviseAction;

  /// No description provided for @mockSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe Areas for Higher Attempts'**
  String get mockSafeTitle;

  /// No description provided for @mockSafeWhy.
  ///
  /// In en, this message translates to:
  /// **'These are topics where your Sure + Correct and Educated Guess + Correct are better than your usual average.'**
  String get mockSafeWhy;

  /// No description provided for @mockSafeAction.
  ///
  /// In en, this message translates to:
  /// **'Be more confident while attempting questions from these topics in mocks and exams.'**
  String get mockSafeAction;

  /// No description provided for @mockMoreClarity.
  ///
  /// In en, this message translates to:
  /// **'Want further clarity? '**
  String get mockMoreClarity;

  /// No description provided for @subjFeedbackLead.
  ///
  /// In en, this message translates to:
  /// **'Any questions or feedback?\n'**
  String get subjFeedbackLead;

  /// No description provided for @subjGetInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get subjGetInTouch;

  /// No description provided for @subjBrowseTopicsLower.
  ///
  /// In en, this message translates to:
  /// **'Browse topics'**
  String get subjBrowseTopicsLower;

  /// No description provided for @subjNewTestBody.
  ///
  /// In en, this message translates to:
  /// **'Start a test or practice specific topics.'**
  String get subjNewTestBody;

  /// No description provided for @subjStartAndMark.
  ///
  /// In en, this message translates to:
  /// **'Start a test and mark confidence to see your insights'**
  String get subjStartAndMark;

  /// No description provided for @subjBrowseTopics.
  ///
  /// In en, this message translates to:
  /// **'Browse Topics'**
  String get subjBrowseTopics;

  /// No description provided for @subjPracticeTopics.
  ///
  /// In en, this message translates to:
  /// **'Practice specific topics'**
  String get subjPracticeTopics;

  /// No description provided for @subjHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'List of Completed sessions for this subject.'**
  String get subjHistoryBody;

  /// No description provided for @subjSessionCountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load session count.'**
  String get subjSessionCountFailed;

  /// No description provided for @subjViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View test history'**
  String get subjViewHistory;

  /// No description provided for @subjNoSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No completed sessions yet'**
  String get subjNoSessionsYet;

  /// No description provided for @subjStatsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subject stats.'**
  String get subjStatsFailed;

  /// No description provided for @subjMarkHint.
  ///
  /// In en, this message translates to:
  /// **'Mark Sure or Educated guess when you answer scored questions in this subject — mock-prep advice and your confidence breakdown will appear here.'**
  String get subjMarkHint;

  /// No description provided for @subjStatsSharpen.
  ///
  /// In en, this message translates to:
  /// **'More scored answers with confidence labels sharpen these stats.'**
  String get subjStatsSharpen;

  /// No description provided for @subjNoAttemptsYet.
  ///
  /// In en, this message translates to:
  /// **'No attempted answers yet.\nStart a test and mark confidence to see your insights'**
  String get subjNoAttemptsYet;

  /// No description provided for @subjAccuracySuffix.
  ///
  /// In en, this message translates to:
  /// **' accuracy'**
  String get subjAccuracySuffix;

  /// No description provided for @subjMcqsAttempted.
  ///
  /// In en, this message translates to:
  /// **' MCQs attempted'**
  String get subjMcqsAttempted;

  /// No description provided for @subjSureNone.
  ///
  /// In en, this message translates to:
  /// **'Sure → wrong: — (no Sure-marked answers yet)'**
  String get subjSureNone;

  /// No description provided for @subjGuessNone.
  ///
  /// In en, this message translates to:
  /// **'Educated guess → wrong: — (no Educated-guess answers yet)'**
  String get subjGuessNone;

  /// No description provided for @subjBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Your confidence breakdown in this subject'**
  String get subjBreakdownTitle;

  /// No description provided for @subjNoConfidentWrongs.
  ///
  /// In en, this message translates to:
  /// **'No confident wrongs to analyse yet'**
  String get subjNoConfidentWrongs;

  /// No description provided for @subjReviseQuestions.
  ///
  /// In en, this message translates to:
  /// **'Revise these questions'**
  String get subjReviseQuestions;

  /// No description provided for @subjTopicNotFound.
  ///
  /// In en, this message translates to:
  /// **'Topic not found in catalog.'**
  String get subjTopicNotFound;

  /// No description provided for @subjReviseMcqs.
  ///
  /// In en, this message translates to:
  /// **'Revise MCQs'**
  String get subjReviseMcqs;

  /// No description provided for @subjAdviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where to revise vs where to attempt more'**
  String get subjAdviceSubtitle;

  /// No description provided for @subjAdviceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start attempting MCQs with marking confidence to see advices and insights here'**
  String get subjAdviceEmpty;

  /// No description provided for @subjReviseTopicsIntro.
  ///
  /// In en, this message translates to:
  /// **'You are likely to lose marks in these topics due to overconfidence and risky guessing.'**
  String get subjReviseTopicsIntro;

  /// No description provided for @subjTopicsToRevise.
  ///
  /// In en, this message translates to:
  /// **'Topics to revise'**
  String get subjTopicsToRevise;

  /// No description provided for @subjNoTopicsToList.
  ///
  /// In en, this message translates to:
  /// **'No topics to list'**
  String get subjNoTopicsToList;

  /// No description provided for @subjNoTopicsBody.
  ///
  /// In en, this message translates to:
  /// **'No topic in this subject has enough wrong answers marked “Sure” or “Educated guess” to show here yet. As that pattern shows up, you will see it broken down by type of confidence.'**
  String get subjNoTopicsBody;

  /// No description provided for @subjWhyTopics.
  ///
  /// In en, this message translates to:
  /// **'Why these topics?'**
  String get subjWhyTopics;

  /// No description provided for @subjRevisitTopic.
  ///
  /// In en, this message translates to:
  /// **'Revisit this topic'**
  String get subjRevisitTopic;

  /// No description provided for @subjSafeIntro.
  ///
  /// In en, this message translates to:
  /// **'You can trust your judgment more in these topics. Attempt more from here in mocks and exams.'**
  String get subjSafeIntro;

  /// No description provided for @subjSafeTopics.
  ///
  /// In en, this message translates to:
  /// **'Safe scoring topics'**
  String get subjSafeTopics;

  /// No description provided for @subjBaselineNotReady.
  ///
  /// In en, this message translates to:
  /// **'Baseline not ready'**
  String get subjBaselineNotReady;

  /// No description provided for @subjNoTopicsQualify.
  ///
  /// In en, this message translates to:
  /// **'No topics qualify yet'**
  String get subjNoTopicsQualify;

  /// No description provided for @subjBaselineBody.
  ///
  /// In en, this message translates to:
  /// **'We need a solid sample of scored answers where you were very or somewhat sure. Keep using confidence on tests so we can set your global rate and list topics that beat it.'**
  String get subjBaselineBody;

  /// No description provided for @subjNoQualifyBody.
  ///
  /// In en, this message translates to:
  /// **'In this subject, no topic is clearly above your overall confident-correct rate yet. The list will update as you add more very sure or somewhat sure attempts.'**
  String get subjNoQualifyBody;

  /// No description provided for @subjAttemptMore.
  ///
  /// In en, this message translates to:
  /// **'Attempt more'**
  String get subjAttemptMore;

  /// No description provided for @subjMockPrepFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load mock-prep tips.'**
  String get subjMockPrepFailed;

  /// No description provided for @subjInsightsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load insights.'**
  String get subjInsightsFailed;

  /// No description provided for @notifPaperBody.
  ///
  /// In en, this message translates to:
  /// **'{count} MCQs from the news you just read'**
  String notifPaperBody(int count);

  /// No description provided for @notifPaperBodyTonight.
  ///
  /// In en, this message translates to:
  /// **'{count} MCQs from the news · Tonight: {topics}'**
  String notifPaperBodyTonight(int count, String topics);

  /// No description provided for @prelimsDaysTo.
  ///
  /// In en, this message translates to:
  /// **'{days} days to UPSC Prelims'**
  String prelimsDaysTo(int days);

  /// No description provided for @prelimsBodyDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days to go\nSmall steps, every day — that\'s the edge.'**
  String prelimsBodyDays(int days);

  /// No description provided for @notifNoTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Find where UPSC Wars gives you an edge'**
  String get notifNoTestTitle;

  /// No description provided for @notifNoTestBody.
  ///
  /// In en, this message translates to:
  /// **'Take 8 quick MCQs. Get coached to eliminate better, spot weak areas, and see where you’re strong.'**
  String get notifNoTestBody;

  /// No description provided for @notifBattleInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle invite'**
  String get notifBattleInviteTitle;

  /// No description provided for @notifTapToJoin.
  ///
  /// In en, this message translates to:
  /// **'Tap to join'**
  String get notifTapToJoin;

  /// No description provided for @notifCaShotTitle.
  ///
  /// In en, this message translates to:
  /// **'CA Shot'**
  String get notifCaShotTitle;

  /// No description provided for @notifTapToRead.
  ///
  /// In en, this message translates to:
  /// **'Tap to read & attempt'**
  String get notifTapToRead;

  /// No description provided for @notifNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notifNewMessage;

  /// No description provided for @notifTapToOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Tap to open chat'**
  String get notifTapToOpenChat;

  /// No description provided for @notifPaperTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s paper quiz is live'**
  String get notifPaperTitle;

  /// No description provided for @prelimsToday.
  ///
  /// In en, this message translates to:
  /// **'Prelims is today'**
  String get prelimsToday;

  /// No description provided for @prelimsBodyToday.
  ///
  /// In en, this message translates to:
  /// **'It\'s the exam day,\nYou\'ve prepared for this — breathe and execute.'**
  String get prelimsBodyToday;

  /// No description provided for @prelimsBodyOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day to go,\nOne calm session at a time.'**
  String get prelimsBodyOneDay;

  /// No description provided for @dcaProgressFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load progress: {error}'**
  String dcaProgressFailed(String error);

  /// No description provided for @dcaOfCount.
  ///
  /// In en, this message translates to:
  /// **'out of {count} participants'**
  String dcaOfCount(int count);

  /// No description provided for @dcaAvailableIn.
  ///
  /// In en, this message translates to:
  /// **'Test available in {countdown}'**
  String dcaAvailableIn(String countdown);

  /// No description provided for @dcaJoinedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} joined'**
  String dcaJoinedCount(int count);

  /// No description provided for @dcaTestFromNews.
  ///
  /// In en, this message translates to:
  /// **'This test is from questions from {date}.'**
  String dcaTestFromNews(String date);

  /// No description provided for @dcaNoChampionYet.
  ///
  /// In en, this message translates to:
  /// **'{date} · No champion locked yet'**
  String dcaNoChampionYet(String date);

  /// No description provided for @dcaJoinedLocked.
  ///
  /// In en, this message translates to:
  /// **'{date} · {count} joined · Champion locked'**
  String dcaJoinedLocked(String date, int count);

  /// No description provided for @dcaJoinedLive.
  ///
  /// In en, this message translates to:
  /// **'{date} · {count} joined · live'**
  String dcaJoinedLive(String date, int count);

  /// No description provided for @dcaYouAir.
  ///
  /// In en, this message translates to:
  /// **'You · AIR {air}'**
  String dcaYouAir(int air);

  /// No description provided for @dcaStartFrom.
  ///
  /// In en, this message translates to:
  /// **'Daily tests start from {date}.'**
  String dcaStartFrom(String date);

  /// No description provided for @dcaTenFromPaper.
  ///
  /// In en, this message translates to:
  /// **'10 MCQs from the {date} paper'**
  String dcaTenFromPaper(String date);

  /// No description provided for @dcaLiveIn.
  ///
  /// In en, this message translates to:
  /// **'Live in {t}'**
  String dcaLiveIn(String t);

  /// No description provided for @dcaNextTestIn.
  ///
  /// In en, this message translates to:
  /// **'Next test in {t}'**
  String dcaNextTestIn(String t);

  /// No description provided for @dcaThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dcaThisMonth;

  /// No description provided for @dcaReviewOrRevise.
  ///
  /// In en, this message translates to:
  /// **'Review or revise'**
  String get dcaReviewOrRevise;

  /// No description provided for @dcaTakeTodays.
  ///
  /// In en, this message translates to:
  /// **'Take today\'s test'**
  String get dcaTakeTodays;

  /// No description provided for @dcaTodaysPaperBtn.
  ///
  /// In en, this message translates to:
  /// **'Today\'s paper'**
  String get dcaTodaysPaperBtn;

  /// No description provided for @dcaNoRanks.
  ///
  /// In en, this message translates to:
  /// **'No ranks yet. Be the first to finish today\'s paper.'**
  String get dcaNoRanks;

  /// No description provided for @dcaSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Submit failed'**
  String get dcaSubmitFailed;

  /// No description provided for @dcaLoadingResults.
  ///
  /// In en, this message translates to:
  /// **'Loading your results…'**
  String get dcaLoadingResults;

  /// No description provided for @dcaTodaysBoard.
  ///
  /// In en, this message translates to:
  /// **'Today\'s board'**
  String get dcaTodaysBoard;

  /// No description provided for @dcaRanksPreview.
  ///
  /// In en, this message translates to:
  /// **'Ranks are in preview.'**
  String get dcaRanksPreview;

  /// No description provided for @dcaSignInForAir.
  ///
  /// In en, this message translates to:
  /// **'Sign in from Profile to join today\'s All-India Rank.'**
  String get dcaSignInForAir;

  /// No description provided for @dcaUnrankedLocked.
  ///
  /// In en, this message translates to:
  /// **'Unranked · this paper\'s Champion is already locked.'**
  String get dcaUnrankedLocked;

  /// No description provided for @dcaSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted.'**
  String get dcaSubmitted;

  /// No description provided for @dcaTodaysLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Today\'s leaderboard'**
  String get dcaTodaysLeaderboard;

  /// No description provided for @dcaReviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Review answers'**
  String get dcaReviewAnswers;

  /// No description provided for @dcaLiveUnranked.
  ///
  /// In en, this message translates to:
  /// **'Unranked · Champion already locked.'**
  String get dcaLiveUnranked;

  /// No description provided for @dcaLiveAir.
  ///
  /// In en, this message translates to:
  /// **'AIR can still move. Champion locks at 6 AM IST.'**
  String get dcaLiveAir;

  /// No description provided for @dcaNotAvailableCopy.
  ///
  /// In en, this message translates to:
  /// **'Questions for this date are not available yet.'**
  String get dcaNotAvailableCopy;

  /// No description provided for @dcaGenericLoadCopy.
  ///
  /// In en, this message translates to:
  /// **'Could not load test. Check your connection and try again.'**
  String get dcaGenericLoadCopy;

  /// No description provided for @testStartTest.
  ///
  /// In en, this message translates to:
  /// **'Start test'**
  String get testStartTest;

  /// No description provided for @dcaNotLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions aren\'t live yet'**
  String get dcaNotLiveTitle;

  /// No description provided for @dcaSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions will be available soon'**
  String get dcaSoonTitle;

  /// No description provided for @dcaNotLiveBody.
  ///
  /// In en, this message translates to:
  /// **'This morning\'s paper was generated, but it has not been published to the app yet. Pull home to refresh in a minute.'**
  String get dcaNotLiveBody;

  /// No description provided for @dcaSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Each paper is built from news articles. It tests how well you read the previous day\'s news — yesterday\'s newspaper, this morning\'s quiz.'**
  String get dcaSoonBody;

  /// No description provided for @dcaSeePast.
  ///
  /// In en, this message translates to:
  /// **'See past current affairs MCQs'**
  String get dcaSeePast;

  /// No description provided for @dcaChampionLocked.
  ///
  /// In en, this message translates to:
  /// **'Champion is locked for this paper.'**
  String get dcaChampionLocked;

  /// No description provided for @dcaPullRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh. Champion locks at 6 AM.'**
  String get dcaPullRefresh;

  /// No description provided for @dcaLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link.'**
  String get dcaLinkFailed;

  /// No description provided for @dcaReviseThisDayRec.
  ///
  /// In en, this message translates to:
  /// **'You can revise this day\'s current affairs from our recommended links.'**
  String get dcaReviseThisDayRec;

  /// No description provided for @dcaAvailableSoon.
  ///
  /// In en, this message translates to:
  /// **'Available soon'**
  String get dcaAvailableSoon;

  /// No description provided for @dcaReviseThisTest.
  ///
  /// In en, this message translates to:
  /// **'Revise this test'**
  String get dcaReviseThisTest;

  /// No description provided for @dcaStartTodays.
  ///
  /// In en, this message translates to:
  /// **'Start today\'s test'**
  String get dcaStartTodays;

  /// No description provided for @dcaStartTheTest.
  ///
  /// In en, this message translates to:
  /// **'Start the test'**
  String get dcaStartTheTest;

  /// No description provided for @dcaFavSources.
  ///
  /// In en, this message translates to:
  /// **'These are our favourite sources for this day\'s current affairs.'**
  String get dcaFavSources;

  /// No description provided for @dcaQuizNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Today\'s quiz isn\'t open yet. Check back after 6 AM, or pick a past day below.'**
  String get dcaQuizNotOpen;

  /// No description provided for @dcaAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You already submitted. Review answers or revise in learning mode.'**
  String get dcaAlreadySubmitted;

  /// No description provided for @dcaSameQuestions.
  ///
  /// In en, this message translates to:
  /// **'Same questions for everyone — based on yesterday\'s news.'**
  String get dcaSameQuestions;

  /// No description provided for @dcaReviseLearning.
  ///
  /// In en, this message translates to:
  /// **'Revise (learning)'**
  String get dcaReviseLearning;

  /// No description provided for @dcaSignInLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see the leaderboard.'**
  String get dcaSignInLeaderboard;

  /// No description provided for @dcaEyebrowToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get dcaEyebrowToday;

  /// No description provided for @dcaEyebrowYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get dcaEyebrowYesterday;

  /// No description provided for @dcaLiveFirst.
  ///
  /// In en, this message translates to:
  /// **'Live ranks · be the first to finish'**
  String get dcaLiveFirst;

  /// No description provided for @dcaSeeAllRanks.
  ///
  /// In en, this message translates to:
  /// **'See all ranks'**
  String get dcaSeeAllRanks;

  /// No description provided for @dcaFinishToAppear.
  ///
  /// In en, this message translates to:
  /// **'Finish the paper to appear on the board.'**
  String get dcaFinishToAppear;

  /// No description provided for @dcaTodayOpens.
  ///
  /// In en, this message translates to:
  /// **'Today\'s test opens at 6 AM'**
  String get dcaTodayOpens;

  /// No description provided for @dcaTomorrowOpens.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s test opens at 6 AM'**
  String get dcaTomorrowOpens;

  /// No description provided for @dcaGoesLive6.
  ///
  /// In en, this message translates to:
  /// **'Today\'s current affairs test, from yesterday\'s news, goes live at 6 AM.'**
  String get dcaGoesLive6;

  /// No description provided for @dcaNoPaperToday.
  ///
  /// In en, this message translates to:
  /// **'No paper today. The next one lands tomorrow at 6 AM.'**
  String get dcaNoPaperToday;

  /// No description provided for @dcaQuizDone.
  ///
  /// In en, this message translates to:
  /// **'Quiz done. Open the explanations if a line still nags.'**
  String get dcaQuizDone;

  /// No description provided for @dcaCaFromYesterday.
  ///
  /// In en, this message translates to:
  /// **'Current affairs test from yesterday\'s news.'**
  String get dcaCaFromYesterday;

  /// No description provided for @dcaReviseThisDay.
  ///
  /// In en, this message translates to:
  /// **'You can revise this day\'s current affairs from these links.'**
  String get dcaReviseThisDay;

  /// No description provided for @dcaNotStartedYet.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get dcaNotStartedYet;

  /// No description provided for @dcaViewResults.
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get dcaViewResults;

  /// No description provided for @dcaReviseYesterdayRec.
  ///
  /// In en, this message translates to:
  /// **'You can revise yesterday\'s current affairs from our recommended links.'**
  String get dcaReviseYesterdayRec;

  /// No description provided for @dcaReviseYesterday.
  ///
  /// In en, this message translates to:
  /// **'You can revise yesterday\'s current affairs from these links.'**
  String get dcaReviseYesterday;

  /// No description provided for @dcaTestWillBeFrom.
  ///
  /// In en, this message translates to:
  /// **'Today\'s test will be from :\n'**
  String get dcaTestWillBeFrom;

  /// No description provided for @dwStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get dwStarting;

  /// No description provided for @dwStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {t}'**
  String dwStartsIn(String t);

  /// No description provided for @dwJoinNow.
  ///
  /// In en, this message translates to:
  /// **'Join now'**
  String get dwJoinNow;

  /// No description provided for @dwSignInJoin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join'**
  String get dwSignInJoin;

  /// No description provided for @dwAttemptUnranked.
  ///
  /// In en, this message translates to:
  /// **'Attempt unranked'**
  String get dwAttemptUnranked;

  /// No description provided for @dwSignInAttempt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to attempt'**
  String get dwSignInAttempt;

  /// No description provided for @dwLobbyOpen.
  ///
  /// In en, this message translates to:
  /// **'LOBBY OPEN'**
  String get dwLobbyOpen;

  /// No description provided for @dwInProgress.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get dwInProgress;

  /// No description provided for @dwSundayOff.
  ///
  /// In en, this message translates to:
  /// **'SUNDAY OFF'**
  String get dwSundayOff;

  /// No description provided for @dwOpenAttempt.
  ///
  /// In en, this message translates to:
  /// **'Open your attempt'**
  String get dwOpenAttempt;

  /// No description provided for @dwAspirantsInLobby.
  ///
  /// In en, this message translates to:
  /// **'aspirants in the lobby'**
  String get dwAspirantsInLobby;

  /// No description provided for @dwWritingNow.
  ///
  /// In en, this message translates to:
  /// **'writing right now'**
  String get dwWritingNow;

  /// No description provided for @dwLateJoinClosed.
  ///
  /// In en, this message translates to:
  /// **'Late join closed'**
  String get dwLateJoinClosed;

  /// No description provided for @dwPaperNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s paper isn\'t loaded yet. Try again in some time.'**
  String get dwPaperNotLoaded;

  /// No description provided for @dwHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get dwHistory;

  /// No description provided for @dwTomorrowTopics.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow · {topics}'**
  String dwTomorrowTopics(String topics);

  /// No description provided for @dwPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get dwPractice;

  /// No description provided for @dwNextEventMonday.
  ///
  /// In en, this message translates to:
  /// **'Next {event} is Monday at 9:00 PM IST.'**
  String dwNextEventMonday(String event);

  /// No description provided for @dwEventLobbyOpen.
  ///
  /// In en, this message translates to:
  /// **'{event} lobby is open.'**
  String dwEventLobbyOpen(String event);

  /// No description provided for @dwEventIsLive.
  ///
  /// In en, this message translates to:
  /// **'{event} is live.'**
  String dwEventIsLive(String event);

  /// No description provided for @dwEventTonight.
  ///
  /// In en, this message translates to:
  /// **'{event} TONIGHT'**
  String dwEventTonight(String event);

  /// No description provided for @dwSatEventStarts.
  ///
  /// In en, this message translates to:
  /// **'Saturday {event} starts at 9:00 PM IST.'**
  String dwSatEventStarts(String event);

  /// No description provided for @dwEventStarts.
  ///
  /// In en, this message translates to:
  /// **'{event} starts at 9:00 PM IST.'**
  String dwEventStarts(String event);

  /// No description provided for @dwFooterTonight.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s {event} starts at 9 PM'**
  String dwFooterTonight(String event);

  /// No description provided for @dwFooterMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday\'s {event} starts at 9 PM'**
  String dwFooterMonday(String event);

  /// No description provided for @dwFooterNext.
  ///
  /// In en, this message translates to:
  /// **'Next {event} starts at 9 PM'**
  String dwFooterNext(String event);

  /// No description provided for @dwRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day · {event} returns Monday 9 PM'**
  String dwRestDay(String event);

  /// No description provided for @dwWeekComplete.
  ///
  /// In en, this message translates to:
  /// **'Week {n} complete'**
  String dwWeekComplete(int n);

  /// No description provided for @dwNightsOf.
  ///
  /// In en, this message translates to:
  /// **'{a} of {b} nights'**
  String dwNightsOf(int a, int b);

  /// No description provided for @dwTopicsWentBy.
  ///
  /// In en, this message translates to:
  /// **'Missed {n, plural, =1{1 topic} other{{n} topics}} this week · nothing lost, Monday is a fresh start'**
  String dwTopicsWentBy(int n);

  /// No description provided for @dwTopicsLanded.
  ///
  /// In en, this message translates to:
  /// **'{n} topics landed'**
  String dwTopicsLanded(int n);

  /// No description provided for @dwStillOpen.
  ///
  /// In en, this message translates to:
  /// **' · {n} still open'**
  String dwStillOpen(int n);

  /// No description provided for @dwTonightTopics.
  ///
  /// In en, this message translates to:
  /// **'Tonight: {topics}'**
  String dwTonightTopics(String topics);

  /// No description provided for @dwDailyDrillSubject.
  ///
  /// In en, this message translates to:
  /// **'Daily Drill · {subject}'**
  String dwDailyDrillSubject(String subject);

  /// No description provided for @dwHowWorks.
  ///
  /// In en, this message translates to:
  /// **'How {program} works'**
  String dwHowWorks(String program);

  /// No description provided for @dwHelpLiveBody.
  ///
  /// In en, this message translates to:
  /// **'Same paper, All-India · {wq}Q / {wm}m weeknights · {gq}Q / {gm}m Sat {event}'**
  String dwHelpLiveBody(int wq, int wm, int gq, int gm, String event);

  /// No description provided for @dwAirAt.
  ///
  /// In en, this message translates to:
  /// **'AIR at {t}'**
  String dwAirAt(String t);

  /// No description provided for @dwHelpRhythmBody.
  ///
  /// In en, this message translates to:
  /// **'2 topics Mon–Fri · {event} Sat · Sunday off'**
  String dwHelpRhythmBody(String event);

  /// No description provided for @dwDrawsFromMany.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s war draws from these {n} topics. Run the PYQs now so you walk in warm.'**
  String dwDrawsFromMany(int n);

  /// No description provided for @dwYourWeekIn.
  ///
  /// In en, this message translates to:
  /// **'Your week in {program}'**
  String dwYourWeekIn(String program);

  /// No description provided for @dwUpRanks.
  ///
  /// In en, this message translates to:
  /// **'up {n} ranks'**
  String dwUpRanks(int n);

  /// No description provided for @dwRanksLockAfter.
  ///
  /// In en, this message translates to:
  /// **'{date} · Ranks lock after the paper closes'**
  String dwRanksLockAfter(String date);

  /// No description provided for @dwBadgesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load badges: {error}'**
  String dwBadgesLoadFailed(String error);

  /// No description provided for @dwEventSaturday.
  ///
  /// In en, this message translates to:
  /// **'{event} · SATURDAY'**
  String dwEventSaturday(String event);

  /// No description provided for @dwMoreSeeAll.
  ///
  /// In en, this message translates to:
  /// **'+ {n} more · See all →'**
  String dwMoreSeeAll(int n);

  /// No description provided for @dwTopicsCovered.
  ///
  /// In en, this message translates to:
  /// **'{covered} of {total} topics covered'**
  String dwTopicsCovered(int covered, int total);

  /// No description provided for @dwTonightAdds.
  ///
  /// In en, this message translates to:
  /// **'tonight adds {n}'**
  String dwTonightAdds(int n);

  /// No description provided for @dwWarStartsIn.
  ///
  /// In en, this message translates to:
  /// **'WAR STARTS IN {t}'**
  String dwWarStartsIn(String t);

  /// No description provided for @dwTimerStartsOnEntry.
  ///
  /// In en, this message translates to:
  /// **'Your timer starts on entry — the {t} close does not move.'**
  String dwTimerStartsOnEntry(String t);

  /// No description provided for @dwEntryClosesIn.
  ///
  /// In en, this message translates to:
  /// **'ENTRY CLOSES IN {t}'**
  String dwEntryClosesIn(String t);

  /// No description provided for @dwYourAirReady.
  ///
  /// In en, this message translates to:
  /// **'Your AIR {air} is ready'**
  String dwYourAirReady(int air);

  /// No description provided for @dwTonightEventLive.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s {event} is live'**
  String dwTonightEventLive(String event);

  /// No description provided for @dwAspirantsTopics.
  ///
  /// In en, this message translates to:
  /// **'{n} aspirants · {topics}'**
  String dwAspirantsTopics(String n, String topics);

  /// No description provided for @dwSeeYourAir.
  ///
  /// In en, this message translates to:
  /// **'See your AIR {air}'**
  String dwSeeYourAir(int air);

  /// No description provided for @dwTonightsResult.
  ///
  /// In en, this message translates to:
  /// **'TONIGHT\'S RESULT · {date}'**
  String dwTonightsResult(String date);

  /// No description provided for @dwAspirantsWroteIt.
  ///
  /// In en, this message translates to:
  /// **'{n} aspirants wrote it'**
  String dwAspirantsWroteIt(String n);

  /// No description provided for @dwPracticedUnranked.
  ///
  /// In en, this message translates to:
  /// **'You practiced unranked · {score}'**
  String dwPracticedUnranked(String score);

  /// No description provided for @dwBadgesCount.
  ///
  /// In en, this message translates to:
  /// **'{kinds} badges · {earned} total earns'**
  String dwBadgesCount(int kinds, int earned);

  /// No description provided for @dwEventIsLiveCaps.
  ///
  /// In en, this message translates to:
  /// **'{event} IS LIVE'**
  String dwEventIsLiveCaps(String event);

  /// No description provided for @dwNoLiveNext.
  ///
  /// In en, this message translates to:
  /// **'No live paper today. Next {event} is Monday at 9:00 PM IST.'**
  String dwNoLiveNext(String event);

  /// No description provided for @dwPlusMore.
  ///
  /// In en, this message translates to:
  /// **'+ {n} more'**
  String dwPlusMore(int n);

  /// No description provided for @dwSeeAllTopics.
  ///
  /// In en, this message translates to:
  /// **'See all {n} topics →'**
  String dwSeeAllTopics(int n);

  /// No description provided for @dwJoinUntilLeft.
  ///
  /// In en, this message translates to:
  /// **'Join until 9:10 · {t} left'**
  String dwJoinUntilLeft(String t);

  /// No description provided for @dwNoPaperNext.
  ///
  /// In en, this message translates to:
  /// **'No paper today · next {event} Monday 9:00 PM'**
  String dwNoPaperNext(String event);

  /// No description provided for @dwLateClosedAirAt.
  ///
  /// In en, this message translates to:
  /// **'Late join closed · AIR at {t}'**
  String dwLateClosedAirAt(String t);

  /// No description provided for @dwStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start War: {error}'**
  String dwStartFailed(String error);

  /// No description provided for @dwLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load Static War: {error}'**
  String dwLoadFailed(String error);

  /// No description provided for @dwPaperLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load tonight\'s paper: {error}'**
  String dwPaperLoadFailed(String error);

  /// No description provided for @dwBattleStartsLeft.
  ///
  /// In en, this message translates to:
  /// **'Battle starts at 9:00 PM IST · {t} left.'**
  String dwBattleStartsLeft(String t);

  /// No description provided for @dwRulesLobby.
  ///
  /// In en, this message translates to:
  /// **'{q} Q · {m} MIN · ONE ATTEMPT'**
  String dwRulesLobby(int q, int m);

  /// No description provided for @dwNoLivePaper.
  ///
  /// In en, this message translates to:
  /// **'No live paper today.'**
  String get dwNoLivePaper;

  /// No description provided for @dwYouWereIn.
  ///
  /// In en, this message translates to:
  /// **'You were in tonight\'s paper.'**
  String get dwYouWereIn;

  /// No description provided for @dwOpenRankExpl.
  ///
  /// In en, this message translates to:
  /// **'Open your rank and explanations.'**
  String get dwOpenRankExpl;

  /// No description provided for @dwAttemptInResultsFollow.
  ///
  /// In en, this message translates to:
  /// **'Your attempt is in. Results will follow.'**
  String get dwAttemptInResultsFollow;

  /// No description provided for @dwPaperStarts9.
  ///
  /// In en, this message translates to:
  /// **'Paper starts at 9:00 PM IST.'**
  String get dwPaperStarts9;

  /// No description provided for @dwLiveNow.
  ///
  /// In en, this message translates to:
  /// **'LIVE NOW'**
  String get dwLiveNow;

  /// No description provided for @dwLiveJoinBefore.
  ///
  /// In en, this message translates to:
  /// **'All-India live paper. Join before the window closes.'**
  String get dwLiveJoinBefore;

  /// No description provided for @dwEntryClosedRanks.
  ///
  /// In en, this message translates to:
  /// **'Entry closed at 9:10 PM IST. Ranks at 9:40 PM.'**
  String get dwEntryClosedRanks;

  /// No description provided for @dwWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s live window has closed.'**
  String get dwWindowClosed;

  /// No description provided for @dwStillUnranked.
  ///
  /// In en, this message translates to:
  /// **'You can still attempt this paper unranked.'**
  String get dwStillUnranked;

  /// No description provided for @dwWeekRevision.
  ///
  /// In en, this message translates to:
  /// **'Week revision. Same paper, All-India.'**
  String get dwWeekRevision;

  /// No description provided for @dwLobbyOpens859.
  ///
  /// In en, this message translates to:
  /// **'All-India live paper. Lobby opens at 8:59 PM.'**
  String get dwLobbyOpens859;

  /// No description provided for @dwSundayNoBattle.
  ///
  /// In en, this message translates to:
  /// **'SUNDAY · NO BATTLE TONIGHT'**
  String get dwSundayNoBattle;

  /// No description provided for @dwQuietWeek.
  ///
  /// In en, this message translates to:
  /// **'A quiet week'**
  String get dwQuietWeek;

  /// No description provided for @dwNoBattleNights.
  ///
  /// In en, this message translates to:
  /// **'No battle nights this week · Monday is a fresh start'**
  String get dwNoBattleNights;

  /// No description provided for @dwStreakSafe.
  ///
  /// In en, this message translates to:
  /// **'Streak safe · revise or rest until Monday'**
  String get dwStreakSafe;

  /// No description provided for @dwFullWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'Full week summary'**
  String get dwFullWeekSummary;

  /// No description provided for @dwTopicsMonday.
  ///
  /// In en, this message translates to:
  /// **'Topics up Monday morning'**
  String get dwTopicsMonday;

  /// No description provided for @dwCatchUp.
  ///
  /// In en, this message translates to:
  /// **'Catch up'**
  String get dwCatchUp;

  /// No description provided for @dwReviseWeek.
  ///
  /// In en, this message translates to:
  /// **'Revise week'**
  String get dwReviseWeek;

  /// No description provided for @dwPracticeEarly.
  ///
  /// In en, this message translates to:
  /// **'Practice early'**
  String get dwPracticeEarly;

  /// No description provided for @dwUpNext.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT'**
  String get dwUpNext;

  /// No description provided for @dwMonday9.
  ///
  /// In en, this message translates to:
  /// **'Monday · 9 PM'**
  String get dwMonday9;

  /// No description provided for @dwWeekStrip.
  ///
  /// In en, this message translates to:
  /// **'Mon–Fri new topics · Sat revises the week · Sunday off'**
  String get dwWeekStrip;

  /// No description provided for @dwExplainerHead.
  ///
  /// In en, this message translates to:
  /// **'Full syllabus.\nTwo topics at a time.'**
  String get dwExplainerHead;

  /// No description provided for @dwExplainerSub.
  ///
  /// In en, this message translates to:
  /// **'9 PM live paper. Same questions. Then you see the leaderboard.'**
  String get dwExplainerSub;

  /// No description provided for @dwPaperIsTheseSat.
  ///
  /// In en, this message translates to:
  /// **'Saturday\'s paper is these:'**
  String get dwPaperIsTheseSat;

  /// No description provided for @dwPaperIsThis.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s paper is this:'**
  String get dwPaperIsThis;

  /// No description provided for @dwPaperIsThese.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s paper is these:'**
  String get dwPaperIsThese;

  /// No description provided for @dwWeekTopicsLand.
  ///
  /// In en, this message translates to:
  /// **'This week\'s two topics land here.'**
  String get dwWeekTopicsLand;

  /// No description provided for @dwTonightTopicsLand.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s two topics land here.'**
  String get dwTonightTopicsLand;

  /// No description provided for @dwTry10.
  ///
  /// In en, this message translates to:
  /// **'Try 10 questions on these'**
  String get dwTry10;

  /// No description provided for @dwQuick10.
  ///
  /// In en, this message translates to:
  /// **'10 quick MCQs on tonight\'s subject'**
  String get dwQuick10;

  /// No description provided for @commonTryAgainError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonTryAgainError;

  /// No description provided for @dwStep2.
  ///
  /// In en, this message translates to:
  /// **'STEP 2 · PREPARE'**
  String get dwStep2;

  /// No description provided for @dwHelpLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live at 9:00 PM'**
  String get dwHelpLiveTitle;

  /// No description provided for @dwHelpAirBody.
  ///
  /// In en, this message translates to:
  /// **'See your score on submission · we\'ll notify you when ranks are ready'**
  String get dwHelpAirBody;

  /// No description provided for @dwHelpRhythmTitle.
  ///
  /// In en, this message translates to:
  /// **'Week rhythm'**
  String get dwHelpRhythmTitle;

  /// No description provided for @dwHelpMissedTitle.
  ///
  /// In en, this message translates to:
  /// **'Missed a night?'**
  String get dwHelpMissedTitle;

  /// No description provided for @dwHelpMissedBody.
  ///
  /// In en, this message translates to:
  /// **'Practice later · no rank · streak breaks'**
  String get dwHelpMissedBody;

  /// No description provided for @dwReviseBefore9.
  ///
  /// In en, this message translates to:
  /// **'Revise before 9 PM'**
  String get dwReviseBefore9;

  /// No description provided for @dwDrawsFromOne.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s war draws from this topic. Run the PYQs now so you walk in warm.'**
  String get dwDrawsFromOne;

  /// No description provided for @dwRevisionNoRank.
  ///
  /// In en, this message translates to:
  /// **'Revision here does not count towards your war rank.'**
  String get dwRevisionNoRank;

  /// No description provided for @dwNoQuestionsTopic.
  ///
  /// In en, this message translates to:
  /// **'No questions available for this topic yet.'**
  String get dwNoQuestionsTopic;

  /// No description provided for @dwStartPractice.
  ///
  /// In en, this message translates to:
  /// **'Start practice'**
  String get dwStartPractice;

  /// No description provided for @dwNightsAttempted.
  ///
  /// In en, this message translates to:
  /// **'nights attempted'**
  String get dwNightsAttempted;

  /// No description provided for @dwConfidentlyWrong.
  ///
  /// In en, this message translates to:
  /// **'Confidently wrong'**
  String get dwConfidentlyWrong;

  /// No description provided for @dwConfWrongBody.
  ///
  /// In en, this message translates to:
  /// **'Topics where you marked Sure / Educated guess and missed.'**
  String get dwConfWrongBody;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @dwDangerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load danger topics.'**
  String get dwDangerLoadFailed;

  /// No description provided for @dwNoAttemptsWeek.
  ///
  /// In en, this message translates to:
  /// **'No attempts this week yet.'**
  String get dwNoAttemptsWeek;

  /// No description provided for @dwNoneWeek.
  ///
  /// In en, this message translates to:
  /// **'None this week — keep that map clean.'**
  String get dwNoneWeek;

  /// No description provided for @dwBadgesEarned.
  ///
  /// In en, this message translates to:
  /// **'Badges earned'**
  String get dwBadgesEarned;

  /// No description provided for @dwShowUpMonday.
  ///
  /// In en, this message translates to:
  /// **'Show up Monday to start collecting.'**
  String get dwShowUpMonday;

  /// No description provided for @dwNoBadgesWeek.
  ///
  /// In en, this message translates to:
  /// **'No badges this week.'**
  String get dwNoBadgesWeek;

  /// No description provided for @dwNoBadgesNight.
  ///
  /// In en, this message translates to:
  /// **'No badges earned this night yet.'**
  String get dwNoBadgesNight;

  /// No description provided for @dwTiersNote.
  ///
  /// In en, this message translates to:
  /// **'Consistency tiers climb over {days} War nights. Miss two nights in a row and you fall one tier.'**
  String dwTiersNote(int days);

  /// No description provided for @dwTonight.
  ///
  /// In en, this message translates to:
  /// **'TONIGHT'**
  String get dwTonight;

  /// No description provided for @dwLastNight.
  ///
  /// In en, this message translates to:
  /// **'LAST NIGHT'**
  String get dwLastNight;

  /// No description provided for @dwLastWar.
  ///
  /// In en, this message translates to:
  /// **'LAST WAR'**
  String get dwLastWar;

  /// No description provided for @dwSeeBoard.
  ///
  /// In en, this message translates to:
  /// **'See board'**
  String get dwSeeBoard;

  /// No description provided for @dwNoChampionYet.
  ///
  /// In en, this message translates to:
  /// **'No champion yet. Ranks land here after the paper locks.'**
  String get dwNoChampionYet;

  /// No description provided for @dwEarnedBadges.
  ///
  /// In en, this message translates to:
  /// **'EARNED BADGES'**
  String get dwEarnedBadges;

  /// No description provided for @dwNoBadgeYet.
  ///
  /// In en, this message translates to:
  /// **'You have not yet earned a badge'**
  String get dwNoBadgeYet;

  /// No description provided for @dwStarts9.
  ///
  /// In en, this message translates to:
  /// **'STARTS 9:00 PM IST'**
  String get dwStarts9;

  /// No description provided for @dwLobbyFilling.
  ///
  /// In en, this message translates to:
  /// **'The lobby is filling up'**
  String get dwLobbyFilling;

  /// No description provided for @dwEnterLobby.
  ///
  /// In en, this message translates to:
  /// **'Enter lobby'**
  String get dwEnterLobby;

  /// No description provided for @dwWarIsLive.
  ///
  /// In en, this message translates to:
  /// **'WAR IS LIVE'**
  String get dwWarIsLive;

  /// No description provided for @dwStarted9.
  ///
  /// In en, this message translates to:
  /// **'STARTED 9:00 PM IST'**
  String get dwStarted9;

  /// No description provided for @dwJoinUntil910.
  ///
  /// In en, this message translates to:
  /// **'You can still join until 9:10'**
  String get dwJoinUntil910;

  /// No description provided for @dwYoureIn.
  ///
  /// In en, this message translates to:
  /// **'YOU\'RE IN'**
  String get dwYoureIn;

  /// No description provided for @dwEntryClosed910.
  ///
  /// In en, this message translates to:
  /// **'ENTRY CLOSED 9:10 PM'**
  String get dwEntryClosed910;

  /// No description provided for @dwAttemptInAir940.
  ///
  /// In en, this message translates to:
  /// **'Your attempt is in · AIR at 9:40 PM IST'**
  String get dwAttemptInAir940;

  /// No description provided for @dwLateJoinClosedDot.
  ///
  /// In en, this message translates to:
  /// **'Late join closed.'**
  String get dwLateJoinClosedDot;

  /// No description provided for @dwEntryCloses910.
  ///
  /// In en, this message translates to:
  /// **'Entry closes at 9:10.'**
  String get dwEntryCloses910;

  /// No description provided for @dwTodaysWarLive.
  ///
  /// In en, this message translates to:
  /// **'Today\'s war is live'**
  String get dwTodaysWarLive;

  /// No description provided for @dwResultsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'RESULTS'**
  String get dwResultsEyebrow;

  /// No description provided for @dwAirAt940.
  ///
  /// In en, this message translates to:
  /// **'AIR AT 9:40 PM'**
  String get dwAirAt940;

  /// No description provided for @dwScoreInNotify.
  ///
  /// In en, this message translates to:
  /// **'Your score is in · we\'ll notify you when AIR is ready'**
  String get dwScoreInNotify;

  /// No description provided for @dwBattleOverAir.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s battle is over · AIR at 9:40 PM'**
  String get dwBattleOverAir;

  /// No description provided for @dwFullResults.
  ///
  /// In en, this message translates to:
  /// **'Full results & review'**
  String get dwFullResults;

  /// No description provided for @dwBattleOverCaps.
  ///
  /// In en, this message translates to:
  /// **'TONIGHT\'S BATTLE IS OVER'**
  String get dwBattleOverCaps;

  /// No description provided for @dwSatOut.
  ///
  /// In en, this message translates to:
  /// **'You sat this one out'**
  String get dwSatOut;

  /// No description provided for @dwAttemptInPending.
  ///
  /// In en, this message translates to:
  /// **'Your attempt is in · rank pending'**
  String get dwAttemptInPending;

  /// No description provided for @dwSeeTonightsPaper.
  ///
  /// In en, this message translates to:
  /// **'See tonight\'s paper'**
  String get dwSeeTonightsPaper;

  /// No description provided for @dwUnrankedAttempt.
  ///
  /// In en, this message translates to:
  /// **'Unranked attempt'**
  String get dwUnrankedAttempt;

  /// No description provided for @dwSeeYourAttempt.
  ///
  /// In en, this message translates to:
  /// **'See your attempt'**
  String get dwSeeYourAttempt;

  /// No description provided for @dwTomorrow9.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow · 9:00 PM IST'**
  String get dwTomorrow9;

  /// No description provided for @dwNoQuestionsAvail.
  ///
  /// In en, this message translates to:
  /// **'No questions available'**
  String get dwNoQuestionsAvail;

  /// No description provided for @dwStaticWarRevise.
  ///
  /// In en, this message translates to:
  /// **'Static War revise'**
  String get dwStaticWarRevise;

  /// No description provided for @dwTonightsLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s war · leaderboard'**
  String get dwTonightsLeaderboard;

  /// No description provided for @dwLeaderboardNotReady.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard not ready yet.'**
  String get dwLeaderboardNotReady;

  /// No description provided for @dwBadgesSyncNote.
  ///
  /// In en, this message translates to:
  /// **'Counts sync from your Static War nights — kept on this device and in the cloud.'**
  String get dwBadgesSyncNote;

  /// No description provided for @dwResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Static War results'**
  String get dwResultsTitle;

  /// No description provided for @dwSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting your answers…'**
  String get dwSubmitting;

  /// No description provided for @dwDemoted.
  ///
  /// In en, this message translates to:
  /// **'Your paper came in after the live window closed, so it\'s saved as an unranked attempt.'**
  String get dwDemoted;

  /// No description provided for @dwUnrankedNotOfficial.
  ///
  /// In en, this message translates to:
  /// **'Unranked · not an official AIR'**
  String get dwUnrankedNotOfficial;

  /// No description provided for @dwSubmittedAirReady.
  ///
  /// In en, this message translates to:
  /// **'Submitted · AIR will be ready at 9:40 PM IST. We\'ll notify you.'**
  String get dwSubmittedAirReady;

  /// No description provided for @dwTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dwTomorrow;

  /// No description provided for @dwTonightsLeaderboardBtn.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s leaderboard'**
  String get dwTonightsLeaderboardBtn;

  /// No description provided for @dwNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Static War is not available.'**
  String get dwNotAvailable;

  /// No description provided for @dwNotAvailableAccount.
  ///
  /// In en, this message translates to:
  /// **'Static War is not available on this account yet.'**
  String get dwNotAvailableAccount;

  /// No description provided for @dwSundayOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunday off'**
  String get dwSundayOffTitle;

  /// No description provided for @dwPracticeTopics.
  ///
  /// In en, this message translates to:
  /// **'Practice these topics →'**
  String get dwPracticeTopics;

  /// No description provided for @dwOpenHistory.
  ///
  /// In en, this message translates to:
  /// **'Open History'**
  String get dwOpenHistory;

  /// No description provided for @dwCantJoinNow.
  ///
  /// In en, this message translates to:
  /// **'You can\'t join now'**
  String get dwCantJoinNow;

  /// No description provided for @dwComeBack859.
  ///
  /// In en, this message translates to:
  /// **'Come back at 8:59 PM IST to enter the lobby.'**
  String get dwComeBack859;

  /// No description provided for @dwResultsReady.
  ///
  /// In en, this message translates to:
  /// **'RESULTS READY'**
  String get dwResultsReady;

  /// No description provided for @dwPrepareToday.
  ///
  /// In en, this message translates to:
  /// **'Prepare today · lobby opens 8:59 PM'**
  String get dwPrepareToday;

  /// No description provided for @dwRanksCalculating.
  ///
  /// In en, this message translates to:
  /// **'Ranks calculating…'**
  String get dwRanksCalculating;

  /// No description provided for @dwResultsReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Results ready'**
  String get dwResultsReadyTitle;

  /// No description provided for @dwReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get dwReady;

  /// No description provided for @dwHistoryCaps.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get dwHistoryCaps;

  /// No description provided for @dwSignInAttemptWar.
  ///
  /// In en, this message translates to:
  /// **'Sign in to attempt this War.'**
  String get dwSignInAttemptWar;

  /// No description provided for @dwSignInJoinWar.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join tonight\'s War.'**
  String get dwSignInJoinWar;

  /// No description provided for @dwAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You already submitted this War.'**
  String get dwAlreadySubmitted;

  /// No description provided for @dwAlreadyPracticed.
  ///
  /// In en, this message translates to:
  /// **'You already practiced this War.'**
  String get dwAlreadyPracticed;

  /// No description provided for @dwUpdateApp.
  ///
  /// In en, this message translates to:
  /// **'Update the app to attempt tonight\'s War — some of this paper isn\'t in your question bank yet.'**
  String get dwUpdateApp;

  /// No description provided for @dwTopicsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load tonight\'s topics'**
  String get dwTopicsLoadFailed;

  /// No description provided for @dwTopicsFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding tonight\'s topics…'**
  String get dwTopicsFinding;

  /// No description provided for @dwTwoTopics.
  ///
  /// In en, this message translates to:
  /// **'Two topics a night'**
  String get dwTwoTopics;

  /// No description provided for @dwPaperOpenRanksTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s paper is open. Ranks show here tomorrow.'**
  String get dwPaperOpenRanksTomorrow;

  /// No description provided for @dwLateClosedUnrankedAt.
  ///
  /// In en, this message translates to:
  /// **'Late join closed · unranked at {t}'**
  String dwLateClosedUnrankedAt(String t);

  /// No description provided for @dwWarriorsThatNight.
  ///
  /// In en, this message translates to:
  /// **'{n} warriors that night'**
  String dwWarriorsThatNight(String n);

  /// No description provided for @dwAirLabel.
  ///
  /// In en, this message translates to:
  /// **'AIR {air}'**
  String dwAirLabel(int air);

  /// No description provided for @dwBetterThan.
  ///
  /// In en, this message translates to:
  /// **'Better than {pct}% of warriors'**
  String dwBetterThan(String pct);

  /// No description provided for @dwPts.
  ///
  /// In en, this message translates to:
  /// **'{score} pts'**
  String dwPts(String score);

  /// No description provided for @dwTopNOf.
  ///
  /// In en, this message translates to:
  /// **'Top {n} of {count}'**
  String dwTopNOf(int n, int count);

  /// No description provided for @dwSeeAllCount.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String dwSeeAllCount(int count);

  /// No description provided for @dwSavedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get dwSavedOnDevice;

  /// No description provided for @dwPaperNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Paper not published yet'**
  String get dwPaperNotPublished;

  /// No description provided for @dwStartDayTest.
  ///
  /// In en, this message translates to:
  /// **'Start this day\'s test'**
  String get dwStartDayTest;

  /// No description provided for @dwReviseThisPaper.
  ///
  /// In en, this message translates to:
  /// **'Revise this paper'**
  String get dwReviseThisPaper;

  /// No description provided for @dwLeaderboardCaps.
  ///
  /// In en, this message translates to:
  /// **'LEADERBOARD'**
  String get dwLeaderboardCaps;

  /// No description provided for @dwArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Static War archive'**
  String get dwArchiveTitle;

  /// No description provided for @dwYourAttemptCaps.
  ///
  /// In en, this message translates to:
  /// **'YOUR ATTEMPT'**
  String get dwYourAttemptCaps;

  /// No description provided for @dwNotAttempted.
  ///
  /// In en, this message translates to:
  /// **'Not attempted'**
  String get dwNotAttempted;

  /// No description provided for @dwStartAboveToTake.
  ///
  /// In en, this message translates to:
  /// **'Start the test above to take this paper.'**
  String get dwStartAboveToTake;

  /// No description provided for @dwPendingRank.
  ///
  /// In en, this message translates to:
  /// **'Pending rank'**
  String get dwPendingRank;

  /// No description provided for @dwSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get dwSkip;

  /// No description provided for @dwNoRankedFinishers.
  ///
  /// In en, this message translates to:
  /// **'No ranked finishers yet'**
  String get dwNoRankedFinishers;

  /// No description provided for @dwRanksLandAfter.
  ///
  /// In en, this message translates to:
  /// **'Ranks land after the paper closes · All-India board fills here'**
  String get dwRanksLandAfter;

  /// No description provided for @dwLeaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get dwLeaderboardTitle;

  /// No description provided for @ocPleaseNote.
  ///
  /// In en, this message translates to:
  /// **'Please note:'**
  String get ocPleaseNote;

  /// No description provided for @ocTooltipLine.
  ///
  /// In en, this message translates to:
  /// **'One live challenge per 24h · next slot ~{eta}'**
  String ocTooltipLine(String eta);

  /// No description provided for @ocBodyCopy.
  ///
  /// In en, this message translates to:
  /// **'You already have a live challenge. Next create in ~{eta}.'**
  String ocBodyCopy(String eta);

  /// No description provided for @ocPickCopy.
  ///
  /// In en, this message translates to:
  /// **'Still on cooldown — next create in ~{eta}.'**
  String ocPickCopy(String eta);

  /// No description provided for @qotdSubjectsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subjects: {error}'**
  String qotdSubjectsFailed(String error);

  /// No description provided for @ocPickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick one subject or mixed misc · 10 MCQs · Timed ({n} min)'**
  String ocPickSubtitle(int n);

  /// No description provided for @ocAlreadyAttempted.
  ///
  /// In en, this message translates to:
  /// **'You have already attempted this challenge.'**
  String get ocAlreadyAttempted;

  /// No description provided for @ocExpired.
  ///
  /// In en, this message translates to:
  /// **'This challenge has expired.'**
  String get ocExpired;

  /// No description provided for @ocSignInSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your score to the leaderboard.'**
  String get ocSignInSave;

  /// No description provided for @ocSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your score'**
  String get ocSaveFailed;

  /// No description provided for @commonCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get commonCheckConnection;

  /// No description provided for @ocPublishingScore.
  ///
  /// In en, this message translates to:
  /// **'Publishing your score'**
  String get ocPublishingScore;

  /// No description provided for @ocLocking.
  ///
  /// In en, this message translates to:
  /// **'Locking your answers onto the leaderboard — almost there.'**
  String get ocLocking;

  /// No description provided for @ocRule1.
  ///
  /// In en, this message translates to:
  /// **'You will answer 10 questions in exam mode — no hints, no explanations.'**
  String get ocRule1;

  /// No description provided for @ocRule2.
  ///
  /// In en, this message translates to:
  /// **'Your score is posted publicly with your name.'**
  String get ocRule2;

  /// No description provided for @ocRule3.
  ///
  /// In en, this message translates to:
  /// **'You can only attempt each challenge once.'**
  String get ocRule3;

  /// No description provided for @ocRule4.
  ///
  /// In en, this message translates to:
  /// **'Ties are broken by who attempted earlier.'**
  String get ocRule4;

  /// No description provided for @ocBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get ocBeforeStart;

  /// No description provided for @ocConfidenceNote.
  ///
  /// In en, this message translates to:
  /// **'While selecting an option, marking confidence level is optional, but we recommend it for better insights.'**
  String get ocConfidenceNote;

  /// No description provided for @ocAMoment.
  ///
  /// In en, this message translates to:
  /// **'a moment'**
  String get ocAMoment;

  /// No description provided for @qotdNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions found for this subject.'**
  String get qotdNoQuestions;

  /// No description provided for @qotdLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load that question.'**
  String get qotdLoadFailed;

  /// No description provided for @qotdPickFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a subject first.'**
  String get qotdPickFirst;

  /// No description provided for @ocPickSubject.
  ///
  /// In en, this message translates to:
  /// **'Pick your subject'**
  String get ocPickSubject;

  /// No description provided for @qotdIntro.
  ///
  /// In en, this message translates to:
  /// **'One random question from your bank · shuffle, attempt, then post to Community QOTD.'**
  String get qotdIntro;

  /// No description provided for @commonSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get commonSubject;

  /// No description provided for @qotdContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to question'**
  String get qotdContinue;

  /// No description provided for @qotdNoneLoaded.
  ///
  /// In en, this message translates to:
  /// **'No question loaded.'**
  String get qotdNoneLoaded;

  /// No description provided for @qotdShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle question'**
  String get qotdShuffle;

  /// No description provided for @qotdReadExpl.
  ///
  /// In en, this message translates to:
  /// **'Read explanation'**
  String get qotdReadExpl;

  /// No description provided for @qotdPostThis.
  ///
  /// In en, this message translates to:
  /// **'Post this question'**
  String get qotdPostThis;

  /// No description provided for @qotdTabIntro.
  ///
  /// In en, this message translates to:
  /// **'Share a tough question with the Community. Tap a card to expand, react, and attempt.'**
  String get qotdTabIntro;

  /// No description provided for @qotdFeedFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load QOTD feed'**
  String get qotdFeedFailed;

  /// No description provided for @qotdEmpty.
  ///
  /// In en, this message translates to:
  /// **'No questions shared yet. Pull to refresh, or tap Create to post one (for example after you attempt a question in a test).'**
  String get qotdEmpty;

  /// No description provided for @ocCreateChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get ocCreateChallenge;

  /// No description provided for @ocPickNote.
  ///
  /// In en, this message translates to:
  /// **'Ten questions are chosen at random from your local bank for this subject. Timer runs during the challenge.'**
  String get ocPickNote;

  /// No description provided for @ocSubjectsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subjects'**
  String get ocSubjectsFailed;

  /// No description provided for @ocStartMyAttempt.
  ///
  /// In en, this message translates to:
  /// **'Start my challenge attempt'**
  String get ocStartMyAttempt;

  /// No description provided for @ocBeginTimed.
  ///
  /// In en, this message translates to:
  /// **'Begin the timed 10-MCQ challenge'**
  String get ocBeginTimed;

  /// No description provided for @commonJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now ✨'**
  String get commonJustNow;

  /// No description provided for @commonMinAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String commonMinAgo(int n);

  /// No description provided for @commonHrAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String commonHrAgo(int n);

  /// No description provided for @commonDayAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String commonDayAgo(int n);

  /// No description provided for @commonWeekAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}w ago'**
  String commonWeekAgo(int n);

  /// No description provided for @blockedUnblocked.
  ///
  /// In en, this message translates to:
  /// **'{name} has been unblocked.'**
  String blockedUnblocked(String name);

  /// No description provided for @blockedUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unblock: {error}'**
  String blockedUnblockFailed(String error);

  /// No description provided for @connectChallengeUser.
  ///
  /// In en, this message translates to:
  /// **'Challenge {target} in a battle.'**
  String connectChallengeUser(String target);

  /// No description provided for @ocCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by {name}'**
  String ocCreatedBy(String name);

  /// No description provided for @ocLiveTill.
  ///
  /// In en, this message translates to:
  /// **'Live till {t}'**
  String ocLiveTill(String t);

  /// No description provided for @ocYourScore.
  ///
  /// In en, this message translates to:
  /// **'Your score: {s} / 10'**
  String ocYourScore(int s);

  /// No description provided for @ocBeatenBy.
  ///
  /// In en, this message translates to:
  /// **'{name} has beaten your score'**
  String ocBeatenBy(String name);

  /// No description provided for @ocCreatedMin.
  ///
  /// In en, this message translates to:
  /// **'Created {n}m ago'**
  String ocCreatedMin(int n);

  /// No description provided for @ocCreatedHr.
  ///
  /// In en, this message translates to:
  /// **'Created {n}h ago'**
  String ocCreatedHr(int n);

  /// No description provided for @ocCreatedDay.
  ///
  /// In en, this message translates to:
  /// **'Created {n}d ago'**
  String ocCreatedDay(int n);

  /// No description provided for @commLastRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Last refreshed: {t}'**
  String commLastRefreshed(String t);

  /// No description provided for @commKeepProfile.
  ///
  /// In en, this message translates to:
  /// **'Keep your profile updated so others can connect with you even outside {app}.'**
  String commKeepProfile(String app);

  /// No description provided for @qotdMinChars.
  ///
  /// In en, this message translates to:
  /// **'Write at least {n} characters, or leave this blank.'**
  String qotdMinChars(int n);

  /// No description provided for @qotdMaxChars.
  ///
  /// In en, this message translates to:
  /// **'Please keep it under {n} characters.'**
  String qotdMaxChars(int n);

  /// No description provided for @qotdMoreChars.
  ///
  /// In en, this message translates to:
  /// **'{n} more characters to reach {need}, or clear the field to post without a comment.'**
  String qotdMoreChars(int n, int need);

  /// No description provided for @ocGreatScore.
  ///
  /// In en, this message translates to:
  /// **'Great score ({n}/10). Post this set as an open challenge so others can try the same questions in Community.'**
  String ocGreatScore(int n);

  /// No description provided for @ocByName.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String ocByName(String name);

  /// No description provided for @ocTries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 try} other{{count} tries}}'**
  String ocTries(int count);

  /// No description provided for @ocYouScore.
  ///
  /// In en, this message translates to:
  /// **'You {n}/10'**
  String ocYouScore(int n);

  /// No description provided for @commBlockedMsg.
  ///
  /// In en, this message translates to:
  /// **'You will not see messages or battle invites from {name}.'**
  String commBlockedMsg(String name);

  /// No description provided for @commBlockUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update block: {error}'**
  String commBlockUpdateFailed(String error);

  /// No description provided for @commChatStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start chat: {error}'**
  String commChatStartFailed(String error);

  /// No description provided for @commLastOnline.
  ///
  /// In en, this message translates to:
  /// **'Last online: {t}'**
  String commLastOnline(String t);

  /// No description provided for @blockedNone.
  ///
  /// In en, this message translates to:
  /// **'No one blocked'**
  String get blockedNone;

  /// No description provided for @blockedNote.
  ///
  /// In en, this message translates to:
  /// **'People you block won’t be able to message you or send battle invites.'**
  String get blockedNote;

  /// No description provided for @blockedUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get blockedUnblock;

  /// No description provided for @connectRandomIntro.
  ///
  /// In en, this message translates to:
  /// **'Start a random battle connect.'**
  String get connectRandomIntro;

  /// No description provided for @connectStartChallenge.
  ///
  /// In en, this message translates to:
  /// **'Start Challenge'**
  String get connectStartChallenge;

  /// No description provided for @connectNote.
  ///
  /// In en, this message translates to:
  /// **'You will briefly see joined players, then battle auto-starts.'**
  String get connectNote;

  /// No description provided for @ocNotFound.
  ///
  /// In en, this message translates to:
  /// **'Challenge not found'**
  String get ocNotFound;

  /// No description provided for @ocExpired24.
  ///
  /// In en, this message translates to:
  /// **'This challenge has expired (challenges last 24 hours).'**
  String get ocExpired24;

  /// No description provided for @ocWinnerSoFar.
  ///
  /// In en, this message translates to:
  /// **'You are the winner so far 🏆'**
  String get ocWinnerSoFar;

  /// No description provided for @ocReviewExpl.
  ///
  /// In en, this message translates to:
  /// **'Review explanations'**
  String get ocReviewExpl;

  /// No description provided for @ocAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept Challenge'**
  String get ocAccept;

  /// No description provided for @ocCreatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Created just now'**
  String get ocCreatedJustNow;

  /// No description provided for @commRecentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent users'**
  String get commRecentFailed;

  /// No description provided for @commTapUser.
  ///
  /// In en, this message translates to:
  /// **'Tap a user to view profile and social links.'**
  String get commTapUser;

  /// No description provided for @commNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found in the latest window.'**
  String get commNoUsers;

  /// No description provided for @commPullRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh.'**
  String get commPullRefresh;

  /// No description provided for @commLoadingRecent.
  ///
  /// In en, this message translates to:
  /// **'Loading recent users…'**
  String get commLoadingRecent;

  /// No description provided for @commSetVisibility.
  ///
  /// In en, this message translates to:
  /// **'Set Visibility'**
  String get commSetVisibility;

  /// No description provided for @commAcceptInvites.
  ///
  /// In en, this message translates to:
  /// **'Accept battle invites'**
  String get commAcceptInvites;

  /// No description provided for @commReceivingInvites.
  ///
  /// In en, this message translates to:
  /// **'You are receiving battle invites.'**
  String get commReceivingInvites;

  /// No description provided for @commNotReceivingInvites.
  ///
  /// In en, this message translates to:
  /// **'You are not receiving battle invites.'**
  String get commNotReceivingInvites;

  /// No description provided for @commShowBattleStatus.
  ///
  /// In en, this message translates to:
  /// **'Show my in-battle status'**
  String get commShowBattleStatus;

  /// No description provided for @commOthersCanSee.
  ///
  /// In en, this message translates to:
  /// **'Others can see when you are in a battle.'**
  String get commOthersCanSee;

  /// No description provided for @commOthersCannotSee.
  ///
  /// In en, this message translates to:
  /// **'Others cannot see your in-battle status.'**
  String get commOthersCannotSee;

  /// No description provided for @commSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings'**
  String get commSaveFailed;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commTapRandom.
  ///
  /// In en, this message translates to:
  /// **'Tap below for Random Battle Connect'**
  String get commTapRandom;

  /// No description provided for @qotdNoteIntro.
  ///
  /// In en, this message translates to:
  /// **'Optional note for the community. You learned something new? Spotted something ironic? A concept felt challenged? Be specific — or leave this blank.'**
  String get qotdNoteIntro;

  /// No description provided for @qotdCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get qotdCommentLabel;

  /// No description provided for @qotdCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank, or write at least {n} characters…'**
  String qotdCommentHint(int n);

  /// No description provided for @qotdSignInKept.
  ///
  /// In en, this message translates to:
  /// **'Sign in to post. Your comment is kept.'**
  String get qotdSignInKept;

  /// No description provided for @qotdPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get qotdPost;

  /// No description provided for @qotdSignInPost.
  ///
  /// In en, this message translates to:
  /// **'Sign in to post'**
  String get qotdSignInPost;

  /// No description provided for @ocShareChallenge.
  ///
  /// In en, this message translates to:
  /// **'Share the challenge'**
  String get ocShareChallenge;

  /// No description provided for @ocPublishCommunity.
  ///
  /// In en, this message translates to:
  /// **'Publish to Community'**
  String get ocPublishCommunity;

  /// No description provided for @ocTempUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get ocTempUnavailable;

  /// No description provided for @ocPosting.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get ocPosting;

  /// No description provided for @ocPostAsChallenge.
  ///
  /// In en, this message translates to:
  /// **'Post as open challenge'**
  String get ocPostAsChallenge;

  /// No description provided for @qotdRule1.
  ///
  /// In en, this message translates to:
  /// **'Each QOTD stays in Community for 24 hours from when you post it.'**
  String get qotdRule1;

  /// No description provided for @qotdRule2.
  ///
  /// In en, this message translates to:
  /// **'One random MCQ is drawn from your offline catalog for the subject you pick.'**
  String get qotdRule2;

  /// No description provided for @qotdRule3.
  ///
  /// In en, this message translates to:
  /// **'Shuffle until you find a question worth sharing, then attempt it.'**
  String get qotdRule3;

  /// No description provided for @qotdRule4.
  ///
  /// In en, this message translates to:
  /// **'You post after attempting; your pick is stored with the community post.'**
  String get qotdRule4;

  /// No description provided for @qotdRule5.
  ///
  /// In en, this message translates to:
  /// **'Your name and an optional short comment appear on the QOTD card.'**
  String get qotdRule5;

  /// No description provided for @qotdBeforeProceed.
  ///
  /// In en, this message translates to:
  /// **'Before you proceed'**
  String get qotdBeforeProceed;

  /// No description provided for @qotdWhoAnswered.
  ///
  /// In en, this message translates to:
  /// **'Who answered'**
  String get qotdWhoAnswered;

  /// No description provided for @qotdAttemptsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load attempts.'**
  String get qotdAttemptsFailed;

  /// No description provided for @qotdNoAttempts.
  ///
  /// In en, this message translates to:
  /// **'No attempts yet.'**
  String get qotdNoAttempts;

  /// No description provided for @qotdProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile is not available for this attempt yet.'**
  String get qotdProfileUnavailable;

  /// No description provided for @qotdWhatIs.
  ///
  /// In en, this message translates to:
  /// **'What is QOTD?'**
  String get qotdWhatIs;

  /// No description provided for @qotdWhat1.
  ///
  /// In en, this message translates to:
  /// **'Share a question from your test with the community.'**
  String get qotdWhat1;

  /// No description provided for @qotdWhat2.
  ///
  /// In en, this message translates to:
  /// **'Others attempt it and react.'**
  String get qotdWhat2;

  /// No description provided for @qotdWhat3.
  ///
  /// In en, this message translates to:
  /// **'It stays live for 24 hours.'**
  String get qotdWhat3;

  /// No description provided for @ocPublishingChallenge.
  ///
  /// In en, this message translates to:
  /// **'Publishing your challenge…'**
  String get ocPublishingChallenge;

  /// No description provided for @ocStepFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this step. Check your connection and try again.'**
  String get ocStepFailed;

  /// No description provided for @ocWhatIs.
  ///
  /// In en, this message translates to:
  /// **'What is an open challenge?'**
  String get ocWhatIs;

  /// No description provided for @ocWhat1.
  ///
  /// In en, this message translates to:
  /// **'A warrior posts their 10-question exam for everyone to try.'**
  String get ocWhat1;

  /// No description provided for @ocWhat2.
  ///
  /// In en, this message translates to:
  /// **'Same 10 questions for every challenger.'**
  String get ocWhat2;

  /// No description provided for @ocWhat3.
  ///
  /// In en, this message translates to:
  /// **'Beat the top score on the leaderboard.'**
  String get ocWhat3;

  /// No description provided for @ocWhat4.
  ///
  /// In en, this message translates to:
  /// **'Each challenge stays live for 24 hours.'**
  String get ocWhat4;

  /// No description provided for @ocWhatSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join a challenge and post your own.'**
  String get ocWhatSignIn;

  /// No description provided for @commonNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get commonNotNow;

  /// No description provided for @qotdPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted to Community QOTD'**
  String get qotdPosted;

  /// No description provided for @ocSectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Same 10 questions — beat the room! Tap a card for the full story.'**
  String get ocSectionIntro;

  /// No description provided for @ocStartNew.
  ///
  /// In en, this message translates to:
  /// **'Start a new 10-question challenge'**
  String get ocStartNew;

  /// No description provided for @ocLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load challenges'**
  String get ocLoadFailed;

  /// No description provided for @ocNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No challenges yet — you could be first!'**
  String get ocNoneYet;

  /// No description provided for @ocCrushIntro.
  ///
  /// In en, this message translates to:
  /// **'Crush a 10Q exam, then hit Create to drop a challenge for everyone.'**
  String get ocCrushIntro;

  /// No description provided for @ocWhatIsShort.
  ///
  /// In en, this message translates to:
  /// **'What is open challenge'**
  String get ocWhatIsShort;

  /// No description provided for @ocPickedForYou.
  ///
  /// In en, this message translates to:
  /// **'Picked for you'**
  String get ocPickedForYou;

  /// No description provided for @commLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get commLinkFailed;

  /// No description provided for @commFighting.
  ///
  /// In en, this message translates to:
  /// **'fighting a battle'**
  String get commFighting;

  /// No description provided for @commAvailable.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get commAvailable;

  /// No description provided for @commBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get commBlockTitle;

  /// No description provided for @commBlockBody.
  ///
  /// In en, this message translates to:
  /// **'This will close this chat and block them.'**
  String get commBlockBody;

  /// No description provided for @commSignInMsg.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send messages.'**
  String get commSignInMsg;

  /// No description provided for @commChatStartSignIn.
  ///
  /// In en, this message translates to:
  /// **'Could not start chat. Please sign in again.'**
  String get commChatStartSignIn;

  /// No description provided for @commSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get commSendMessage;

  /// No description provided for @commThatsAll.
  ///
  /// In en, this message translates to:
  /// **'That\'s all'**
  String get commThatsAll;

  /// No description provided for @bcSubInvite.
  ///
  /// In en, this message translates to:
  /// **'Battle vs {name} · 10 MCQs · Timed ({mins} min)'**
  String bcSubInvite(String name, int mins);

  /// No description provided for @bcSubPick.
  ///
  /// In en, this message translates to:
  /// **'Pick one subject or mixed misc · 10 MCQs · Timed ({mins} min)'**
  String bcSubPick(int mins);

  /// No description provided for @bcErrSetup.
  ///
  /// In en, this message translates to:
  /// **'Battle setup failed ({code}).'**
  String bcErrSetup(String code);

  /// No description provided for @bwJoinWindow.
  ///
  /// In en, this message translates to:
  /// **'If your opponent joins within {window}, you can start the battle. Time remaining: {remaining}.'**
  String bwJoinWindow(String window, String remaining);

  /// No description provided for @bsoSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{name} has submitted; unanswered questions stay blank.'**
  String bsoSubmitted(String name);

  /// No description provided for @bsoLockedAll.
  ///
  /// In en, this message translates to:
  /// **'{name} has locked in every answer.'**
  String bsoLockedAll(String name);

  /// No description provided for @bsoStillWorking.
  ///
  /// In en, this message translates to:
  /// **'{name} is still working through the paper.'**
  String bsoStillWorking(String name);

  /// No description provided for @bsoCloseBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is still answering. Stop the live duel anyway?'**
  String bsoCloseBody(String name);

  /// No description provided for @bsoLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is still answering. Do you want to stop watching?'**
  String bsoLeaveBody(String name);

  /// No description provided for @bjSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join this battle.'**
  String get bjSignIn;

  /// No description provided for @bjNotFound.
  ///
  /// In en, this message translates to:
  /// **'This battle was not found. It may have expired.'**
  String get bjNotFound;

  /// No description provided for @bjNotPvp.
  ///
  /// In en, this message translates to:
  /// **'This link is not for a player-vs-player battle.'**
  String get bjNotPvp;

  /// No description provided for @bjWrongAccount.
  ///
  /// In en, this message translates to:
  /// **'This invite was sent to a different account.'**
  String get bjWrongAccount;

  /// No description provided for @bjClosed.
  ///
  /// In en, this message translates to:
  /// **'This battle is no longer accepting joins. It may have already started.'**
  String get bjClosed;

  /// No description provided for @bjIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Battle data is incomplete.'**
  String get bjIncomplete;

  /// No description provided for @bjJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not join battle.'**
  String get bjJoinFailed;

  /// No description provided for @bjTitle.
  ///
  /// In en, this message translates to:
  /// **'Join battle'**
  String get bjTitle;

  /// No description provided for @bjSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get bjSomethingWrong;

  /// No description provided for @commonHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get commonHome;

  /// No description provided for @brTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle Result'**
  String get brTitle;

  /// No description provided for @commonBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get commonBackToHome;

  /// No description provided for @bcTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure battle'**
  String get bcTitle;

  /// No description provided for @bcPick.
  ///
  /// In en, this message translates to:
  /// **'Pick your battlefield'**
  String get bcPick;

  /// No description provided for @bcMisc.
  ///
  /// In en, this message translates to:
  /// **'Misc'**
  String get bcMisc;

  /// No description provided for @bcTimerNote.
  ///
  /// In en, this message translates to:
  /// **'Timer runs during the battle. Answers lock in once chosen, with explanations shown so you learn as you go.'**
  String get bcTimerNote;

  /// No description provided for @bcLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subjects'**
  String get bcLoadFailed;

  /// No description provided for @bcUnblockFirst.
  ///
  /// In en, this message translates to:
  /// **'Unblock this player in Community before inviting them.'**
  String get bcUnblockFirst;

  /// No description provided for @bcErrPermission.
  ///
  /// In en, this message translates to:
  /// **'Could not save the battle room. Sign in and try again.'**
  String get bcErrPermission;

  /// No description provided for @bcErrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This service is temporarily unavailable. Check your connection and try again.'**
  String get bcErrUnavailable;

  /// No description provided for @bcErrTimeout.
  ///
  /// In en, this message translates to:
  /// **'Saving the battle timed out. Check your internet connection and try again.'**
  String get bcErrTimeout;

  /// No description provided for @bwLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave match?'**
  String get bwLeaveTitle;

  /// No description provided for @bwLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your opponent may still be waiting in the lobby.'**
  String get bwLeaveBody;

  /// No description provided for @bwStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get bwStay;

  /// No description provided for @bwStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start battle. Try again.'**
  String get bwStartFailed;

  /// No description provided for @bwMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get bwMatch;

  /// No description provided for @bwBattleId.
  ///
  /// In en, this message translates to:
  /// **'Battle ID'**
  String get bwBattleId;

  /// No description provided for @bw2Joined.
  ///
  /// In en, this message translates to:
  /// **'2 joined'**
  String get bw2Joined;

  /// No description provided for @commonYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonYou;

  /// No description provided for @bwStartingSoon.
  ///
  /// In en, this message translates to:
  /// **'Please wait… battle is starting in a few seconds.'**
  String get bwStartingSoon;

  /// No description provided for @bwOppJoined.
  ///
  /// In en, this message translates to:
  /// **'Opponent joined. Start the battle when you are ready.'**
  String get bwOppJoined;

  /// No description provided for @bwWaitOppJoin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your opponent to open the invite and join.'**
  String get bwWaitOppJoin;

  /// No description provided for @bwStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting battle…'**
  String get bwStarting;

  /// No description provided for @bwWaitHost.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to start the battle.'**
  String get bwWaitHost;

  /// No description provided for @bwOppInLobby.
  ///
  /// In en, this message translates to:
  /// **'Opponent in lobby'**
  String get bwOppInLobby;

  /// No description provided for @bwWaitOpp.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent'**
  String get bwWaitOpp;

  /// No description provided for @bwTimedOut.
  ///
  /// In en, this message translates to:
  /// **'We timed out while waiting for your opponent to join. You can keep waiting in case they are slow, or go back.'**
  String get bwTimedOut;

  /// No description provided for @commonGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get commonGoBack;

  /// No description provided for @bwKeepWaiting.
  ///
  /// In en, this message translates to:
  /// **'Keep waiting'**
  String get bwKeepWaiting;

  /// No description provided for @bshScores.
  ///
  /// In en, this message translates to:
  /// **'Scores'**
  String get bshScores;

  /// No description provided for @bshFinished.
  ///
  /// In en, this message translates to:
  /// **'Battle finished'**
  String get bshFinished;

  /// No description provided for @bsnTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit your answers?'**
  String get bsnTitle;

  /// No description provided for @bsnBodyWatch.
  ///
  /// In en, this message translates to:
  /// **'Your score will lock in. You can watch your opponent finish on a live board, or go straight to results.'**
  String get bsnBodyWatch;

  /// No description provided for @bsnBodyPlain.
  ///
  /// In en, this message translates to:
  /// **'Your score will lock in and you will see the outcome.'**
  String get bsnBodyPlain;

  /// No description provided for @bsnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue battle'**
  String get bsnContinue;

  /// No description provided for @bsnWatch.
  ///
  /// In en, this message translates to:
  /// **'Submit and Watch their progress'**
  String get bsnWatch;

  /// No description provided for @bsnSeeResults.
  ///
  /// In en, this message translates to:
  /// **'Submit & see results'**
  String get bsnSeeResults;

  /// No description provided for @bsoYourOpp.
  ///
  /// In en, this message translates to:
  /// **'Your opponent'**
  String get bsoYourOpp;

  /// No description provided for @bsoTie.
  ///
  /// In en, this message translates to:
  /// **'Tie on points.'**
  String get bsoTie;

  /// No description provided for @bsoYouAhead.
  ///
  /// In en, this message translates to:
  /// **'You were ahead on points.'**
  String get bsoYouAhead;

  /// No description provided for @bsoOppAhead.
  ///
  /// In en, this message translates to:
  /// **'Your opponent was ahead on points.'**
  String get bsoOppAhead;

  /// No description provided for @bsoYouAheadNow.
  ///
  /// In en, this message translates to:
  /// **'You are ahead on points (for now).'**
  String get bsoYouAheadNow;

  /// No description provided for @bsoOppAheadNow.
  ///
  /// In en, this message translates to:
  /// **'Your opponent is ahead on points (for now).'**
  String get bsoOppAheadNow;

  /// No description provided for @bsoClose.
  ///
  /// In en, this message translates to:
  /// **'Scores are very close.'**
  String get bsoClose;

  /// No description provided for @bsoTimerEnded.
  ///
  /// In en, this message translates to:
  /// **'The timer window ended; the room will not add more live marks.'**
  String get bsoTimerEnded;

  /// No description provided for @bsoCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close live duel?'**
  String get bsoCloseTitle;

  /// No description provided for @bsoStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get bsoStop;

  /// No description provided for @bsoLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the live board?'**
  String get bsoLeaveTitle;

  /// No description provided for @bsoKeepWatching.
  ///
  /// In en, this message translates to:
  /// **'Keep watching'**
  String get bsoKeepWatching;

  /// No description provided for @bsoBattleOver.
  ///
  /// In en, this message translates to:
  /// **'Battle over'**
  String get bsoBattleOver;

  /// No description provided for @bsoLiveDuel.
  ///
  /// In en, this message translates to:
  /// **'Live duel'**
  String get bsoLiveDuel;

  /// No description provided for @bsoStopFollowing.
  ///
  /// In en, this message translates to:
  /// **'Stop following'**
  String get bsoStopFollowing;

  /// No description provided for @bsoClosePanel.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get bsoClosePanel;

  /// No description provided for @bcfSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {error}'**
  String bcfSendFailed(String error);

  /// No description provided for @bcfLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages: {error}'**
  String bcfLoadFailed(String error);

  /// No description provided for @bsbAcc.
  ///
  /// In en, this message translates to:
  /// **'{pct}% accuracy · {correct} correct, {wrong} wrong'**
  String bsbAcc(int pct, int correct, int wrong);

  /// No description provided for @bsbAccUn.
  ///
  /// In en, this message translates to:
  /// **'{pct}% accuracy · {correct} correct, {wrong} wrong, {un} unanswered'**
  String bsbAccUn(int pct, int correct, int wrong, int un);

  /// No description provided for @bsbAheadBy.
  ///
  /// In en, this message translates to:
  /// **'You were ahead by {delta} points'**
  String bsbAheadBy(String delta);

  /// No description provided for @bsbLedBy.
  ///
  /// In en, this message translates to:
  /// **'They led by {delta} points'**
  String bsbLedBy(String delta);

  /// No description provided for @btOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open battle.'**
  String get btOpenFailed;

  /// No description provided for @btLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave battle?'**
  String get btLeaveTitle;

  /// No description provided for @btLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Going back means you want to quit the battle, but your progress will be saved.'**
  String get btLeaveBody;

  /// No description provided for @btGridTooltip.
  ///
  /// In en, this message translates to:
  /// **'Question grid'**
  String get btGridTooltip;

  /// No description provided for @btWaitJoin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your opponent to join before you can answer.'**
  String get btWaitJoin;

  /// No description provided for @btRevisit.
  ///
  /// In en, this message translates to:
  /// **'Revisit'**
  String get btRevisit;

  /// No description provided for @btSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit battle. Please retry.'**
  String get btSubmitFailed;

  /// No description provided for @btGridTitle.
  ///
  /// In en, this message translates to:
  /// **'Question Grid'**
  String get btGridTitle;

  /// No description provided for @btAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get btAnswer;

  /// No description provided for @bcfCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close chat?'**
  String get bcfCloseTitle;

  /// No description provided for @bcfCloseBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to hide this battle chat?'**
  String get bcfCloseBody;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @bcfStartConv.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation.'**
  String get bcfStartConv;

  /// No description provided for @bcfHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get bcfHint;

  /// No description provided for @commonOpponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get commonOpponent;

  /// No description provided for @bsbNoAttempts.
  ///
  /// In en, this message translates to:
  /// **'no scored attempts'**
  String get bsbNoAttempts;

  /// No description provided for @bsbYouCaps.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get bsbYouCaps;

  /// No description provided for @bsbTieTitle.
  ///
  /// In en, this message translates to:
  /// **'Neck and neck!'**
  String get bsbTieTitle;

  /// No description provided for @bsbTieSub.
  ///
  /// In en, this message translates to:
  /// **'It is a tie. That was intense.'**
  String get bsbTieSub;

  /// No description provided for @bsbLoseTitle.
  ///
  /// In en, this message translates to:
  /// **'So close!'**
  String get bsbLoseTitle;

  /// No description provided for @bsbLoseSub.
  ///
  /// In en, this message translates to:
  /// **'You lost this one. Come back stronger.'**
  String get bsbLoseSub;

  /// No description provided for @bsbTiedPoints.
  ///
  /// In en, this message translates to:
  /// **'Scores are tied on points.'**
  String get bsbTiedPoints;

  /// No description provided for @bsbVictory.
  ///
  /// In en, this message translates to:
  /// **'Victory unlocked!'**
  String get bsbVictory;

  /// No description provided for @bsbOutplayed.
  ///
  /// In en, this message translates to:
  /// **'You outplayed your opponent this round.'**
  String get bsbOutplayed;

  /// No description provided for @bsbStacked.
  ///
  /// In en, this message translates to:
  /// **'How you stacked up'**
  String get bsbStacked;

  /// No description provided for @bsbTiePts.
  ///
  /// In en, this message translates to:
  /// **'Tie on points'**
  String get bsbTiePts;

  /// No description provided for @bspWaitJoin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your opponent to join…'**
  String get bspWaitJoin;

  /// No description provided for @bspRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record your answer.'**
  String get bspRecordFailed;

  /// No description provided for @bspSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit battle.'**
  String get bspSubmitFailed;

  /// No description provided for @bspPermDenied.
  ///
  /// In en, this message translates to:
  /// **'Battle permission denied.'**
  String get bspPermDenied;

  /// No description provided for @bspNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Please check internet and retry.'**
  String get bspNetwork;

  /// No description provided for @bspStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start online battle. Please retry.'**
  String get bspStartFailed;

  /// No description provided for @bicSent.
  ///
  /// In en, this message translates to:
  /// **'Battle invite sent.'**
  String get bicSent;

  /// No description provided for @bicNoToken.
  ///
  /// In en, this message translates to:
  /// **'Invitee has no push token yet. They can still join using the session link.'**
  String get bicNoToken;

  /// No description provided for @bicPushFailed.
  ///
  /// In en, this message translates to:
  /// **'Push could not be sent. They can still join using the session link.'**
  String get bicPushFailed;

  /// No description provided for @bicUnclear.
  ///
  /// In en, this message translates to:
  /// **'Invite status unclear. Please try again later.'**
  String get bicUnclear;

  /// No description provided for @gmSetTitle.
  ///
  /// In en, this message translates to:
  /// **'{subject} · Set {n}/{total}'**
  String gmSetTitle(String subject, int n, int total);

  /// No description provided for @gmCorrectOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct'**
  String gmCorrectOfTotal(int correct, int total);

  /// No description provided for @gmOddTitle.
  ///
  /// In en, this message translates to:
  /// **'Odd One Out · {subject}'**
  String gmOddTitle(String subject);

  /// No description provided for @gmNOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String gmNOfTotal(int n, int total);

  /// No description provided for @gmFobStep2.
  ///
  /// In en, this message translates to:
  /// **'You have {seconds} seconds on the clock.'**
  String gmFobStep2(int seconds);

  /// No description provided for @gmSubjNOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{subject} · {n} of {total}'**
  String gmSubjNOfTotal(String subject, int n, int total);

  /// No description provided for @gmDuelYouWin.
  ///
  /// In en, this message translates to:
  /// **'You win, {name}'**
  String gmDuelYouWin(String name);

  /// No description provided for @gmDuelWins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins'**
  String gmDuelWins(String name);

  /// No description provided for @gmDescMemory.
  ///
  /// In en, this message translates to:
  /// **'Match terms to answers — train recall.'**
  String get gmDescMemory;

  /// No description provided for @gmDescTimeline.
  ///
  /// In en, this message translates to:
  /// **'Put events in the right order.'**
  String get gmDescTimeline;

  /// No description provided for @gmOddStep2.
  ///
  /// In en, this message translates to:
  /// **'Pick the odd one out.'**
  String get gmOddStep2;

  /// No description provided for @gmDescFob.
  ///
  /// In en, this message translates to:
  /// **'Ten seconds. Trust your gut.'**
  String get gmDescFob;

  /// No description provided for @gmDescCtd.
  ///
  /// In en, this message translates to:
  /// **'Find the hidden link.'**
  String get gmDescCtd;

  /// No description provided for @gmDescDuel.
  ///
  /// In en, this message translates to:
  /// **'One phone, two players, fastest wins.'**
  String get gmDescDuel;

  /// No description provided for @gmStartN.
  ///
  /// In en, this message translates to:
  /// **'Start · {n} questions'**
  String gmStartN(int n);

  /// No description provided for @gmTlStep1.
  ///
  /// In en, this message translates to:
  /// **'Read the shuffled events for the set.'**
  String get gmTlStep1;

  /// No description provided for @gmTlStep2.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag rows to place them in order.'**
  String get gmTlStep2;

  /// No description provided for @gmTlStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap Check to reveal years and what you got right.'**
  String get gmTlStep3;

  /// No description provided for @gmNextSet.
  ///
  /// In en, this message translates to:
  /// **'Next set →'**
  String get gmNextSet;

  /// No description provided for @gmCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get gmCheck;

  /// No description provided for @gmNoContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get gmNoContent;

  /// No description provided for @gmTlHint.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag to reorder, then check.'**
  String get gmTlHint;

  /// No description provided for @gmErrNoTimeline.
  ///
  /// In en, this message translates to:
  /// **'No timeline sets found.'**
  String get gmErrNoTimeline;

  /// No description provided for @gmOddStep1.
  ///
  /// In en, this message translates to:
  /// **'Look at all four options.'**
  String get gmOddStep1;

  /// No description provided for @gmOddStep3.
  ///
  /// In en, this message translates to:
  /// **'See the highlight and explanation instantly.'**
  String get gmOddStep3;

  /// No description provided for @gmNext.
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get gmNext;

  /// No description provided for @gmErrNoOdd.
  ///
  /// In en, this message translates to:
  /// **'No odd-one-out items found.'**
  String get gmErrNoOdd;

  /// No description provided for @gmFobStep1.
  ///
  /// In en, this message translates to:
  /// **'Read the statement fast.'**
  String get gmFobStep1;

  /// No description provided for @gmFobStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap FACT or BLUFF before time runs out.'**
  String get gmFobStep3;

  /// No description provided for @gmGotIt.
  ///
  /// In en, this message translates to:
  /// **'You got it'**
  String get gmGotIt;

  /// No description provided for @gmNotThisTime.
  ///
  /// In en, this message translates to:
  /// **'Not this time'**
  String get gmNotThisTime;

  /// No description provided for @gmTooSlow.
  ///
  /// In en, this message translates to:
  /// **'Too slow'**
  String get gmTooSlow;

  /// No description provided for @gmErrNoFob.
  ///
  /// In en, this message translates to:
  /// **'No fact-or-bluff items found.'**
  String get gmErrNoFob;

  /// No description provided for @gmCtdStep1.
  ///
  /// In en, this message translates to:
  /// **'Read all three clues together.'**
  String get gmCtdStep1;

  /// No description provided for @gmCtdStep2.
  ///
  /// In en, this message translates to:
  /// **'Think about what links them.'**
  String get gmCtdStep2;

  /// No description provided for @gmCtdStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap the option that ties them together.'**
  String get gmCtdStep3;

  /// No description provided for @gmCtdHidden.
  ///
  /// In en, this message translates to:
  /// **'What\'s the hidden link?'**
  String get gmCtdHidden;

  /// No description provided for @gmErrNoCtd.
  ///
  /// In en, this message translates to:
  /// **'No connect-the-dots items found.'**
  String get gmErrNoCtd;

  /// No description provided for @gmDuelStart.
  ///
  /// In en, this message translates to:
  /// **'Start match'**
  String get gmDuelStart;

  /// No description provided for @gmDuelStep1.
  ///
  /// In en, this message translates to:
  /// **'Lay the phone flat on the table between you.'**
  String get gmDuelStep1;

  /// No description provided for @gmDuelStep2.
  ///
  /// In en, this message translates to:
  /// **'Same question, 2 options each — mirrored top and bottom.'**
  String get gmDuelStep2;

  /// No description provided for @gmDuelStep3.
  ///
  /// In en, this message translates to:
  /// **'Both pick (or pass) first — correct answer reveals only when both have locked in.'**
  String get gmDuelStep3;

  /// No description provided for @gmDuelNoQ.
  ///
  /// In en, this message translates to:
  /// **'No question'**
  String get gmDuelNoQ;

  /// No description provided for @gmDuelPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get gmDuelPass;

  /// No description provided for @gmDuelPassedWait.
  ///
  /// In en, this message translates to:
  /// **'Passed — waiting…'**
  String get gmDuelPassedWait;

  /// No description provided for @gmDuelPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get gmDuelPassed;

  /// No description provided for @gmDuelPoint.
  ///
  /// In en, this message translates to:
  /// **'Point!'**
  String get gmDuelPoint;

  /// No description provided for @gmDuelEven.
  ///
  /// In en, this message translates to:
  /// **'Evenly matched'**
  String get gmDuelEven;

  /// No description provided for @gmDuelExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get gmDuelExit;

  /// No description provided for @gmDuelRematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get gmDuelRematch;

  /// No description provided for @gmErrNoDuel.
  ///
  /// In en, this message translates to:
  /// **'No duel questions found.'**
  String get gmErrNoDuel;

  /// No description provided for @gmSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get gmSessionComplete;

  /// No description provided for @gmSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid recall.'**
  String get gmSolid;

  /// No description provided for @gmAnotherPass.
  ///
  /// In en, this message translates to:
  /// **'Worth another pass.'**
  String get gmAnotherPass;

  /// No description provided for @gmPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get gmPlayAgain;

  /// No description provided for @gmBackToGames.
  ///
  /// In en, this message translates to:
  /// **'Back to games'**
  String get gmBackToGames;

  /// No description provided for @gmHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get gmHowToPlay;

  /// No description provided for @gmDontShow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get gmDontShow;

  /// No description provided for @gmHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recall, timeline, fact-or-bluff — train the UPSC way'**
  String get gmHomeSubtitle;

  /// No description provided for @gmConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get gmConfig;

  /// No description provided for @gmSetup.
  ///
  /// In en, this message translates to:
  /// **'Set up your session'**
  String get gmSetup;

  /// No description provided for @gmLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get gmLanguage;

  /// No description provided for @gmSubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get gmSubjects;

  /// No description provided for @gmAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gmAll;

  /// No description provided for @gmStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get gmStart;

  /// No description provided for @mpPairsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} pairs'**
  String mpPairsCount(int n);

  /// No description provided for @mpUnlock.
  ///
  /// In en, this message translates to:
  /// **'To unlock, attempt {n} {subject} questions'**
  String mpUnlock(int n, String subject);

  /// No description provided for @mpUnlockDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String mpUnlockDone(int done, int total);

  /// No description provided for @mpDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day ago} other{{n} days ago}}'**
  String mpDaysAgo(int n);

  /// No description provided for @mpWkAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} wk ago'**
  String mpWkAgo(int n);

  /// No description provided for @mpMoAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} mo ago'**
  String mpMoAgo(int n);

  /// No description provided for @mpMatched.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} matched'**
  String mpMatched(int done, int total);

  /// No description provided for @mpTimeErrors.
  ///
  /// In en, this message translates to:
  /// **'{time} · {n} errors'**
  String mpTimeErrors(String time, int n);

  /// No description provided for @mpStarsVerdict.
  ///
  /// In en, this message translates to:
  /// **'{stars} / 5 · {verdict}'**
  String mpStarsVerdict(int stars, String verdict);

  /// No description provided for @mpWrongPairs.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 pair you got wrong} other{{n} pairs you got wrong}}'**
  String mpWrongPairs(int n);

  /// No description provided for @mpTopics.
  ///
  /// In en, this message translates to:
  /// **'{n} topics'**
  String mpTopics(int n);

  /// No description provided for @mpQuickDrill.
  ///
  /// In en, this message translates to:
  /// **'Quick {n}-pair recall drill — tap Start when you are ready.'**
  String mpQuickDrill(int n);

  /// No description provided for @mpPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get mpPlayNow;

  /// No description provided for @mpCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get mpCards;

  /// No description provided for @mpList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get mpList;

  /// No description provided for @mpTapRow.
  ///
  /// In en, this message translates to:
  /// **'Tap a row to reveal its answer'**
  String get mpTapRow;

  /// No description provided for @mpNeverPlayed.
  ///
  /// In en, this message translates to:
  /// **'Never played'**
  String get mpNeverPlayed;

  /// No description provided for @mpToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get mpToday;

  /// No description provided for @mpYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get mpYesterday;

  /// No description provided for @mpPairsInRound.
  ///
  /// In en, this message translates to:
  /// **'Pairs in round'**
  String get mpPairsInRound;

  /// No description provided for @mpBestTime.
  ///
  /// In en, this message translates to:
  /// **'Best time'**
  String get mpBestTime;

  /// No description provided for @mpLastPlayed.
  ///
  /// In en, this message translates to:
  /// **'Last played'**
  String get mpLastPlayed;

  /// No description provided for @mpRevise.
  ///
  /// In en, this message translates to:
  /// **'Revise'**
  String get mpRevise;

  /// No description provided for @mpErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get mpErrors;

  /// No description provided for @mpProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get mpProgress;

  /// No description provided for @mpTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get mpTerms;

  /// No description provided for @mpAnswers.
  ///
  /// In en, this message translates to:
  /// **'Answers'**
  String get mpAnswers;

  /// No description provided for @mpAllMatched.
  ///
  /// In en, this message translates to:
  /// **'All pairs matched'**
  String get mpAllMatched;

  /// No description provided for @mpPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get mpPaused;

  /// No description provided for @mpResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get mpResume;

  /// No description provided for @mpQuitToSet.
  ///
  /// In en, this message translates to:
  /// **'Quit to set'**
  String get mpQuitToSet;

  /// No description provided for @mpComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get mpComplete;

  /// No description provided for @mpTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get mpTime;

  /// No description provided for @mpTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get mpTotalTime;

  /// No description provided for @mpTotalErrors.
  ///
  /// In en, this message translates to:
  /// **'Total errors'**
  String get mpTotalErrors;

  /// No description provided for @mpPairsCleared.
  ///
  /// In en, this message translates to:
  /// **'Pairs cleared'**
  String get mpPairsCleared;

  /// No description provided for @mpNewBest.
  ///
  /// In en, this message translates to:
  /// **'New best time for this set'**
  String get mpNewBest;

  /// No description provided for @mpFullRecall.
  ///
  /// In en, this message translates to:
  /// **'No wrong taps — full recall'**
  String get mpFullRecall;

  /// No description provided for @mpTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try another set'**
  String get mpTryAnother;

  /// No description provided for @mpBackToSets.
  ///
  /// In en, this message translates to:
  /// **'Back to sets'**
  String get mpBackToSets;

  /// No description provided for @mpV5.
  ///
  /// In en, this message translates to:
  /// **'Razor sharp'**
  String get mpV5;

  /// No description provided for @mpV4.
  ///
  /// In en, this message translates to:
  /// **'Strong recall'**
  String get mpV4;

  /// No description provided for @mpV3.
  ///
  /// In en, this message translates to:
  /// **'Solid, can be faster'**
  String get mpV3;

  /// No description provided for @mpV2.
  ///
  /// In en, this message translates to:
  /// **'Recall is slow'**
  String get mpV2;

  /// No description provided for @mpV1.
  ///
  /// In en, this message translates to:
  /// **'Needs heavy revision'**
  String get mpV1;

  /// No description provided for @mpTagline.
  ///
  /// In en, this message translates to:
  /// **'Learn. Recall. Master.'**
  String get mpTagline;

  /// No description provided for @mpBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse by Subject'**
  String get mpBrowse;

  /// No description provided for @mpHowItWorksQ.
  ///
  /// In en, this message translates to:
  /// **'How it works?'**
  String get mpHowItWorksQ;

  /// No description provided for @mpGroupedNote.
  ///
  /// In en, this message translates to:
  /// **'Topics are grouped by difficulty. Earn stars as you master harder topics!'**
  String get mpGroupedNote;

  /// No description provided for @mpTerm.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get mpTerm;

  /// No description provided for @mpTapTerm.
  ///
  /// In en, this message translates to:
  /// **'Tap to see term'**
  String get mpTapTerm;

  /// No description provided for @mpTapFlip.
  ///
  /// In en, this message translates to:
  /// **'Tap to flip · swipe any direction for next'**
  String get mpTapFlip;

  /// No description provided for @mpPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get mpPlay;

  /// No description provided for @mpHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get mpHowItWorks;

  /// No description provided for @mpTrain.
  ///
  /// In en, this message translates to:
  /// **'Train recall in under a minute'**
  String get mpTrain;

  /// No description provided for @mpStep1T.
  ///
  /// In en, this message translates to:
  /// **'Pick a subject'**
  String get mpStep1T;

  /// No description provided for @mpStep1B.
  ///
  /// In en, this message translates to:
  /// **'Browse Polity, History, Geography, and more.'**
  String get mpStep1B;

  /// No description provided for @mpStep2T.
  ///
  /// In en, this message translates to:
  /// **'Choose a topic'**
  String get mpStep2T;

  /// No description provided for @mpStep2B.
  ///
  /// In en, this message translates to:
  /// **'Each set has a difficulty tag — easy to hard.'**
  String get mpStep2B;

  /// No description provided for @mpStep3T.
  ///
  /// In en, this message translates to:
  /// **'Match the pairs'**
  String get mpStep3T;

  /// No description provided for @mpStep3B.
  ///
  /// In en, this message translates to:
  /// **'Tap a term, then its answer. Beat your best time and earn stars.'**
  String get mpStep3B;

  /// No description provided for @mpGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get mpGotIt;

  /// No description provided for @mpOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open game'**
  String get mpOpenFailed;

  /// No description provided for @mpGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get mpGoHome;

  /// No description provided for @mpRevisionGame.
  ///
  /// In en, this message translates to:
  /// **'Revision Game'**
  String get mpRevisionGame;

  /// No description provided for @mpBrowseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse all sets'**
  String get mpBrowseAll;

  /// No description provided for @mpSetDetail.
  ///
  /// In en, this message translates to:
  /// **'Set detail'**
  String get mpSetDetail;

  /// No description provided for @mpSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get mpSummary;

  /// No description provided for @chatNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in. Please sign in and try again.'**
  String get chatNotSignedIn;

  /// No description provided for @chatBlockedSend.
  ///
  /// In en, this message translates to:
  /// **'You have blocked this person. Unblock them in Settings to send messages.'**
  String get chatBlockedSend;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message failed to send: {error}'**
  String chatSendFailed(String error);

  /// No description provided for @cpUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile: {error}'**
  String cpUpdateFailed(String error);

  /// No description provided for @cpPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy note: Apple may not share your real email/name on future sign-ins. We store this name only to show it inside {app}.'**
  String cpPrivacy(String app);

  /// No description provided for @fpCanYou.
  ///
  /// In en, this message translates to:
  /// **'{line}. Can you?'**
  String fpCanYou(String line);

  /// No description provided for @fpPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo: {name}'**
  String fpPhoto(String name);

  /// No description provided for @fpSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {name}'**
  String fpSource(String name);

  /// No description provided for @fpMetaLine.
  ///
  /// In en, this message translates to:
  /// **'{date}  ·  {n} min read  ·  High Relevance'**
  String fpMetaLine(String date, int n);

  /// No description provided for @fpBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{a} attempted · {c} got it right · {w} got it wrong'**
  String fpBreakdown(int a, int c, int w);

  /// No description provided for @fpTrap.
  ///
  /// In en, this message translates to:
  /// **'{a} attempted · {p}% fell for it'**
  String fpTrap(int a, int p);

  /// No description provided for @chatListTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatListTitle;

  /// No description provided for @chatNone.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chatNone;

  /// No description provided for @chatStartConv.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get chatStartConv;

  /// No description provided for @chatStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start chat. Go back and try again.'**
  String get chatStartFailed;

  /// No description provided for @chatSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to send messages.'**
  String get chatSignInAgain;

  /// No description provided for @chatBlockedHidden.
  ///
  /// In en, this message translates to:
  /// **'You have blocked this person. Their messages are hidden. Unblock them in Settings to chat.'**
  String get chatBlockedHidden;

  /// No description provided for @chatOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get chatOpenLink;

  /// No description provided for @cpPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get cpPhotoUpdated;

  /// No description provided for @cpNameNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'UPSC War is not allowed in name'**
  String get cpNameNotAllowed;

  /// No description provided for @cpEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get cpEnterName;

  /// No description provided for @cpProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get cpProfileUpdated;

  /// No description provided for @cpTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get cpTitle;

  /// No description provided for @cpSignInContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get cpSignInContinue;

  /// No description provided for @cpConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect your account to sync your profile and progress across devices.'**
  String get cpConnect;

  /// No description provided for @cpSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get cpSigningIn;

  /// No description provided for @cpSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get cpSignIn;

  /// No description provided for @cpHelps.
  ///
  /// In en, this message translates to:
  /// **'This helps others recognize you in Community and chat.'**
  String get cpHelps;

  /// No description provided for @cpPhotoWeb.
  ///
  /// In en, this message translates to:
  /// **'Profile photo can be changed in the Android or iOS app.'**
  String get cpPhotoWeb;

  /// No description provided for @cpYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get cpYourName;

  /// No description provided for @cpNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sachin'**
  String get cpNameHint;

  /// No description provided for @cpSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get cpSaving;

  /// No description provided for @cpPhotoAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can change your photo anytime from Profile.'**
  String get cpPhotoAnytime;

  /// No description provided for @ddOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open revision queue'**
  String get ddOpenFailed;

  /// No description provided for @fpWhatsThis.
  ///
  /// In en, this message translates to:
  /// **'What\'s this?'**
  String get fpWhatsThis;

  /// No description provided for @fpNone.
  ///
  /// In en, this message translates to:
  /// **'No CA Shots yet. Breaking CA briefings will show up here.'**
  String get fpNone;

  /// No description provided for @fpWhatAre.
  ///
  /// In en, this message translates to:
  /// **'What are CA Shots?'**
  String get fpWhatAre;

  /// No description provided for @fpWhatBody.
  ///
  /// In en, this message translates to:
  /// **'Think of these as short daily drills — shots you can take every day to prepare for your final battle.'**
  String get fpWhatBody;

  /// No description provided for @fpAlertsT.
  ///
  /// In en, this message translates to:
  /// **'Frequent alerts'**
  String get fpAlertsT;

  /// No description provided for @fpAlertsB.
  ///
  /// In en, this message translates to:
  /// **'You get notified when a UPSC-relevant article is worth your attention.'**
  String get fpAlertsB;

  /// No description provided for @fpMcqT.
  ///
  /// In en, this message translates to:
  /// **'One focused MCQ'**
  String get fpMcqT;

  /// No description provided for @fpMcqB.
  ///
  /// In en, this message translates to:
  /// **'Each shot gives one concept-based MCQ from that article, with explanation.'**
  String get fpMcqB;

  /// No description provided for @fpReadyT.
  ///
  /// In en, this message translates to:
  /// **'Battle readiness'**
  String get fpReadyT;

  /// No description provided for @fpReadyB.
  ///
  /// In en, this message translates to:
  /// **'Take these shots daily so your concepts stay sharp for the final battle.'**
  String get fpReadyB;

  /// No description provided for @fpNotDone.
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get fpNotDone;

  /// No description provided for @fpDoneCorrect.
  ///
  /// In en, this message translates to:
  /// **'Done · Correct'**
  String get fpDoneCorrect;

  /// No description provided for @fpDoneWrong.
  ///
  /// In en, this message translates to:
  /// **'Done · Wrong'**
  String get fpDoneWrong;

  /// No description provided for @fpUndated.
  ///
  /// In en, this message translates to:
  /// **'Undated'**
  String get fpUndated;

  /// No description provided for @fpReadSource.
  ///
  /// In en, this message translates to:
  /// **'Read source'**
  String get fpReadSource;

  /// No description provided for @fpShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get fpShare;

  /// No description provided for @fpLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this CA Shot.'**
  String get fpLoadFailed;

  /// No description provided for @fpCheckNet.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get fpCheckNet;

  /// No description provided for @fpNewsSummary.
  ///
  /// In en, this message translates to:
  /// **'News Summary'**
  String get fpNewsSummary;

  /// No description provided for @fpShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get fpShowLess;

  /// No description provided for @fpReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get fpReadMore;

  /// No description provided for @fpWhyRelevant.
  ///
  /// In en, this message translates to:
  /// **'Why is this relevant for UPSC?'**
  String get fpWhyRelevant;

  /// No description provided for @fpReviewAttempt.
  ///
  /// In en, this message translates to:
  /// **'Review your MCQ Attempt'**
  String get fpReviewAttempt;

  /// No description provided for @fpAttemptMcq.
  ///
  /// In en, this message translates to:
  /// **'Attempt the MCQ'**
  String get fpAttemptMcq;

  /// No description provided for @fpExpired.
  ///
  /// In en, this message translates to:
  /// **'This CA Shot has expired.'**
  String get fpExpired;

  /// No description provided for @fpAttempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt'**
  String get fpAttempt;

  /// No description provided for @fpPickSee.
  ///
  /// In en, this message translates to:
  /// **'Pick an option to see answer and explanation.'**
  String get fpPickSee;

  /// No description provided for @fpCorrectBang.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get fpCorrectBang;

  /// No description provided for @fpBackToShot.
  ///
  /// In en, this message translates to:
  /// **'Back to CA Shot'**
  String get fpBackToShot;

  /// No description provided for @fpHomeSub.
  ///
  /// In en, this message translates to:
  /// **'Breaking news brief + 1 MCQ based on it.'**
  String get fpHomeSub;

  /// No description provided for @fpAnswerThis.
  ///
  /// In en, this message translates to:
  /// **'Answer this Pulse'**
  String get fpAnswerThis;

  /// No description provided for @fpPickSubmit.
  ///
  /// In en, this message translates to:
  /// **'Pick an option to submit your answer.'**
  String get fpPickSubmit;

  /// No description provided for @fpNoAttempts.
  ///
  /// In en, this message translates to:
  /// **'No attempts yet'**
  String get fpNoAttempts;

  /// No description provided for @fpBeFirst.
  ///
  /// In en, this message translates to:
  /// **'Be the first to attempt this.'**
  String get fpBeFirst;

  /// No description provided for @tcOnlyAvail.
  ///
  /// In en, this message translates to:
  /// **'Only {n} available'**
  String tcOnlyAvail(String n);

  /// No description provided for @tcMinutesTotal.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes total'**
  String tcMinutesTotal(int n);

  /// No description provided for @tcCoach1T.
  ///
  /// In en, this message translates to:
  /// **'Pick question count'**
  String get tcCoach1T;

  /// No description provided for @tcCoach1B.
  ///
  /// In en, this message translates to:
  /// **'Choose how many questions you want in this session — 10 for a quick drill, 25 for a full practice block.'**
  String get tcCoach1B;

  /// No description provided for @tcCoach2T.
  ///
  /// In en, this message translates to:
  /// **'Choose a mode'**
  String get tcCoach2T;

  /// No description provided for @tcCoach2B.
  ///
  /// In en, this message translates to:
  /// **'Exam hides all explanations until the test ends — just like the real paper. Learning shows the answer and explanation right after each question.'**
  String get tcCoach2B;

  /// No description provided for @tcCoach3B.
  ///
  /// In en, this message translates to:
  /// **'Each question gets {n}s. Toggle this off if you prefer practising without the clock.'**
  String tcCoach3B(int n);

  /// No description provided for @glTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to {app}'**
  String glTitle(String app);

  /// No description provided for @pcDays.
  ///
  /// In en, this message translates to:
  /// **'Prelims: {n} days'**
  String pcDays(int n);

  /// No description provided for @pdLead.
  ///
  /// In en, this message translates to:
  /// **'You’re missing updates and reminders. Please enable '**
  String get pdLead;

  /// No description provided for @pdLink.
  ///
  /// In en, this message translates to:
  /// **'notifications'**
  String get pdLink;

  /// No description provided for @pdTrail.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get pdTrail;

  /// No description provided for @tcWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get tcWentWrong;

  /// No description provided for @tcConfOff.
  ///
  /// In en, this message translates to:
  /// **'Confidence rating is off'**
  String get tcConfOff;

  /// No description provided for @tcConfOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it on to track how sure you were before reveal and unlock Danger Zone insights.'**
  String get tcConfOffBody;

  /// No description provided for @tcExamDesc.
  ///
  /// In en, this message translates to:
  /// **'Simulate real conditions. Explanation after test ends.'**
  String get tcExamDesc;

  /// No description provided for @tcLearnDesc.
  ///
  /// In en, this message translates to:
  /// **'See explanation after each question.'**
  String get tcLearnDesc;

  /// No description provided for @tcNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions available for this topic.'**
  String get tcNoQuestions;

  /// No description provided for @tcTimePerQ.
  ///
  /// In en, this message translates to:
  /// **'Time per question'**
  String get tcTimePerQ;

  /// No description provided for @tcNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get tcNoLimit;

  /// No description provided for @tcStartExam.
  ///
  /// In en, this message translates to:
  /// **'Start exam'**
  String get tcStartExam;

  /// No description provided for @tcStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start learning session'**
  String get tcStartLearning;

  /// No description provided for @tcNoTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get tcNoTimeLimit;

  /// No description provided for @tcTakeTime.
  ///
  /// In en, this message translates to:
  /// **'Take as long as you need on each question.'**
  String get tcTakeTime;

  /// No description provided for @tcExamNote.
  ///
  /// In en, this message translates to:
  /// **'Exam mode is a timed test with explanations after it ends.'**
  String get tcExamNote;

  /// No description provided for @tcLearnNote.
  ///
  /// In en, this message translates to:
  /// **'No clock running — ideal for deep reading and revision.'**
  String get tcLearnNote;

  /// No description provided for @glBody.
  ///
  /// In en, this message translates to:
  /// **'Save your progress, sync stats across devices, and keep your streak safe.'**
  String get glBody;

  /// No description provided for @glSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get glSigningIn;

  /// No description provided for @glApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get glApple;

  /// No description provided for @glGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get glGoogle;

  /// No description provided for @glAgree.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Privacy Policy and to authenticate with Apple or Google via Firebase.'**
  String get glAgree;

  /// No description provided for @glReadPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read full privacy policy'**
  String get glReadPolicy;

  /// No description provided for @cuGetInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get cuGetInTouch;

  /// No description provided for @cuBody.
  ///
  /// In en, this message translates to:
  /// **'If something is unclear, you have a feature idea, or any feedback — pick what works best for you.'**
  String get cuBody;

  /// No description provided for @cuTgDirect.
  ///
  /// In en, this message translates to:
  /// **'Telegram (direct message)'**
  String get cuTgDirect;

  /// No description provided for @cuTgDirectSub.
  ///
  /// In en, this message translates to:
  /// **'Quick questions & updates'**
  String get cuTgDirectSub;

  /// No description provided for @cuTgGroup.
  ///
  /// In en, this message translates to:
  /// **'Telegram group'**
  String get cuTgGroup;

  /// No description provided for @cuTgGroupSub.
  ///
  /// In en, this message translates to:
  /// **'Community & discussion'**
  String get cuTgGroupSub;

  /// No description provided for @cuOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get cuOpenFailed;

  /// No description provided for @cuRate.
  ///
  /// In en, this message translates to:
  /// **'Rate / review'**
  String get cuRate;

  /// No description provided for @rrTitle.
  ///
  /// In en, this message translates to:
  /// **'Built by an Aspirant, for Aspirants'**
  String get rrTitle;

  /// No description provided for @rrBody1.
  ///
  /// In en, this message translates to:
  /// **'Built by an ex-UPSC aspirant who faced the same struggle of solving endless MCQs without clearly knowing where marks were being lost.'**
  String get rrBody1;

  /// No description provided for @rrBody2.
  ///
  /// In en, this message translates to:
  /// **'The goal was simple: help aspirants prepare smarter by identifying confident mistakes, danger zones, safe risk areas, and better revision priorities.'**
  String get rrBody2;

  /// No description provided for @rrJourney.
  ///
  /// In en, this message translates to:
  /// **'Read About Journey of UPSC Wars'**
  String get rrJourney;

  /// No description provided for @rrBody3.
  ///
  /// In en, this message translates to:
  /// **'If UPSC Wars is helping your preparation, your review can help other aspirants find it too.'**
  String get rrBody3;

  /// No description provided for @rrRate.
  ///
  /// In en, this message translates to:
  /// **'⭐ Rate & Review UPSC Wars'**
  String get rrRate;

  /// No description provided for @qpTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose mode'**
  String get qpTitle;

  /// No description provided for @qpSub.
  ///
  /// In en, this message translates to:
  /// **'How would you like to practice?'**
  String get qpSub;

  /// No description provided for @qpTutor.
  ///
  /// In en, this message translates to:
  /// **'Tutor Mode'**
  String get qpTutor;

  /// No description provided for @qpTutorDesc.
  ///
  /// In en, this message translates to:
  /// **'See explanations after each question'**
  String get qpTutorDesc;

  /// No description provided for @qpExam.
  ///
  /// In en, this message translates to:
  /// **'Exam Mode'**
  String get qpExam;

  /// No description provided for @qpExamDesc.
  ///
  /// In en, this message translates to:
  /// **'Get results at the end'**
  String get qpExamDesc;

  /// No description provided for @pcToday.
  ///
  /// In en, this message translates to:
  /// **'Prelims: today'**
  String get pcToday;

  /// No description provided for @pcOneDay.
  ///
  /// In en, this message translates to:
  /// **'Prelims: 1 day'**
  String get pcOneDay;

  /// No description provided for @pcTitle.
  ///
  /// In en, this message translates to:
  /// **'UPSC PRELIMS COUNTDOWN'**
  String get pcTitle;

  /// No description provided for @pcUnits.
  ///
  /// In en, this message translates to:
  /// **'Days : Hours : Min : Sec'**
  String get pcUnits;

  /// No description provided for @pdTitle.
  ///
  /// In en, this message translates to:
  /// **'You’re missing drill, CA & community alerts'**
  String get pdTitle;

  /// No description provided for @pdBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications for Daily Drill, current affairs, CA Shots, and community invites.'**
  String get pdBody;

  /// No description provided for @pdEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable alerts'**
  String get pdEnable;

  /// No description provided for @suStoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the store.'**
  String get suStoreFailed;

  /// No description provided for @suAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get suAvailable;

  /// No description provided for @suUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get suUpdate;

  /// No description provided for @suLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get suLater;

  /// No description provided for @kuTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get kuTitle;

  /// No description provided for @kuBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported.\n Kindly Update to keep practicing.'**
  String get kuBody;

  /// No description provided for @kuContinue.
  ///
  /// In en, this message translates to:
  /// **'Update from the store to continue'**
  String get kuContinue;

  /// No description provided for @vbDismissQ.
  ///
  /// In en, this message translates to:
  /// **'Dismiss?'**
  String get vbDismissQ;

  /// No description provided for @vbDismissBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? You will not be reminded of this again.'**
  String get vbDismissBody;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @vbDefault.
  ///
  /// In en, this message translates to:
  /// **'We posted a short video that may help.'**
  String get vbDefault;

  /// No description provided for @vbWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch video'**
  String get vbWatch;

  /// No description provided for @lbSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see the leaderboard'**
  String get lbSignIn;

  /// No description provided for @obgOdd.
  ///
  /// In en, this message translates to:
  /// **'Spot the one that doesn’t belong.'**
  String get obgOdd;

  /// No description provided for @obgFob.
  ///
  /// In en, this message translates to:
  /// **'Ten seconds on the clock — trust your gut.'**
  String get obgFob;

  /// No description provided for @obgCtd.
  ///
  /// In en, this message translates to:
  /// **'Find the hidden link between clues.'**
  String get obgCtd;

  /// No description provided for @obgDuel.
  ///
  /// In en, this message translates to:
  /// **'One phone, two players — fastest wins.'**
  String get obgDuel;

  /// No description provided for @ecWatchOut.
  ///
  /// In en, this message translates to:
  /// **'Watch out - {title}'**
  String ecWatchOut(String title);

  /// No description provided for @srYou.
  ///
  /// In en, this message translates to:
  /// **'You: ({opt})'**
  String srYou(String opt);

  /// No description provided for @srCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct: ({opt})'**
  String srCorrect(String opt);

  /// No description provided for @srYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer: ({opt})'**
  String srYourAnswer(String opt);

  /// No description provided for @stSharedWithYou.
  ///
  /// In en, this message translates to:
  /// **'{name} shared this test with you.'**
  String stSharedWithYou(String name);

  /// No description provided for @stSubjectTopic.
  ///
  /// In en, this message translates to:
  /// **'Subject: {subject} · {topic}'**
  String stSubjectTopic(String subject, String topic);

  /// No description provided for @stSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject: {subject}'**
  String stSubject(String subject);

  /// No description provided for @stQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions: {n}'**
  String stQuestions(int n);

  /// No description provided for @obgTitle.
  ///
  /// In en, this message translates to:
  /// **'Six games. Zero boring revision.'**
  String get obgTitle;

  /// No description provided for @obgStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get obgStart;

  /// No description provided for @srTitle.
  ///
  /// In en, this message translates to:
  /// **'Session review'**
  String get srTitle;

  /// No description provided for @srBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get srBookmark;

  /// No description provided for @srRevisionMode.
  ///
  /// In en, this message translates to:
  /// **'Revision mode'**
  String get srRevisionMode;

  /// No description provided for @stNameHint.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t want to give your name, enter any random name'**
  String get stNameHint;

  /// No description provided for @stBefore.
  ///
  /// In en, this message translates to:
  /// **'Before you begin'**
  String get stBefore;

  /// No description provided for @stEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your display name'**
  String get stEnterName;

  /// No description provided for @stTop5.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard · Top 5'**
  String get stTop5;

  /// No description provided for @stBeFirst.
  ///
  /// In en, this message translates to:
  /// **'Be the first to take this test.'**
  String get stBeFirst;

  /// No description provided for @stAbout.
  ///
  /// In en, this message translates to:
  /// **'You are about to start a shared practice test.'**
  String get stAbout;

  /// No description provided for @stTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared test'**
  String get stTitle;

  /// No description provided for @stOhSnap.
  ///
  /// In en, this message translates to:
  /// **'Oh snap.'**
  String get stOhSnap;

  /// No description provided for @stExpired.
  ///
  /// In en, this message translates to:
  /// **'This link is unavailable or expired.\nAsk your friend to reshare.'**
  String get stExpired;

  /// No description provided for @stOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening shared test…'**
  String get stOpening;

  /// No description provided for @stPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing configuration…'**
  String get stPreparing;

  /// No description provided for @tsAttemptedOf.
  ///
  /// In en, this message translates to:
  /// **'{attempted} of {total} tests attempted'**
  String tsAttemptedOf(int attempted, int total);

  /// No description provided for @tsAccuracyPct.
  ///
  /// In en, this message translates to:
  /// **'{percent}% accuracy'**
  String tsAccuracyPct(int percent);

  /// No description provided for @tsCompletedOf.
  ///
  /// In en, this message translates to:
  /// **'{attempted} of {total} tests completed'**
  String tsCompletedOf(int attempted, int total);

  /// No description provided for @tsTestsIn.
  ///
  /// In en, this message translates to:
  /// **'Tests in {title}'**
  String tsTestsIn(String title);

  /// No description provided for @tsQAnswered.
  ///
  /// In en, this message translates to:
  /// **'{n} questions answered'**
  String tsQAnswered(int n);

  /// No description provided for @tsHcTests.
  ///
  /// In en, this message translates to:
  /// **'{n} tests: subjects, current affairs and mocks'**
  String tsHcTests(int n);

  /// No description provided for @tsHcFree.
  ///
  /// In en, this message translates to:
  /// **'{n} free tests to try. Subject tests, current affairs, full mocks.'**
  String tsHcFree(int n);

  /// No description provided for @tsUnlocksOn.
  ///
  /// In en, this message translates to:
  /// **'Unlocks {date}'**
  String tsUnlocksOn(String date);

  /// No description provided for @tsAvailFrom.
  ///
  /// In en, this message translates to:
  /// **'Available from {date}'**
  String tsAvailFrom(String date);

  /// No description provided for @tsLiveSince.
  ///
  /// In en, this message translates to:
  /// **'Live since {date}'**
  String tsLiveSince(String date);

  /// No description provided for @tsQMin.
  ///
  /// In en, this message translates to:
  /// **'{q} Q · {m} min'**
  String tsQMin(int q, int m);

  /// No description provided for @tsInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress · {meta}'**
  String tsInProgress(String meta);

  /// No description provided for @tsScoreLine.
  ///
  /// In en, this message translates to:
  /// **'Score {marks}  ·  {correct} correct, {wrong} wrong, {skipped} skipped'**
  String tsScoreLine(String marks, int correct, int wrong, int skipped);

  /// No description provided for @tsNQuestions.
  ///
  /// In en, this message translates to:
  /// **'{n} questions'**
  String tsNQuestions(int n);

  /// No description provided for @tsNMinutesTimed.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes, timed'**
  String tsNMinutesTimed(int n);

  /// No description provided for @tsLoadMineFail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your test series.'**
  String get tsLoadMineFail;

  /// No description provided for @tsNoneStarted.
  ///
  /// In en, this message translates to:
  /// **'You have not started a test series yet.'**
  String get tsNoneStarted;

  /// No description provided for @tsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get tsUnlocked;

  /// No description provided for @tsFreeTests.
  ///
  /// In en, this message translates to:
  /// **'Free tests'**
  String get tsFreeTests;

  /// No description provided for @tsPrelimsOver.
  ///
  /// In en, this message translates to:
  /// **'Prelims is over. All tests stay open for practice.'**
  String get tsPrelimsOver;

  /// No description provided for @tsLoadSeriesFail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this series.'**
  String get tsLoadSeriesFail;

  /// No description provided for @tsLoadSubjectFail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this subject.'**
  String get tsLoadSubjectFail;

  /// No description provided for @tsSubjectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Subject not found.'**
  String get tsSubjectNotFound;

  /// No description provided for @tsTopicsToRevise.
  ///
  /// In en, this message translates to:
  /// **'Topics to revise'**
  String get tsTopicsToRevise;

  /// No description provided for @tsNoOwnTests.
  ///
  /// In en, this message translates to:
  /// **'This subject has no tests of its own. Its numbers come from your full-length tests.'**
  String get tsNoOwnTests;

  /// No description provided for @tsNoQAnswered.
  ///
  /// In en, this message translates to:
  /// **'No questions answered yet'**
  String get tsNoQAnswered;

  /// No description provided for @tsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The test series is not available right now.'**
  String get tsUnavailable;

  /// No description provided for @tsLoadFail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the test series. Check your connection.'**
  String get tsLoadFail;

  /// No description provided for @tsHcDefault.
  ///
  /// In en, this message translates to:
  /// **'Subject tests, current affairs and full-length mocks.'**
  String get tsHcDefault;

  /// No description provided for @tsFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tsFreeLabel;

  /// No description provided for @tsPublishingSoon.
  ///
  /// In en, this message translates to:
  /// **'Publishing soon'**
  String get tsPublishingSoon;

  /// No description provided for @tsReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get tsReview;

  /// No description provided for @tsSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get tsSoon;

  /// No description provided for @tsLoadTestFail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this test. Check your connection and try again.'**
  String get tsLoadTestFail;

  /// No description provided for @tsPractiseAgain.
  ///
  /// In en, this message translates to:
  /// **'Practise again (not scored)'**
  String get tsPractiseAgain;

  /// No description provided for @tsMarking.
  ///
  /// In en, this message translates to:
  /// **'+2 for correct, −0.66 for wrong'**
  String get tsMarking;

  /// No description provided for @tsOneAttempt.
  ///
  /// In en, this message translates to:
  /// **'One scored attempt. Afterwards you can review it and practise again without affecting your stats.'**
  String get tsOneAttempt;

  /// No description provided for @tsUnlockedAll.
  ///
  /// In en, this message translates to:
  /// **'Unlocked! Every test in this series is now yours.'**
  String get tsUnlockedAll;

  /// No description provided for @tsPurchaseFail.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed.'**
  String get tsPurchaseFail;

  /// No description provided for @tsPaymentPendingSeries.
  ///
  /// In en, this message translates to:
  /// **'Your payment is pending. The series unlocks once it completes.'**
  String get tsPaymentPendingSeries;

  /// No description provided for @tsCodeCheckFail.
  ///
  /// In en, this message translates to:
  /// **'Could not check the code. Check your connection and try again.'**
  String get tsCodeCheckFail;

  /// No description provided for @tsUnlockAll.
  ///
  /// In en, this message translates to:
  /// **'Unlock all tests'**
  String get tsUnlockAll;

  /// No description provided for @tsPaidNoAccess.
  ///
  /// In en, this message translates to:
  /// **'Payment went through, but access was not granted yet. Tap Restore purchase, or try again in a little while.'**
  String get tsPaidNoAccess;

  /// No description provided for @tsPwSubject.
  ///
  /// In en, this message translates to:
  /// **'{n} subject tests, {questions} questions each, with {pct}% PYQs'**
  String tsPwSubject(int n, int questions, int pct);

  /// No description provided for @tsPwCa.
  ///
  /// In en, this message translates to:
  /// **'{n} current-affairs tests, added on the 1st of every month'**
  String tsPwCa(int n);

  /// No description provided for @tsPwMocks.
  ///
  /// In en, this message translates to:
  /// **'{n} full-length mocks that mirror the real paper ({questions} Q, {hours} hrs)'**
  String tsPwMocks(int n, int questions, int hours);

  /// No description provided for @tsPwFree.
  ///
  /// In en, this message translates to:
  /// **'{n} tests are free to try first, including all PYQ tests.'**
  String tsPwFree(int n);

  /// No description provided for @tsUnlockAllPrice.
  ///
  /// In en, this message translates to:
  /// **'Unlock all tests · {price}'**
  String tsUnlockAllPrice(String price);

  /// No description provided for @tsSignInPurchase.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google so your purchase is saved to your account.'**
  String get tsSignInPurchase;

  /// No description provided for @tsPassUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This pass is not available right now. Please try again later.'**
  String get tsPassUnavailable;

  /// No description provided for @tsPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Your payment is pending.'**
  String get tsPaymentPending;

  /// No description provided for @tsPurchasesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases are not available on this device.'**
  String get tsPurchasesUnavailable;

  /// No description provided for @tsCodeNotApplied.
  ///
  /// In en, this message translates to:
  /// **'That code could not be applied.'**
  String get tsCodeNotApplied;

  /// No description provided for @tsAlreadyHaveAccess.
  ///
  /// In en, this message translates to:
  /// **'You already have access to this series.'**
  String get tsAlreadyHaveAccess;

  /// No description provided for @tsAccessNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Your access was added but has not loaded yet. Tap Restore purchase in a moment.'**
  String get tsAccessNotLoaded;

  /// No description provided for @tsEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your code first.'**
  String get tsEnterCode;

  /// No description provided for @tsSignInAccess.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google so your access is saved to your account.'**
  String get tsSignInAccess;

  /// No description provided for @tsSignInBefore.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the Google account you used before.'**
  String get tsSignInBefore;

  /// No description provided for @tsAccessRestored.
  ///
  /// In en, this message translates to:
  /// **'Access restored.'**
  String get tsAccessRestored;

  /// No description provided for @tsNothingFoundUnlock.
  ///
  /// In en, this message translates to:
  /// **'Nothing was found for this account. You can unlock the series below.'**
  String get tsNothingFoundUnlock;

  /// No description provided for @tsNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing was found for this account.'**
  String get tsNothingFound;

  /// No description provided for @tsRestoreFail.
  ///
  /// In en, this message translates to:
  /// **'Could not restore. Please check your connection and try again.'**
  String get tsRestoreFail;

  /// No description provided for @tsPayOnce.
  ///
  /// In en, this message translates to:
  /// **'One payment. No subscription. Yours forever, including every test added later.'**
  String get tsPayOnce;

  /// No description provided for @tsPwBilingual.
  ///
  /// In en, this message translates to:
  /// **'Hindi and English on every question and explanation'**
  String get tsPwBilingual;

  /// No description provided for @tsPwDash.
  ///
  /// In en, this message translates to:
  /// **'Dashboard: accuracy by subject, danger-zone and risk topics'**
  String get tsPwDash;

  /// No description provided for @tsPwNoPurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases are not available on this device or build yet.'**
  String get tsPwNoPurchases;

  /// No description provided for @tsPwNotOnSale.
  ///
  /// In en, this message translates to:
  /// **'This series is not on sale right now.'**
  String get tsPwNotOnSale;

  /// No description provided for @tsDiscountCode.
  ///
  /// In en, this message translates to:
  /// **'Discount code'**
  String get tsDiscountCode;

  /// No description provided for @tsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get tsApply;

  /// No description provided for @tsHaveCode.
  ///
  /// In en, this message translates to:
  /// **'Have a code?'**
  String get tsHaveCode;

  /// No description provided for @tsRestorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get tsRestorePurchase;

  /// No description provided for @tsMissingQs.
  ///
  /// In en, this message translates to:
  /// **'Some questions for this test are not on your device yet. Check your connection, or update the app, and try again.'**
  String get tsMissingQs;

  /// No description provided for @tsNoQsRevise.
  ///
  /// In en, this message translates to:
  /// **'No questions to revise for this topic yet.'**
  String get tsNoQsRevise;

  /// No description provided for @tsOpenTopicFail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this topic. Please try again.'**
  String get tsOpenTopicFail;

  /// No description provided for @tsSubConf.
  ///
  /// In en, this message translates to:
  /// **'Questions you got wrong despite high confidence.'**
  String get tsSubConf;

  /// No description provided for @tsSubWrong.
  ///
  /// In en, this message translates to:
  /// **'Questions you got wrong. Tap a topic to read them again.'**
  String get tsSubWrong;

  /// No description provided for @tsPrevYearQs.
  ///
  /// In en, this message translates to:
  /// **'Previous year questions'**
  String get tsPrevYearQs;

  /// No description provided for @tsDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{a}/{t} done'**
  String tsDoneOf(int a, int t);

  /// No description provided for @tsCompletedSlash.
  ///
  /// In en, this message translates to:
  /// **'{a}/{t} tests completed'**
  String tsCompletedSlash(int a, int t);

  /// No description provided for @tsFreePyqMix.
  ///
  /// In en, this message translates to:
  /// **'{n} free PYQ mix tests'**
  String tsFreePyqMix(int n);

  /// No description provided for @tsCorrectOf.
  ///
  /// In en, this message translates to:
  /// **'{c}/{a} correct'**
  String tsCorrectOf(int c, int a);

  /// No description provided for @tsMistakesN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 mistake} other{{n} mistakes}}'**
  String tsMistakesN(int n);

  /// No description provided for @tsSeeAllTopics.
  ///
  /// In en, this message translates to:
  /// **'See all topics ({n})'**
  String tsSeeAllTopics(int n);

  /// No description provided for @tsQAnsweredFlt.
  ///
  /// In en, this message translates to:
  /// **'{n} questions answered in full-length tests'**
  String tsQAnsweredFlt(int n);

  /// No description provided for @tsWhatYouGet.
  ///
  /// In en, this message translates to:
  /// **'What you get'**
  String get tsWhatYouGet;

  /// No description provided for @tsFltDesc.
  ///
  /// In en, this message translates to:
  /// **'Each test has {questions} questions, Time {hours} hours.\nTest of all GS subjects + current affairs'**
  String tsFltDesc(int questions, int hours);

  /// No description provided for @tsSubjTestsDesc.
  ///
  /// In en, this message translates to:
  /// **'Topic-wise {n}-question tests for GS subjects'**
  String tsSubjTestsDesc(int n);

  /// No description provided for @tsCaEveryMonth.
  ///
  /// In en, this message translates to:
  /// **'Current affairs every month'**
  String get tsCaEveryMonth;

  /// No description provided for @tsCaMonthlyDesc.
  ///
  /// In en, this message translates to:
  /// **'A fresh test on the 1st of each month, built from the previous month\'s Current affairs.'**
  String get tsCaMonthlyDesc;

  /// No description provided for @tsKnowMarks.
  ///
  /// In en, this message translates to:
  /// **'Know where you lose marks'**
  String get tsKnowMarks;

  /// No description provided for @tsKnowMarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Accuracy by subject, topics to revise and safe areas, based on how sure you were.'**
  String get tsKnowMarksDesc;

  /// No description provided for @tsBilingualOnePay.
  ///
  /// In en, this message translates to:
  /// **'Hindi and English, one payment'**
  String get tsBilingualOnePay;

  /// No description provided for @tsNoSubExpire.
  ///
  /// In en, this message translates to:
  /// **'No subscription. Pay once and it never expires.'**
  String get tsNoSubExpire;

  /// No description provided for @tsSubSafe.
  ///
  /// In en, this message translates to:
  /// **'Topics you answer reliably across your tests.'**
  String get tsSubSafe;

  /// No description provided for @tsPrepOverview.
  ///
  /// In en, this message translates to:
  /// **'Your Preparation Overview'**
  String get tsPrepOverview;

  /// No description provided for @tsBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Based on your full-length and subject-wise tests.'**
  String get tsBasedOn;

  /// No description provided for @tsFinishATest.
  ///
  /// In en, this message translates to:
  /// **'Finish a test to see your progress, weak topics and strengths.'**
  String get tsFinishATest;

  /// No description provided for @tsYourStats.
  ///
  /// In en, this message translates to:
  /// **'YOUR STATS'**
  String get tsYourStats;

  /// No description provided for @tsTestsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Tests completed'**
  String get tsTestsCompleted;

  /// No description provided for @tsOverallAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Overall accuracy'**
  String get tsOverallAccuracy;

  /// No description provided for @tsQsAttempted.
  ///
  /// In en, this message translates to:
  /// **'Questions attempted'**
  String get tsQsAttempted;

  /// No description provided for @tsReviseFirst.
  ///
  /// In en, this message translates to:
  /// **'Topics to revise first'**
  String get tsReviseFirst;

  /// No description provided for @tsKeepPractising.
  ///
  /// In en, this message translates to:
  /// **'Keep practising'**
  String get tsKeepPractising;

  /// No description provided for @tsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get tsSeeAll;

  /// No description provided for @tsFltIntro.
  ///
  /// In en, this message translates to:
  /// **'Simulate the real exam: {questions} questions, {hours} hours.'**
  String tsFltIntro(int questions, int hours);

  /// No description provided for @tsReviseFromFlts.
  ///
  /// In en, this message translates to:
  /// **'Topics to revise (from FLTs)'**
  String get tsReviseFromFlts;

  /// No description provided for @tsAvailableTests.
  ///
  /// In en, this message translates to:
  /// **'Available Tests'**
  String get tsAvailableTests;

  /// No description provided for @tsSubjIntro.
  ///
  /// In en, this message translates to:
  /// **'Practise by subject and strengthen your concepts.'**
  String get tsSubjIntro;

  /// No description provided for @tsFullSyllDesc.
  ///
  /// In en, this message translates to:
  /// **'Every subject in one paper, in Prelims proportion.'**
  String get tsFullSyllDesc;

  /// No description provided for @tsBySubject.
  ///
  /// In en, this message translates to:
  /// **'By subject'**
  String get tsBySubject;

  /// No description provided for @tsPyqCaIntro.
  ///
  /// In en, this message translates to:
  /// **'Extra practice. These tests are not counted in your overview stats.'**
  String get tsPyqCaIntro;

  /// No description provided for @tsNewTest1st.
  ///
  /// In en, this message translates to:
  /// **'A new test arrives on the 1st of each month.'**
  String get tsNewTest1st;

  /// No description provided for @tsNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get tsNothingYet;

  /// No description provided for @tsSubSafe2.
  ///
  /// In en, this message translates to:
  /// **'Topics you answer reliably. Keep practising to stay sharp.'**
  String get tsSubSafe2;

  /// No description provided for @tsNoWeak.
  ///
  /// In en, this message translates to:
  /// **'No weak topics yet. Finish a test and they will show up here.'**
  String get tsNoWeak;

  /// No description provided for @tsNoSafe.
  ///
  /// In en, this message translates to:
  /// **'No safe areas yet. A topic becomes safe at {pct}% accuracy over {min}+ questions.'**
  String tsNoSafe(int pct, int min);

  /// No description provided for @tsFromFlt.
  ///
  /// In en, this message translates to:
  /// **'From full-length tests'**
  String get tsFromFlt;

  /// No description provided for @tsCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {l}'**
  String tsCorrectAnswer(String l);

  /// No description provided for @tsCorrectBang.
  ///
  /// In en, this message translates to:
  /// **'Correct! Answer: {l}'**
  String tsCorrectBang(String l);

  /// No description provided for @tsNotQuite.
  ///
  /// In en, this message translates to:
  /// **'Not quite. The answer is {l}'**
  String tsNotQuite(String l);

  /// No description provided for @tsQsCorrectOf.
  ///
  /// In en, this message translates to:
  /// **'{c} of {a} questions correct'**
  String tsQsCorrectOf(int c, int a);

  /// No description provided for @tsLowScoreStory.
  ///
  /// In en, this message translates to:
  /// **'A low subject score is not the whole story. Inside {subject}, {topic} is where you actually lose marks. Start there.'**
  String tsLowScoreStory(String subject, String topic);

  /// No description provided for @tsPrelimsOn.
  ///
  /// In en, this message translates to:
  /// **'Prelims on {date}'**
  String tsPrelimsOn(String date);

  /// No description provided for @tsDaysToGo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day to go} other{{n} days to go}}'**
  String tsDaysToGo(int n);

  /// No description provided for @tsSeeAllPyq.
  ///
  /// In en, this message translates to:
  /// **'See all {n} PYQ tests'**
  String tsSeeAllPyq(int n);

  /// No description provided for @tsFreeInAll.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 test is} other{{n} tests are}} free in all, across subjects, current affairs and mocks.'**
  String tsFreeInAll(int n);

  /// No description provided for @tsWrapTests.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 test} other{{n} tests}}: mocks, subjects and current affairs'**
  String tsWrapTests(int n);

  /// No description provided for @tsOneTimeNoSub.
  ///
  /// In en, this message translates to:
  /// **'One-time, no subscription'**
  String get tsOneTimeNoSub;

  /// No description provided for @tsYesterdayCa.
  ///
  /// In en, this message translates to:
  /// **'Yesterday\'s current affairs'**
  String get tsYesterdayCa;

  /// No description provided for @tsSampleQ.
  ///
  /// In en, this message translates to:
  /// **'Sample question'**
  String get tsSampleQ;

  /// No description provided for @tsHowExplained.
  ///
  /// In en, this message translates to:
  /// **'This is how every question in the series is explained.'**
  String get tsHowExplained;

  /// No description provided for @tsTapOption.
  ///
  /// In en, this message translates to:
  /// **'Tap an option to see the answer and explanation.'**
  String get tsTapOption;

  /// No description provided for @tsJustShow.
  ///
  /// In en, this message translates to:
  /// **'Just show the answer'**
  String get tsJustShow;

  /// No description provided for @tsEveryQDetail.
  ///
  /// In en, this message translates to:
  /// **'Every question in the series comes with this level of detail: English and हिन्दी.'**
  String get tsEveryQDetail;

  /// No description provided for @tsExampleNums.
  ///
  /// In en, this message translates to:
  /// **'Example with sample numbers'**
  String get tsExampleNums;

  /// No description provided for @tsTopicByTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic by topic'**
  String get tsTopicByTopic;

  /// No description provided for @tsTapTopicHint.
  ///
  /// In en, this message translates to:
  /// **'In the app, tap any topic to re-read exactly the questions you attempted in it.'**
  String get tsTapTopicHint;

  /// No description provided for @tsHeroTagline.
  ///
  /// In en, this message translates to:
  /// **'Practise. Learn. Find your weak areas. Be better prepared for Prelims.'**
  String get tsHeroTagline;

  /// No description provided for @tsTotalTests.
  ///
  /// In en, this message translates to:
  /// **'Total tests'**
  String get tsTotalTests;

  /// No description provided for @tsFreshMonthly.
  ///
  /// In en, this message translates to:
  /// **'A fresh test on the 1st of every month, built from the previous month\'s news.'**
  String get tsFreshMonthly;

  /// No description provided for @tsFreePyqDesc.
  ///
  /// In en, this message translates to:
  /// **'Start with questions UPSC has already asked. Same interface, explanations and analysis as the paid tests.'**
  String get tsFreePyqDesc;

  /// No description provided for @tsFromYesterdayCa.
  ///
  /// In en, this message translates to:
  /// **'From yesterday\'s current affairs'**
  String get tsFromYesterdayCa;

  /// No description provided for @tsSampleGs.
  ///
  /// In en, this message translates to:
  /// **'A sample GS question'**
  String get tsSampleGs;

  /// No description provided for @tsExplTeach.
  ///
  /// In en, this message translates to:
  /// **'Explanations that actually teach'**
  String get tsExplTeach;

  /// No description provided for @tsExplTeachSub.
  ///
  /// In en, this message translates to:
  /// **'You learn the answer, and how to think like the paper-setter.'**
  String get tsExplTeachSub;

  /// No description provided for @tsStmtDesc.
  ///
  /// In en, this message translates to:
  /// **'Every statement judged true or false, with the reason.'**
  String get tsStmtDesc;

  /// No description provided for @tsDistractorDesc.
  ///
  /// In en, this message translates to:
  /// **'The option that looks right but is not, and why it fools people.'**
  String get tsDistractorDesc;

  /// No description provided for @tsElimDesc.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step way to cross out options, even when unsure.'**
  String get tsElimDesc;

  /// No description provided for @tsValueAddDesc.
  ///
  /// In en, this message translates to:
  /// **'Related facts worth remembering: one question, five lessons.'**
  String get tsValueAddDesc;

  /// No description provided for @tsSeeRealExample.
  ///
  /// In en, this message translates to:
  /// **'See a real example'**
  String get tsSeeRealExample;

  /// No description provided for @tsSmarterTitle.
  ///
  /// In en, this message translates to:
  /// **'Smarter than a score'**
  String get tsSmarterTitle;

  /// No description provided for @tsSmarterSub.
  ///
  /// In en, this message translates to:
  /// **'Most test series stop at your marks. We show you what to do next.'**
  String get tsSmarterSub;

  /// No description provided for @tsToolQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Your revision queue builds itself'**
  String get tsToolQueueTitle;

  /// No description provided for @tsToolQueueBody.
  ///
  /// In en, this message translates to:
  /// **'Got a question wrong? Bookmarked it to look at later? It goes into your revision queue automatically. No notebooks, no lists to maintain. Just open the queue and revise.'**
  String get tsToolQueueBody;

  /// No description provided for @tsToolBlindTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your blind spots'**
  String get tsToolBlindTitle;

  /// No description provided for @tsToolBlindBody.
  ///
  /// In en, this message translates to:
  /// **'We ask how sure you were. Confident but wrong is a blind spot: fix it first. Confident and right is a safe area: attempt more there and take the risk.'**
  String get tsToolBlindBody;

  /// No description provided for @tsToolTopicTitle.
  ///
  /// In en, this message translates to:
  /// **'Know exactly which topics cost you marks'**
  String get tsToolTopicTitle;

  /// No description provided for @tsToolTopicBody.
  ///
  /// In en, this message translates to:
  /// **'Accuracy in Modern History is low? We also tell you which topics inside it are dragging it down, so you revise the right chapter, not the whole book.'**
  String get tsToolTopicBody;

  /// No description provided for @tsSeeExample.
  ///
  /// In en, this message translates to:
  /// **'See an example'**
  String get tsSeeExample;

  /// No description provided for @tsSureRight.
  ///
  /// In en, this message translates to:
  /// **'Sure and right'**
  String get tsSureRight;

  /// No description provided for @tsSafeAction.
  ///
  /// In en, this message translates to:
  /// **'Attempt more here. Take the risk.'**
  String get tsSafeAction;

  /// No description provided for @tsSureWrong.
  ///
  /// In en, this message translates to:
  /// **'Sure but wrong'**
  String get tsSureWrong;

  /// No description provided for @tsBlindAction.
  ///
  /// In en, this message translates to:
  /// **'Fix these first. They cost marks.'**
  String get tsBlindAction;

  /// No description provided for @tsGuessRight.
  ///
  /// In en, this message translates to:
  /// **'Pure guess and right'**
  String get tsGuessRight;

  /// No description provided for @tsLuckyAction.
  ///
  /// In en, this message translates to:
  /// **'Revise so it sticks.'**
  String get tsLuckyAction;

  /// No description provided for @tsGuessWrong.
  ///
  /// In en, this message translates to:
  /// **'Pure guess and wrong'**
  String get tsGuessWrong;

  /// No description provided for @tsGapAction.
  ///
  /// In en, this message translates to:
  /// **'Learn it from the explanation.'**
  String get tsGapAction;

  /// No description provided for @tsPractiseLike.
  ///
  /// In en, this message translates to:
  /// **'Practise like it\'s Prelims day'**
  String get tsPractiseLike;

  /// No description provided for @tsMocksMirror.
  ///
  /// In en, this message translates to:
  /// **'The full-length mocks mirror the real paper.'**
  String get tsMocksMirror;

  /// No description provided for @ts100q2h.
  ///
  /// In en, this message translates to:
  /// **'{questions} Q, {hours} hours'**
  String ts100q2h(int questions, int hours);

  /// No description provided for @tsTimedPaper.
  ///
  /// In en, this message translates to:
  /// **'Timed, exam-style paper with all GS subjects.'**
  String get tsTimedPaper;

  /// No description provided for @tsRealMarking.
  ///
  /// In en, this message translates to:
  /// **'Real marking'**
  String get tsRealMarking;

  /// No description provided for @tsMarkingSkip.
  ///
  /// In en, this message translates to:
  /// **'+2 for correct, −0.66 for wrong. Learn when to skip.'**
  String get tsMarkingSkip;

  /// No description provided for @tsOneScored.
  ///
  /// In en, this message translates to:
  /// **'One scored attempt'**
  String get tsOneScored;

  /// No description provided for @tsThenReview.
  ///
  /// In en, this message translates to:
  /// **'Then review it, and practise again without affecting stats.'**
  String get tsThenReview;

  /// No description provided for @tsBothLangs.
  ///
  /// In en, this message translates to:
  /// **'Every question and explanation, in both languages.'**
  String get tsBothLangs;

  /// No description provided for @tsOnePayGood.
  ///
  /// In en, this message translates to:
  /// **'One payment. Yours for good.'**
  String get tsOnePayGood;

  /// No description provided for @tsWrapExpl.
  ///
  /// In en, this message translates to:
  /// **'Detailed explanations in English and हिन्दी'**
  String get tsWrapExpl;

  /// No description provided for @tsWrapQueue.
  ///
  /// In en, this message translates to:
  /// **'Revision queue, blind spots and topic-wise analysis'**
  String get tsWrapQueue;

  /// No description provided for @tsWrapNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No subscription, no expiry. Tests added later are included.'**
  String get tsWrapNoExpiry;

  /// No description provided for @tsNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet? Try the free tests first.'**
  String get tsNotSure;

  /// No description provided for @tsTryFreePyq.
  ///
  /// In en, this message translates to:
  /// **'Try the free PYQ tests'**
  String get tsTryFreePyq;

  /// No description provided for @tsGetHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get tsGetHelp;

  /// No description provided for @tsGetHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Questions about unlock, payment, or a test? Reach out — we reply.'**
  String get tsGetHelpBody;

  /// No description provided for @tsGetHelpTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get tsGetHelpTelegram;

  /// No description provided for @tsGetHelpEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get tsGetHelpEmail;

  /// No description provided for @practiceTestNumber.
  ///
  /// In en, this message translates to:
  /// **'Test {n}'**
  String practiceTestNumber(int n);

  /// No description provided for @practiceTestsProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} tests'**
  String practiceTestsProgress(int done, int total);

  /// No description provided for @practiceQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Qs'**
  String practiceQuestionCount(int count);

  /// No description provided for @practiceReviewLast.
  ///
  /// In en, this message translates to:
  /// **'Review last attempt'**
  String get practiceReviewLast;

  /// No description provided for @practiceReattempt.
  ///
  /// In en, this message translates to:
  /// **'Reattempt'**
  String get practiceReattempt;

  /// No description provided for @practiceNewSeason.
  ///
  /// In en, this message translates to:
  /// **'New season: your tests have been reshuffled for the next prelims.'**
  String get practiceNewSeason;

  /// No description provided for @practiceBrowseTopics.
  ///
  /// In en, this message translates to:
  /// **'Topic-wise tests'**
  String get practiceBrowseTopics;

  /// No description provided for @practiceBrowseTopicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse topics'**
  String get practiceBrowseTopicsSubtitle;

  /// No description provided for @practiceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceSectionTitle;

  /// No description provided for @practiceSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your test series for prelims {year}'**
  String practiceSectionSubtitle(int year);

  /// No description provided for @practiceSeeStats.
  ///
  /// In en, this message translates to:
  /// **'See stats'**
  String get practiceSeeStats;

  /// No description provided for @practiceNoTests.
  ///
  /// In en, this message translates to:
  /// **'No tests in this pool yet.'**
  String get practiceNoTests;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// No description provided for @statsAllSubjects.
  ///
  /// In en, this message translates to:
  /// **'All subjects'**
  String get statsAllSubjects;

  /// No description provided for @statsCoverage.
  ///
  /// In en, this message translates to:
  /// **'{value} covered'**
  String statsCoverage(String value);

  /// No description provided for @statsAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get statsAccuracyLabel;

  /// No description provided for @statsRingCoverage.
  ///
  /// In en, this message translates to:
  /// **'Covered'**
  String get statsRingCoverage;

  /// No description provided for @statsRingTests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get statsRingTests;

  /// No description provided for @statsAccuracyChart.
  ///
  /// In en, this message translates to:
  /// **'Accuracy by subject'**
  String get statsAccuracyChart;

  /// No description provided for @statsTopicChart.
  ///
  /// In en, this message translates to:
  /// **'Accuracy by topic'**
  String get statsTopicChart;

  /// No description provided for @statsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'{value} accuracy'**
  String statsAccuracy(String value);

  /// No description provided for @statsAnswered.
  ///
  /// In en, this message translates to:
  /// **'{count} answered'**
  String statsAnswered(int count);

  /// No description provided for @statsFocusNext.
  ///
  /// In en, this message translates to:
  /// **'Focus next'**
  String get statsFocusNext;

  /// No description provided for @statsFocusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Keep practising. Suggestions show up once a topic is weak, shaky, or still untouched.'**
  String get statsFocusEmpty;

  /// No description provided for @statsFocusRevise.
  ///
  /// In en, this message translates to:
  /// **'Revise {topic}'**
  String statsFocusRevise(String topic);

  /// No description provided for @statsFocusPractise.
  ///
  /// In en, this message translates to:
  /// **'Practise {topic}'**
  String statsFocusPractise(String topic);

  /// No description provided for @statsFocusStart.
  ///
  /// In en, this message translates to:
  /// **'Start {topic}'**
  String statsFocusStart(String topic);

  /// No description provided for @statsSortWeakest.
  ///
  /// In en, this message translates to:
  /// **'Weakest'**
  String get statsSortWeakest;

  /// No description provided for @statsSortLeastCovered.
  ///
  /// In en, this message translates to:
  /// **'Least covered'**
  String get statsSortLeastCovered;

  /// No description provided for @statsSortAz.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get statsSortAz;

  /// No description provided for @statsConfidence.
  ///
  /// In en, this message translates to:
  /// **'Sure {sureTotal} ({sureWrong} wrong) · Educated guess {guessTotal} ({guessWrong} wrong)'**
  String statsConfidence(
    int sureTotal,
    int sureWrong,
    int guessTotal,
    int guessWrong,
  );

  /// No description provided for @statsTrapPatterns.
  ///
  /// In en, this message translates to:
  /// **'Trap patterns'**
  String get statsTrapPatterns;

  /// No description provided for @statsUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock full stats'**
  String get statsUnlock;

  /// No description provided for @todayQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'What to do today?'**
  String get todayQueueTitle;

  /// No description provided for @todayQueueCaShots.
  ///
  /// In en, this message translates to:
  /// **'CA shots'**
  String get todayQueueCaShots;

  /// No description provided for @todayQueueCaShotsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick revision of important current affairs'**
  String get todayQueueCaShotsSubtitle;

  /// No description provided for @todayQueueCaTest.
  ///
  /// In en, this message translates to:
  /// **'Current affairs test'**
  String get todayQueueCaTest;

  /// No description provided for @todayQueueCaTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test your CA preparation'**
  String get todayQueueCaTestSubtitle;

  /// No description provided for @todayQueueDailyWar.
  ///
  /// In en, this message translates to:
  /// **'Daily war'**
  String get todayQueueDailyWar;

  /// No description provided for @todayQueueDailyWarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s competitive CA challenge'**
  String get todayQueueDailyWarSubtitle;

  /// No description provided for @todayQueueOpenChallenge.
  ///
  /// In en, this message translates to:
  /// **'Open challenge'**
  String get todayQueueOpenChallenge;

  /// No description provided for @todayQueueOpenChallengeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join a live community challenge'**
  String get todayQueueOpenChallengeSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
