// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDone => 'Done';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonExit => 'Exit';

  @override
  String get commonLogOut => 'Log out';

  @override
  String get languagePickerTitle => 'Choose language';

  @override
  String get languagePickerSubtitle =>
      'One setting for the whole app and the questions.';

  @override
  String get languagePickerHintEn => 'App and questions both in English.';

  @override
  String get languagePickerHintHi => 'App and questions both in Hindi.';

  @override
  String get languagePickerPracticeTest => 'Practice test';

  @override
  String get readingSizeSmall => 'Small';

  @override
  String get readingSizeDefault => 'Default';

  @override
  String get readingSizeMedium => 'Medium';

  @override
  String get readingSizeLarge => 'Large';

  @override
  String get readingSizeExtraLarge => 'Extra large';

  @override
  String get routerExitDialogTitle => 'Exit app?';

  @override
  String routerExitDialogBody(String appName) {
    return 'You will leave $appName.';
  }

  @override
  String settingsSeriesUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series unlocked',
      one: '1 series unlocked',
    );
    return '$_temp0';
  }

  @override
  String settingsBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSubtitleEn => 'App and questions in English';

  @override
  String get settingsLanguageSubtitleHi => 'App and questions in Hindi';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSendFeedback => 'Send feedback';

  @override
  String get settingsTelegramDirect => 'Telegram (direct)';

  @override
  String get settingsTelegramGroup => 'Telegram (group)';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsAboutUs => 'About us';

  @override
  String get settingsAboutUsSubtitle => 'What we’re building, why it exists';

  @override
  String get settingsRateApp => 'Rate the app';

  @override
  String get settingsOpenAppStore => 'Open App Store';

  @override
  String get settingsOpenPlayStore => 'Open Play Store';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsFooter => 'Built with care for every serious aspirant.';

  @override
  String get settingsStoreOpenFailed =>
      'Could not open the store. Try again later.';

  @override
  String get settingsHeaderTagline => 'Make the app feel like yours.';

  @override
  String get settingsNoOneBlocked => 'No one blocked';

  @override
  String get settingsBlockedUsers => 'Blocked users';

  @override
  String get settingsLoggingOut => 'Logging out...';

  @override
  String get settingsSignOutSubtitle => 'Sign out of this device';

  @override
  String get settingsLogOutConfirmTitle => 'Log out?';

  @override
  String get settingsLogOutConfirmBody => 'Are you sure you want to log out?';

  @override
  String get settingsLinkOpenFailed => 'Could not open link.';

  @override
  String get settingsLanguageTitle => 'Question language';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsDarkModeSubtitle =>
      'Comfortable contrast for long sessions.';

  @override
  String get settingsReadingSize => 'Reading size';

  @override
  String get settingsReadingSizeSubtitle => 'Question text and explanations.';

  @override
  String get settingsReadingSmaller => 'Smaller';

  @override
  String get settingsReadingLarger => 'Larger';

  @override
  String get settingsPreview => 'PREVIEW';

  @override
  String get settingsConfidenceTitle => 'Confidence before reveal';

  @override
  String get settingsConfidenceSubtitle =>
      'Ask “how sure are you?” before showing answers.';

  @override
  String get settingsStatusBarReminder => 'Status bar reminder';

  @override
  String get settingsAndroidOnly => 'Available on Android.';

  @override
  String get settingsStatusBarReminderSubtitle =>
      'Keep the days-until-Prelims count visible.';

  @override
  String get routerGoHome => 'Go home';

  @override
  String get routerLinkFailedTitle => 'Link could not be opened';

  @override
  String get routerErrorTitle => 'Oh snap';

  @override
  String get routerLinkFailedBody =>
      'This link could not be opened.\nPlease try again.';

  @override
  String get routerErrorBody => 'Something went wrong.\nPlease try again.';

  @override
  String get revisionQueueEmptyLine => 'Nothing in the queue yet';

  @override
  String get commonNone => 'None';

  @override
  String get revisionIncorrectMcqs => 'Incorrect MCQs';

  @override
  String get revisionBookmarkedMcqs => 'Bookmarked MCQs';

  @override
  String revisionCountIncorrect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incorrects',
      one: '1 incorrect',
    );
    return '$_temp0';
  }

  @override
  String revisionCountBookmark(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookmarks',
      one: '1 bookmark',
    );
    return '$_temp0';
  }

  @override
  String get ritualCaShotsWhen => 'Through the day';

  @override
  String get ritualCaShotsBody =>
      'Breaking news brief + 1 MCQ. Two minutes when a shot lands.';

  @override
  String get ritualDailyCaWhen => 'Opens 6 AM';

  @override
  String get ritualDailyCaBody =>
      'Yesterday\'s news as a scored paper. Revise any past day.';

  @override
  String get ritualDailyWarWhen => '9 PM · Mon–Fri';

  @override
  String get ritualDailyWarBody =>
      'All-India live static GS paper. Same questions, then the rank.';

  @override
  String homeStreakMilestoneToast(int count) {
    return '$count-day streak. Keep showing up.';
  }

  @override
  String homeStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String homeGreetingNamed(String name) {
    return 'Hey, $name';
  }

  @override
  String get homeGoodMorning => 'Good morning';

  @override
  String get homeGoodAfternoon => 'Good afternoon';

  @override
  String get homeGoodEvening => 'Good evening';

  @override
  String homeTrapsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count traps',
      one: '1 trap',
    );
    return '$_temp0';
  }

  @override
  String homeCaughtByTraps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trap types',
      one: '1 trap type',
    );
    return 'You\'ve been caught by $_temp0';
  }

  @override
  String homeStartNQuestionTest(int count) {
    return 'Start $count-question test';
  }

  @override
  String homeCountAvailable(int count) {
    return '$count available';
  }

  @override
  String activationLeftAt(int done, int total) {
    return 'You left at question $done of $total. Pick up where you stopped.';
  }

  @override
  String homeAnsweredOf(int done, int total) {
    return 'You\'ve answered $done of $total questions.';
  }

  @override
  String homeResumeProgress(int done, int total) {
    return 'Resume · $done of $total done';
  }

  @override
  String restoreProgressTests(int done, int total) {
    return '$done of $total tests';
  }

  @override
  String revisionPickPool(int count) {
    return 'Pick a pool. You’ll get a short random test from those questions — up to $count at a time.';
  }

  @override
  String homeOpenChallengeBy(String name) {
    return 'Open challenge by $name';
  }

  @override
  String homeGoalOthersLive(String goal, int count) {
    return '$goal · +$count live';
  }

  @override
  String homeChallengeGoalMixed(String who, int score) {
    String _temp0 = intl.Intl.selectLogic(who, {
      'poster': 'Beat their score of $score/10 across mixed subjects',
      'other': 'Beat the top score of $score/10 across mixed subjects',
    });
    return '$_temp0';
  }

  @override
  String homeChallengeGoalSubject(String who, int score, String subject) {
    String _temp0 = intl.Intl.selectLogic(who, {
      'poster': 'Beat their score of $score/10 in $subject',
      'other': 'Beat the top score of $score/10 in $subject',
    });
    return '$_temp0';
  }

  @override
  String homeDangerLocked(int total) {
    return 'Questions you got wrong while sure. Unlocks at $total questions.';
  }

  @override
  String homeDangerLockedProgress(int total, int scored) {
    return 'Questions you got wrong while sure. Unlocks at $total questions. — $scored/$total so far.';
  }

  @override
  String homeWeekReviewCount(int mistakes) {
    return '$mistakes questions where you slipped last week.';
  }

  @override
  String homeDrillSubjectBit(String subject) {
    return '10 $subject questions with instant feedback.';
  }

  @override
  String homeDrillOpenAgain(String counts) {
    return '$counts. Open again if you want another set.';
  }

  @override
  String homeDrillShortSet(String counts) {
    return '$counts. A short set from misses or bookmarks.';
  }

  @override
  String get homeStreak3Toast => '3-day streak — the habit is sticking.';

  @override
  String get homeQuestionBankUnavailable => 'Question bank unavailable';

  @override
  String get homeQuestionBankUnavailableBody =>
      'The question database could not be opened. Reinstall the app or ensure storage is available, then restart.';

  @override
  String get homeGreetingGeneric => 'Hey there';

  @override
  String get homeResumeDemoTest => 'Resume demo test';

  @override
  String get homeStartWithDemoTest => 'Start with the demo test';

  @override
  String get homeRateReview => 'Rate & review';

  @override
  String get homePickAnySubject => 'PICK ANY SUBJECT';

  @override
  String get homeSubjects => 'SUBJECTS';

  @override
  String get homeQuestionsYouSaved => 'Questions you saved';

  @override
  String get activationStartHere => 'START HERE';

  @override
  String get activationTakeDemo => 'Take the 5-minute demo test';

  @override
  String get activationPickUp => 'Pick up where you left off.';

  @override
  String get activationDemoPitch =>
      'See how a trap question fools confident aspirants — and how Danger Zone catches it.';

  @override
  String get activationStartTest => 'Start the test';

  @override
  String get activationHideTitle => 'Hide for now?';

  @override
  String get activationHideBody => 'We’ll bring this back tomorrow.';

  @override
  String get activationHideConfirm => 'Hide for now';

  @override
  String get activationKeepGoing => 'Keep going';

  @override
  String get drillSubjectTitle => 'Daily practice subject';

  @override
  String get drillSubjectBody => 'Choose what your daily drill focuses on.';

  @override
  String get revisionEmptyPools =>
      'Questions you get wrong or bookmark will appear here. Then you can take a short random test from either pool.';

  @override
  String get revisionPoolWrongBody =>
      'A random test from questions you answered incorrectly.';

  @override
  String get revisionPoolSavedBody =>
      'A random test from questions you have bookmarked.';

  @override
  String get ritualsIntroTitle => 'Your daily loop';

  @override
  String get ritualsIntroOne => 'On Home. Same place every day.';

  @override
  String get ritualsIntroTwo => 'Two things on Home. Same place every day.';

  @override
  String get ritualsIntroThree => 'Three things on Home. Same place every day.';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get restorePaused => 'Restore paused';

  @override
  String get restoreFailedBody => 'Could not restore your data.';

  @override
  String get restoreDoneTitle => 'Your data is back';

  @override
  String get restoreDoneBody => 'Restored your tests.';

  @override
  String get restoreInProgressTitle => 'Restoring your data…';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get restoreKeepUsing =>
      'You can keep using the app while this finishes.';

  @override
  String get homeNoQuestionsYet => 'No questions answered yet.';

  @override
  String get commonResume => 'Resume';

  @override
  String get demoInProgress => 'Demo in progress';

  @override
  String get commonStartOver => 'Start over';

  @override
  String get demoTry => 'Try a demo test';

  @override
  String get demoTrySuffix => ' — see the edge UPSC Wars gives you';

  @override
  String get demoRemindTomorrow => 'Remind me tomorrow';

  @override
  String get demoNotNowTitle => 'Not now?';

  @override
  String get demoNotNowBody =>
      'This 5-minute demo finds questions you feel sure about but get wrong — the edge UPSC Wars is built around. We’ll nudge you again tomorrow until you finish one test.';

  @override
  String get demoTryDiagnostic => 'Try the diagnostic instead';

  @override
  String get demoIntroTitle => 'Find where UPSC Wars gives you an edge';

  @override
  String get demoIntroBody =>
      'Take this demo — current affairs mixed with static, with instant feedback after each answer.';

  @override
  String get demoPoint1Title => '8 MCQs · no timer';

  @override
  String get demoPoint1Body =>
      'Current affairs plus static — see the explanation as you go.';

  @override
  String get demoPoint2Title => 'Mark your confidence';

  @override
  String get demoPoint2Body =>
      'Sure, educated guess, or unsure — we spot what feels right but isn’t.';

  @override
  String get demoPoint3Title => 'Rich insights when you finish';

  @override
  String get demoPoint3Body =>
      'Confident mistakes, trap patterns, and what to revise next.';

  @override
  String get demoPoint4Title => 'Explanations that actually teach';

  @override
  String get demoPoint4Body =>
      'Traps, elimination, statement analysis — not just right or wrong.';

  @override
  String get demoLetsGo => 'Let’s go';

  @override
  String get demoSkipToHome => 'Skip to home';

  @override
  String get todayCaLive => 'Live now — based on yesterday\'s news.';

  @override
  String get todayCaNotDone => 'Current affairs test from yesterday\'s news.';

  @override
  String get todayDone => 'Done today';

  @override
  String get todayQuizDoneOpenAnswers => 'Quiz done — open answers';

  @override
  String get todaySignInOpenChallenge => 'Sign in to join an open challenge.';

  @override
  String get todayDangerUnlocked =>
      'Questions you got wrong while sure — trap patterns.';

  @override
  String get todayWhatIsThis => 'What is this?';

  @override
  String get todayCaShotSubtitle => 'Breaking news brief + 1 MCQ based on it.';

  @override
  String get todayPaperQuizTitle => 'Today\'s paper quiz';

  @override
  String get todayPaperQuizBody =>
      'Based on yesterday\'s news. Same questions for everyone — then All-India Rank.';

  @override
  String get todayOpenPaper => 'Open paper';

  @override
  String get todayWeekDone => 'Week review done';

  @override
  String get todayWeekDoneBody =>
      'You\'ve gone through last week\'s mistakes. Streak intact.';

  @override
  String get todaySeeResults => 'See results';

  @override
  String get todayWeekEmpty => 'No mistakes this week';

  @override
  String get todayWeekEmptyBody =>
      'No mistakes from last week — you\'re clean.';

  @override
  String get todayQuickPracticeInstead => 'Quick practice instead';

  @override
  String get todayWeekReviewTitle => 'Review last week\'s mistakes';

  @override
  String get todayStartReview => 'Start review';

  @override
  String get todayDrillDone => 'Drill done';

  @override
  String get todayDrillTitle => 'Today\'s drill';

  @override
  String get todayDrillBody => '10 questions with instant feedback.';

  @override
  String get todayDrillInBooks => 'Today\'s drill is in the books.';

  @override
  String get todayOpenAgain => 'Open again';

  @override
  String get commonStart => 'Start';

  @override
  String get progressPerfectWeek => 'Perfect week — all 7 days sealed 🔥';

  @override
  String progressDaysSealed(int count) {
    return '$count of 7 days sealed this week';
  }

  @override
  String progressWrongAnswersAllTime(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'wrong answers (all-time) · ',
      one: 'wrong answer (all-time) · ',
    );
    return '$_temp0';
  }

  @override
  String progressAttemptedAccuracy(int attempted, String accuracy) {
    return '$attempted attempted · $accuracy accuracy';
  }

  @override
  String progressWrongAllTime(int count) {
    return '$count wrong (all-time)';
  }

  @override
  String profileAppVersion(String version) {
    return 'Current app version: $version';
  }

  @override
  String get progressTabHistory => 'Test History';

  @override
  String get progressLoadFailed => 'Could not load overview.';

  @override
  String get progressSubtitle => 'Your performance across all subjects';

  @override
  String get progressSubjectsPractised => ' subjects practised';

  @override
  String get progressSortMostMistakes => 'Most mistakes';

  @override
  String get progressNotStarted => 'Not started';

  @override
  String get profileMadeWithLove => 'Made with love ';

  @override
  String get profileInDelhi => ' in Delhi';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileYourProfile => 'Your Profile';

  @override
  String get profileSignInPitch =>
      'Sign in to join the community, participate in battles, and build your profile.';

  @override
  String get authSigningIn => 'Signing in...';

  @override
  String get authContinueApple => 'Continue with Apple';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String get profilePhotoWebHint =>
      'Profile photo can be changed in the Android or iOS app.';

  @override
  String get profileNoEmail => 'No email';

  @override
  String get profileAuthentication => 'Authentication';

  @override
  String get profileAccountConnected => 'Account connected';

  @override
  String get profileDataSecure => 'Your account data remains secure';

  @override
  String get profileTelegramSlash => 'Telegram username should not contain /';

  @override
  String get profileInstagramSlash => 'Instagram username should not contain /';

  @override
  String get profileCommunityUpdated => 'Community profile updated';

  @override
  String get profileCommunityTitle => 'Community Profile';

  @override
  String get profileCommunityBody =>
      'Complete these fields so aspirants can connect with you.';

  @override
  String get profileOptionalSubject => 'Optional Subject';

  @override
  String get profileInstagramLabel => 'Instagram (without @)';

  @override
  String get profileTelegramLabel => 'Telegram (without @)';

  @override
  String get profileUpdating => 'Updating...';

  @override
  String get profileUpdate => 'Update';

  @override
  String get riskLower => 'Lower risk';

  @override
  String get riskMedium => 'Medium risk';

  @override
  String get riskHigher => 'Higher risk';

  @override
  String testQuestionOfTotal(int current, int total) {
    return 'Q$current of $total';
  }

  @override
  String historySessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String historyScoreDone(String score) {
    return '$score done';
  }

  @override
  String reviewCorrectWrong(int correct, int wrong) {
    return '$correct correct · $wrong wrong';
  }

  @override
  String reviewQuestionOfTotal(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get testCorrect => 'Correct';

  @override
  String get testNotThisTime => 'Not this time';

  @override
  String get testHintCorrect =>
      'The marks are in the explanation — elimination, statement analysis, and the trap option.';

  @override
  String get testHintWrong =>
      'Read how to kill the other options — that\'s the real practice.';

  @override
  String get testShowExplanation => 'Show explanation';

  @override
  String get testConfidenceIntroTitle =>
      'From now on, let\'s also check how sure you are.';

  @override
  String get testConfidenceWhy => 'Why? ';

  @override
  String get testConfidenceWhyBody => 'To catch your confident mistakes.';

  @override
  String get testHowSure => 'How sure are you?';

  @override
  String get testHowSureBody =>
      'Pick before you see the answer — this builds your Danger Zone map.';

  @override
  String get testLeaveDemoTitle => 'Leave demo?';

  @override
  String get testLeaveDemoBody =>
      'Your progress will be saved. Resume from Home when you\'re ready.';

  @override
  String get testLeave => 'Leave';

  @override
  String get testGoBackTitle => 'Go back?';

  @override
  String get testLeaveTestTitle => 'Leave test?';

  @override
  String get testGoBackBody => 'Are you sure? Your progress will be lost.';

  @override
  String get testLeaveTestBody =>
      'Your progress will be saved and you can resume later.';

  @override
  String get testGoBack => 'Go back';

  @override
  String get testSessionNotFound => 'Session not found';

  @override
  String get commonSomethingWrong => 'Something went wrong';

  @override
  String get testSessionLoadFailed => 'Could not load test session.';

  @override
  String get testTimerPausedNotice =>
      'Timer paused while app was closed. Remaining time may not be accurate.';

  @override
  String get testBookmarked => 'Bookmarked';

  @override
  String get testBookmarkRemoved => 'Bookmark removed';

  @override
  String get testGridHint => 'Tap any number to jump to that question';

  @override
  String get testGridCurrent => 'Current';

  @override
  String get testGridAttempted => 'Attempted';

  @override
  String get testGridFlagged => 'Flagged';

  @override
  String get testGridNotVisited => 'Not visited';

  @override
  String get testGridSkipped => 'Skipped';

  @override
  String get testSubmitTest => 'Submit Test';

  @override
  String get testSubmit => 'Submit';

  @override
  String get commonBack => 'Back';

  @override
  String get testPrev => 'Prev';

  @override
  String get testNext => 'Next';

  @override
  String get demoLoadFailed => 'Could not load the demo test.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyLoadFailed => 'Failed to load history';

  @override
  String get historyEmpty => 'No sessions yet';

  @override
  String get historyNoneFound => 'No sessions found';

  @override
  String get historyEmptyHint => 'Complete a test to see your history here';

  @override
  String get historyChangeFilters => 'Try changing your filters';

  @override
  String get commonAll => 'All';

  @override
  String get historyAbandoned => 'Abandoned';

  @override
  String get historyInProgress => 'In progress';

  @override
  String get historyRestart => 'Restart';

  @override
  String get reviewShareTitle => 'Share this test';

  @override
  String get reviewShareBody =>
      'Tap Share to send this question (or the whole test) to friends.\n\nFound an error in a question? Use Share to report it to the UPSC Wars developer.';

  @override
  String get reviewQuestionLabel => 'QUESTION';

  @override
  String get reviewPrevArrow => '← Prev';

  @override
  String get reviewNextArrow => 'Next →';

  @override
  String get reviewRemoveBookmark => 'Remove bookmark';

  @override
  String get reviewInRevisionQueue => 'In revision queue';

  @override
  String get reviewAddToRevisionQueue => 'Add to revision queue';

  @override
  String get reviewCorrectAnswer => 'Correct answer';

  @override
  String get reviewIncorrect => 'Incorrect';

  @override
  String get reviewTimesUp => 'Time\'s up';

  @override
  String get reviewSkipped => 'Skipped';

  @override
  String get reviewYourPick => 'Your pick';
}
