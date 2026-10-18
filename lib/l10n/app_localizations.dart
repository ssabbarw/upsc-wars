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
  /// **'Question language'**
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
  /// **'{count, plural, =1{1 incorrect} other{{count} incorrects}}'**
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
  /// **'SUBJECTS'**
  String get homeSubjects;

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
  /// **'Today\'s paper quiz'**
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
  /// **'The marks are in the explanation — elimination, statement analysis, and the trap option.'**
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
