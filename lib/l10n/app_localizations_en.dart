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

  @override
  String get onbSublinePrefix => 'We analyze every answer to ';

  @override
  String get onbSublinePhrase => 'identify the topics that help or hurt';

  @override
  String get onbSublineSuffix => ' your score.';

  @override
  String get onbFeatureExplanation => 'Rich explanation';

  @override
  String get onbFeatureStatement => 'Statement analysis';

  @override
  String get onbFeatureElimination => 'Elimination technique';

  @override
  String get onbFeatureDistractor => 'Strong distractor option';

  @override
  String get onbThesisEyebrow => 'THE UPSC REALITY';

  @override
  String get onbConfidentWrong => 'Confident\n& Wrong';

  @override
  String get onbConfidentWrongBody =>
      'Topics you are confident about and get wrong.';

  @override
  String get onbGuessRight => 'Guess\n& Right';

  @override
  String get onbGuessRightBody =>
      'Topics where your guesses are right more often.';

  @override
  String get onbNext => 'Next  →';

  @override
  String get onbLead => 'Prelims isn\'t about knowing everything.';

  @override
  String get onbAccent => 'UPSC Wars shows you where you stand.';

  @override
  String get onbAvoidMistakes => 'Avoid costly mistakes.';

  @override
  String get onbReviseTopics => 'Revise these topics.';

  @override
  String get onbAttemptMore => 'Attempt more from these topics';

  @override
  String get onbGainMarks => 'Gain +ve marks.';

  @override
  String get onbDepthEyebrow => 'THE UPSC EDGE';

  @override
  String get onbDepthTitle => 'Each question in\nUPSC Wars has:';

  @override
  String get aboutWhyBody =>
      'I prepared for UPSC myself and realised that most aspirants solve thousands of MCQs but still don’t know where they are actually losing marks.\n\nSometimes the problem is not lack of knowledge — it is overconfidence, risky guessing, weak revision, and repeated mistakes.\n\nAt the same time, preparation is also about knowing where you can safely take smart risks and attempt more with confidence.\n\nThat is why I built UPSC Wars.';

  @override
  String get aboutGoalBody =>
      'So your preparation becomes smarter, not just harder.\n\nMy goal is simple:\n\nHelp aspirants prepare like someone who clears Prelims.\n\nBuilt independently. No coaching institute. No big team. Just a serious attempt to make UPSC preparation better.';

  @override
  String get aboutConnectBody =>
      'Your feedback directly improves UPSC Wars.\n\nIf something feels missing, confusing, or useful, please message me. I read every feedback personally.\n\n📩 upscwars@gmail.com';

  @override
  String get aboutReviewBody =>
      'If UPSC Wars helped your preparation, please leave a review.\n\nYour review helps more serious aspirants discover the app and helps improve the app faster.';

  @override
  String get aboutBullet1 =>
      '• Areas where confident answers or intelligent guesses often go wrong\n';

  @override
  String get aboutArrow1 => '  → Avoid taking extra risks here\n\n';

  @override
  String get aboutBullet2 =>
      '• Areas where confident answers or intelligent guesses are usually correct\n';

  @override
  String get aboutArrow2 => '  → Take smarter risks here\n\n';

  @override
  String get aboutBullet3 =>
      '• Common UPSC trap patterns and tricky question types\n';

  @override
  String get aboutArrow3 => '  → Stay alert and avoid negative marking';

  @override
  String get aboutExAspirant => '(Ex-aspirant)';

  @override
  String get aboutWhyTitle => 'Why I Built UPSC Wars';

  @override
  String get aboutHelpsFind => 'It helps you find:';

  @override
  String get aboutConnect => 'Connect';

  @override
  String get aboutReviews => 'Reviews';

  @override
  String get aboutRateReview => 'Rate/Review UPSC Wars';

  @override
  String get aboutFeedbackEmail => 'Send Feedback on Email';

  @override
  String get aboutFeedbackTelegram => 'Send Feedback on Telegram';

  @override
  String get aboutLinkFailed => 'Could not open link';

  @override
  String resultsAccuracyVsLast(String sign, int value) {
    return '$sign$value% accuracy vs your last test';
  }

  @override
  String resultsMarksBreakdown(String earned, String lost) {
    return '+$earned earned · $lost';
  }

  @override
  String get resultsZeroLost => '0 lost';

  @override
  String resultsMarksLost(String value) {
    return '−$value lost';
  }

  @override
  String resultsAllQuestions(int total) {
    return 'All $total questions';
  }

  @override
  String resultsAttemptedSkipped(int attempted, int skipped) {
    return '$attempted attempted · $skipped skipped';
  }

  @override
  String resultsCountCorrect(int count) {
    return '$count correct';
  }

  @override
  String resultsCountWrong(int count) {
    return '$count wrong';
  }

  @override
  String resultsCountSkipped(int count) {
    return '$count skipped';
  }

  @override
  String resultsCorrectOfAttempted(int correct, int attempted) {
    return '$correct of $attempted correct';
  }

  @override
  String resultsAddedToQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions added to revision queue',
      one: '1 question added to revision queue',
    );
    return '$_temp0';
  }

  @override
  String resultsTotalInQueue(int count) {
    return '$count total in queue';
  }

  @override
  String resultsPctWrong(int pct, int wrong, int attempted) {
    return '$pct% wrong ($wrong/$attempted)';
  }

  @override
  String resultsReviewAll(int count) {
    return 'Review all questions ($count)';
  }

  @override
  String resultsTimingLine(int avg, int min, int max) {
    return 'Avg ${avg}s per question · Fastest ${min}s · Slowest ${max}s';
  }

  @override
  String resultsYourScore(int pct) {
    return 'Your score: $pct%';
  }

  @override
  String resultsNameYou(String name) {
    return '$name (you)';
  }

  @override
  String get resultsAttemptToEarn => 'Attempt questions to earn marks';

  @override
  String get resultsNetMarks => 'Net marks';

  @override
  String get resultsNoneAttempted => 'None attempted';

  @override
  String get resultsNoAttemptsYet => 'No attempts yet';

  @override
  String get resultsAttemptAccuracy => 'Attempt accuracy';

  @override
  String get resultsNoneAddedToQueue =>
      'No incorrect answers added from this test.';

  @override
  String get resultsGoToQueue => 'Go to queue';

  @override
  String get resultsWorstTopics => 'Most inaccurate topics';

  @override
  String get resultsBestTopics => 'Top topic accuracy';

  @override
  String get commonShowLess => 'Show less';

  @override
  String get commonViewAll => 'View all';

  @override
  String get resultsBackToHome => 'Back to home';

  @override
  String get resultsMoreInsights => 'More insights';

  @override
  String get resultsAreYouSure => 'Are you sure?';

  @override
  String get resultsReturnHome => 'You will return to the home screen.';

  @override
  String get resultsGoToHome => 'Go to Home';

  @override
  String get resultsLoadFailed => 'Could not load results';

  @override
  String get resultsShareTest => 'Share test';

  @override
  String get resultsSessionSummary => 'Session summary';

  @override
  String get resultsTop5Shared => 'Top 5 for this shared test';

  @override
  String get resultsLeaderboardEmpty => 'It\'s empty.';

  @override
  String get resultsLeaderboardFailed => 'Could not load leaderboard.';

  @override
  String get shareLinkCopied => 'Link copied to clipboard';

  @override
  String get shareTitle => 'Share Test';

  @override
  String get shareQuestion => 'Question';

  @override
  String get shareEntireTest => 'Entire Test';

  @override
  String get shareGenerating => 'Generating link...';

  @override
  String get shareInfoFriends => 'You can share this link with your friends.';

  @override
  String get shareInfoReport =>
      'You can use this link to report any error in this question to the upsc wars team.';

  @override
  String get commonCopy => 'Copy';

  @override
  String get shareContactUs => 'Contact Us';

  @override
  String get shareLink => 'Share Link';

  @override
  String get shareFailed => 'Failed to generate link';

  @override
  String get resultsReviewYourMistakes => 'Review your mistakes';

  @override
  String resultsRealExamCost(String marks) {
    return 'Real exam cost: −$marks marks';
  }

  @override
  String resultsTopRisk(String topic) {
    return 'Top risk area: $topic';
  }

  @override
  String resultsTopRiskPct(String topic, int pct) {
    return 'Top risk area: $topic ($pct% of your loss)';
  }

  @override
  String resultsConfidentMistakesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Confident Mistakes',
      one: '1 Confident Mistake',
    );
    return '$_temp0';
  }

  @override
  String resultsReviewConfidentCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review $count confident mistakes',
      one: 'Review 1 confident mistake',
    );
    return '$_temp0';
  }

  @override
  String resultsEduMistakesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Educated Guess Mistakes',
      one: '1 Educated Guess Mistake',
    );
    return '$_temp0';
  }

  @override
  String resultsReviewEduCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review $count educated guesses',
      one: 'Review 1 educated guess',
    );
    return '$_temp0';
  }

  @override
  String resultsMixedMistakesTitle(int sure, int edu) {
    return '$sure Confident · $edu Educated guess';
  }

  @override
  String resultsIncompleteHeadline(int attempted, int total) {
    return '$attempted of $total attempted';
  }

  @override
  String resultsLeftUnanswered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You left $count questions unanswered. Finish full tests for better insights.',
      one:
          'You left 1 question unanswered. Finish full tests for better insights.',
    );
    return '$_temp0';
  }

  @override
  String resultsQrMixed(int total) {
    return 'You lost marks on $total questions — some you were sure about';
  }

  @override
  String resultsQrSure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You lost marks on $count questions — you were sure about them',
      one: 'You lost marks on 1 question — you were sure about it',
    );
    return '$_temp0';
  }

  @override
  String resultsQrEdu(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You lost marks on $count questions — your educated guess didn\'\'t pay off',
      one:
          'You lost marks on 1 question — your educated guess didn\'\'t pay off',
    );
    return '$_temp0';
  }

  @override
  String get resultsCaseASubtitle =>
      'You were sure, but incorrect. These are rank killers.';

  @override
  String get resultsCaseBSubtitle =>
      'Your elimination strategy failed more often than it worked.';

  @override
  String get resultsCaseCSubtitle =>
      'You lost marks from both overconfidence and risky elimination.';

  @override
  String get resultsCaseDSubtitle =>
      'Wrong answers were pure guesses. You still lost marks worth reviewing.';

  @override
  String get resultsNoConfidentMistakes => 'No confident mistakes';

  @override
  String get resultsExcellentEyebrow => 'EXCELLENT SESSION';

  @override
  String get resultsCaseESubtitle =>
      'When you were confident, you stayed accurate. Keep the momentum.';

  @override
  String get resultsExcellentTitle => 'Excellent session';

  @override
  String get resultsPracticeMore => 'Practice more';

  @override
  String get resultsCaseFSubtitle =>
      'You left questions unanswered. Finish full tests for better insights.';

  @override
  String get resultsIncompleteTitle => 'Incomplete session';

  @override
  String get resultsLockedEyebrow => 'INSIGHTS LOCKED';

  @override
  String get resultsCaseGSubtitle =>
      'Enable confidence tracking to unlock personalised insights.';

  @override
  String get resultsLockedTitle => 'Insights locked';

  @override
  String get resultsEnableTracking => 'Enable confidence tracking';

  @override
  String get resultsCaseHSubtitle =>
      'As this test was attempted without marking confidence.';

  @override
  String get resultsInsightsUnavailable => 'Confidence insights not available';

  @override
  String get resultsRetryWithConfidence => 'Retry with confidence marking';

  @override
  String get resultsCaseISubtitle =>
      'You submitted without answering any questions. Try again when you are ready.';

  @override
  String get resultsNoQuestionsAttempted => 'No questions attempted';

  @override
  String get resultsRetryTest => 'Retry test';

  @override
  String get resultsFinishMore =>
      'Finish more of the test before calling it a clean session.';

  @override
  String get resultsQrTitle => 'QUESTIONS TO REVIEW';

  @override
  String get resultsQrReveal => 'These questions may reveal:';

  @override
  String get resultsQrBullet1 =>
      'Concepts that feel familiar but aren\'t fully clear';

  @override
  String get resultsQrBullet2 =>
      'Topics where the detail matters and you missed it';

  @override
  String get resultsQrBullet3 => 'Avoidable exam-day mistakes';

  @override
  String resultsYouWere(String label) {
    return 'You were $label';
  }

  @override
  String resultsNoTierItems(String label) {
    return 'No $label items';
  }

  @override
  String resultsWithOutcome(String outcome) {
    return ' with outcome “$outcome”';
  }

  @override
  String resultsNoTierBody(String label, String outcome) {
    return 'No scored questions in this session were logged under “$label”$outcome.';
  }

  @override
  String get resultsWrongOnly => ' · Wrong only';

  @override
  String get resultsCorrectOnly => ' · Correct only';

  @override
  String resultsLoggedAs(String tier, String suffix) {
    return 'Logged as: $tier$suffix';
  }

  @override
  String resultsLostMarksOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You lost marks on $count questions',
      one: 'You lost marks on 1 question',
    );
    return '$_temp0';
  }

  @override
  String get resultsWatchOutFor => 'Watch out for:';

  @override
  String get resultsEyebrowSureWrong => 'CONFIDENT · WRONG';

  @override
  String get resultsSureDesc =>
      'You were sure — and lost marks anyway. \n\nGo through these carefully and check whether you misread the question or your understanding has a gap.';

  @override
  String get resultsSureBullet3 => 'Traps that feel obvious in hindsight';

  @override
  String get resultsEyebrowEduWrong => 'EDUCATED GUESS · WRONG';

  @override
  String get resultsEduDesc =>
      'You had some idea but not enough. These are clean gaps — easier to fix than confident mistakes. You know you need to revise these.';

  @override
  String get resultsEduBullet1 => 'Topics that need focused revision';

  @override
  String get resultsEduBullet2 =>
      'Concepts partially encountered but not fully absorbed';

  @override
  String get resultsEduBullet3 =>
      'Areas where elimination logic needs strengthening';

  @override
  String get resultsReviewLoadFailed => 'Could not load review';

  @override
  String get resultsNoDangerItems => 'No Danger Zone items';

  @override
  String get resultsNoDangerBody =>
      'Wrong answers without a confidence pick, or where you marked \"Guessing\", do not appear here.';

  @override
  String get resultsInvalidFilter => 'Invalid confidence filter.';

  @override
  String get resultsNoReviewable => 'No reviewable mistakes in this session.';

  @override
  String get resultsReviewLoadFailedDot => 'Could not load review.';

  @override
  String get resultsSureWrongSeg => 'Sure + wrong';

  @override
  String get resultsEduWrongSeg => 'Edu guess + wrong';

  @override
  String get resultsReviewConfidentMistakes => 'Review confident mistakes';

  @override
  String get resultsSwipeBoth => 'Swipe to see both types';

  @override
  String get resultsStartReview => 'Start review';

  @override
  String resultsUnlockMapBody(int answered) {
    return 'You did not log confidence on any of your $answered scored questions. After each answer, use the three chips under your chosen option — it takes one tap and powers Danger Zone, accuracy by tier, and smarter revision hints.';
  }

  @override
  String resultsLogMoreBody(int logged, int answered, String pct) {
    return 'You tagged $logged of $answered scored questions ($pct%). Aim for at least half — the more you log, the sharper your insights get.';
  }

  @override
  String resultsSureWarn(String pct, int correct, int total) {
    return 'When you tapped Sure, you were right $pct% of the time ($correct / $total). Aim for about 75%+ on high-conviction picks before Prelims.';
  }

  @override
  String resultsSureOk(String pct, int correct, int total) {
    return 'Sure-tier accuracy $pct% ($correct / $total). That is in a healthy range for conviction answers.';
  }

  @override
  String get resultsMatrixHint =>
      'Tap a cell to review those questions only (same session).';

  @override
  String get resultsUnlockMap => 'Unlock this map next time';

  @override
  String get resultsLogMore => 'Log a bit more next round';

  @override
  String get resultsMatrixCorrect => 'Correct';

  @override
  String get resultsMatrixWrong => 'Wrong';

  @override
  String get resultsCoverageHint =>
      'Questions where you tapped Sure, Intelligent, or Pure guess after answering.';

  @override
  String get resultsCoachMistakesTitle => 'Review only your mistakes';

  @override
  String get resultsCoachMistakesBody =>
      'Just the questions you got wrong — the ones worth going back to.';

  @override
  String get resultsCoachAllOr => 'Or review all questions';

  @override
  String get resultsCoachAll => 'Review all questions';

  @override
  String get resultsCoachAllBody =>
      'The full paper, including the ones you got right.';

  @override
  String get resultsCoachTopicsTitle => 'You don’t have to remember this';

  @override
  String get resultsCoachTopicsBody =>
      'The same weak and strong topic lists live on every subject. Open a subject from Home anytime.';

  @override
  String get resultsCoachGotIt => 'Got it';

  @override
  String get resultsCoachNext => 'Next';

  @override
  String commonQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String bookmarksSavedCount(int count) {
    return '$count saved';
  }

  @override
  String get revisionStartSession => 'Start revision session';

  @override
  String get revisionEmptyTitle => 'Your revision queue is empty';

  @override
  String get revisionEmptyBody =>
      'Questions you get wrong or bookmark will appear here';

  @override
  String get revisionNoItemsSubject => 'No items for this subject.';

  @override
  String get revisionMastered => 'Mastered';

  @override
  String get revisionInQueue => 'In queue';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get commonUndo => 'Undo';

  @override
  String get bookmarksEmptyTitle => 'No bookmarks yet';

  @override
  String get bookmarksEmptyBody =>
      'Bookmark questions during a test to save them here';

  @override
  String get commonRemove => 'Remove';

  @override
  String trapsCatalogCount(int count) {
    return '$count UPSC traps';
  }

  @override
  String trapsCaughtOfTotal(int caught, int total) {
    return '$caught of $total have caught you';
  }

  @override
  String weakGroupSummary(String questions, String times) {
    return '$questions · got wrong $times';
  }

  @override
  String commonTimesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String trapsCaughtByThis(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions caught by this trap',
      one: '1 question caught by this trap',
    );
    return '$_temp0';
  }

  @override
  String weakNeedMore(String subject) {
    return 'Attempt more questions to start seeing your weak areas for $subject';
  }

  @override
  String trapsCaughtCount(int count) {
    return 'Caught you $count×';
  }

  @override
  String topicInRevisionQueue(int count) {
    return '$count in revision queue';
  }

  @override
  String topicDangerLine(int sure, int edu) {
    return 'Sure wrong: $sure · Educated guess wrong: $edu (all-time)';
  }

  @override
  String subjectTestInfo(String questions, int topics) {
    return '$questions questions · $topics topics';
  }

  @override
  String pyqNoQuestionsYear(String year) {
    return 'No questions are available for $year yet.';
  }

  @override
  String pyqSetOf(int n, int total) {
    return 'Set $n of $total';
  }

  @override
  String pyqFixedOrder(int count) {
    return '$count questions (fixed order for this set)';
  }

  @override
  String pyqTestN(int n) {
    return 'Test $n';
  }

  @override
  String pyqQuestionsRange(int from, int to) {
    return 'Questions $from–$to';
  }

  @override
  String notifLoadFailed(String error) {
    return 'Could not load message.\n$error';
  }

  @override
  String get trapsNoCatalog => 'No trap catalog yet';

  @override
  String get commonNoDataFound => 'No data found';

  @override
  String get weakPracticeSubtopic => 'Practice This Sub-topic';

  @override
  String get weakPracticeTrap => 'Practice This Trap Type';

  @override
  String get trapsCaughtZero => 'Caught you 0× — not enough data yet';

  @override
  String get trapsSeeExample => 'See example';

  @override
  String get weakLegend =>
      'Accuracy = % correct among attempted questions in the topic.\nAttempt = % of topic questions you have attempted.';

  @override
  String get trapsExampleEyebrow => 'EXAMPLE';

  @override
  String get trapsExampleLoadFailed => 'Could not load an example.';

  @override
  String get trapsNoExample => 'No example written for this trap yet.';

  @override
  String get trapsSpotted => 'You spotted it.';

  @override
  String get trapsThatsTheTrap => 'That\'s the trap.';

  @override
  String get trapsTrackingNote =>
      'We keep track of which traps catch you most, so you can watch for them in the exam.';

  @override
  String get topicSearchHint => 'Search topics...';

  @override
  String get topicNoMatch => 'No topics match your search.';

  @override
  String get topicLoadFailed => 'Could not load topics.';

  @override
  String get subjectTestChooseBattle => 'Choose a subject to start battle';

  @override
  String get subjectTestChooseBegin => 'Choose a subject to begin';

  @override
  String get subjectTestStartBattle => 'Start battle';

  @override
  String get subjectTestLoadFailed => 'Could not load subjects.';

  @override
  String get pyqLoadFailed => 'Could not load PYQ sets';

  @override
  String get commonCompleted => 'Completed';

  @override
  String get notifScreenTitle => 'Notification';

  @override
  String get notifNoAnnouncement => 'No announcement is available right now.';

  @override
  String get notifEmptyAnnouncement => 'This announcement is empty.';

  @override
  String topicsAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count attempts',
      one: '· 1 attempt',
    );
    return '$_temp0';
  }

  @override
  String commonDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String subjCorrectOfTotal(int correct, int total, String pct) {
    return '$correct/$total correct · $pct%';
  }

  @override
  String subjQuestionsPlain(int count) {
    return '$count questions';
  }

  @override
  String dzStartFailed(String error) {
    return 'Could not start session: $error';
  }

  @override
  String dzTitleOf(String label) {
    return 'Danger zone of $label';
  }

  @override
  String dzTotalLine(int count, String marks) {
    return 'Total: $count wrong · about $marks marks (0.66 each if counted)';
  }

  @override
  String dzApproxMarks(String marks) {
    return '≈ $marks marks';
  }

  @override
  String subjAllTopicsIn(String subject) {
    return 'Questions from all topics in $subject';
  }

  @override
  String subjPracticeTopicsCount(int count) {
    return 'Practice specific topics ($count topics)';
  }

  @override
  String subjCompletedSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed sessions',
      one: '1 completed session',
    );
    return '$_temp0';
  }

  @override
  String get commonWrongLower => 'wrong';

  @override
  String subjTopicOpenFailed(String error) {
    return 'Could not open topic: $error';
  }

  @override
  String subjAdviceFor(String subject) {
    return 'ADVICE FOR $subject';
  }

  @override
  String subjSureEduWrong(int sure, int edu) {
    return 'Sure wrong: $sure · Edu guess wrong: $edu';
  }

  @override
  String subjConfidentRate(String rate, String global) {
    return 'When confident: $rate% right · vs $global% overall';
  }

  @override
  String get subjHistLoadFailed => 'Could not load history.';

  @override
  String get subjHistEmptyTitle => 'No completed sessions yet.';

  @override
  String get subjHistEmptyBody => 'Start a test to see your results here.';

  @override
  String get subjStartTest => 'Start a test';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get topicsNotStarted => 'Not started';

  @override
  String get topicsNoneFound => 'No topics found for this subject.';

  @override
  String get topicsBankInstalling =>
      'If your question bank is still installing, go back and try again in a moment.';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get subjModeLearning => 'Learning';

  @override
  String get subjModeExam => 'Exam';

  @override
  String get dzNoQuestions => 'No questions in this category.';

  @override
  String get dzSubtitle =>
      'Wrong answers with Sure or Educated-guess (all-time)';

  @override
  String get dzCalm => 'No Sure or Educated-guess wrong answers yet.';

  @override
  String get dzSureWrong => 'Sure — wrong';

  @override
  String get dzSureWrongBody => 'You marked Sure and answered incorrectly.';

  @override
  String get dzEduWrong => 'Educated guess — wrong';

  @override
  String get dzEduWrongBody =>
      'You marked Educated guess and answered incorrectly.';

  @override
  String get commonRevise => 'Revise';

  @override
  String get topicSheetNoQuestions => 'No questions in this topic right now.';

  @override
  String get topicSheetInsights => 'INSIGHTS';

  @override
  String get topicSheetDzFailed => 'Could not load Danger zone.';

  @override
  String get mockReviseTitle => 'Revise Before Your Next Mock';

  @override
  String get mockReviseWhy =>
      'These are topics where your Sure + Incorrect and Educated Guess + Incorrect are higher than your usual average.';

  @override
  String get mockWhatToDo => 'What to do';

  @override
  String get mockReviseAction =>
      'Revise these topics from your notes first before your next mock to reduce costly mistakes and improve your score.';

  @override
  String get mockSafeTitle => 'Safe Areas for Higher Attempts';

  @override
  String get mockSafeWhy =>
      'These are topics where your Sure + Correct and Educated Guess + Correct are better than your usual average.';

  @override
  String get mockSafeAction =>
      'Be more confident while attempting questions from these topics in mocks and exams.';

  @override
  String get mockMoreClarity => 'Want further clarity? ';

  @override
  String get subjFeedbackLead => 'Any questions or feedback?\\n';

  @override
  String get subjGetInTouch => 'Get in touch';

  @override
  String get subjBrowseTopicsLower => 'Browse topics';

  @override
  String get subjNewTestBody => 'Start a test or practice specific topics.';

  @override
  String get subjStartAndMark =>
      'Start a test and mark confidence to see your insights';

  @override
  String get subjBrowseTopics => 'Browse Topics';

  @override
  String get subjPracticeTopics => 'Practice specific topics';

  @override
  String get subjHistoryBody => 'List of Completed sessions for this subject.';

  @override
  String get subjSessionCountFailed => 'Could not load session count.';

  @override
  String get subjViewHistory => 'View test history';

  @override
  String get subjNoSessionsYet => 'No completed sessions yet';

  @override
  String get subjStatsFailed => 'Could not load subject stats.';

  @override
  String get subjMarkHint =>
      'Mark Sure or Educated guess when you answer scored questions in this subject — mock-prep advice and your confidence breakdown will appear here.';

  @override
  String get subjStatsSharpen =>
      'More scored answers with confidence labels sharpen these stats.';

  @override
  String get subjNoAttemptsYet =>
      'No attempted answers yet.\\nStart a test and mark confidence to see your insights';

  @override
  String get subjAccuracySuffix => ' accuracy';

  @override
  String get subjMcqsAttempted => ' MCQs attempted';

  @override
  String get subjSureNone => 'Sure → wrong: — (no Sure-marked answers yet)';

  @override
  String get subjGuessNone =>
      'Educated guess → wrong: — (no Educated-guess answers yet)';

  @override
  String get subjBreakdownTitle => 'Your confidence breakdown in this subject';

  @override
  String get subjNoConfidentWrongs => 'No confident wrongs to analyse yet';

  @override
  String get subjReviseQuestions => 'Revise these questions';

  @override
  String get subjTopicNotFound => 'Topic not found in catalog.';

  @override
  String get subjReviseMcqs => 'Revise MCQs';

  @override
  String get subjAdviceSubtitle => 'Where to revise vs where to attempt more';

  @override
  String get subjAdviceEmpty =>
      'Start attempting MCQs with marking confidence to see advices and insights here';

  @override
  String get subjReviseTopicsIntro =>
      'You are likely to lose marks in these topics due to overconfidence and risky guessing.';

  @override
  String get subjTopicsToRevise => 'Topics to revise';

  @override
  String get subjNoTopicsToList => 'No topics to list';

  @override
  String get subjNoTopicsBody =>
      'No topic in this subject has enough wrong answers marked “Very sure” or “Somewhat sure” to show here yet. As that pattern shows up, you will see it broken down by type of confidence.';

  @override
  String get subjWhyTopics => 'Why these topics?';

  @override
  String get subjRevisitTopic => 'Revisit this topic';

  @override
  String get subjSafeIntro =>
      'You can trust your judgment more in these topics. Attempt more from here in mocks and exams.';

  @override
  String get subjSafeTopics => 'Safe scoring topics';

  @override
  String get subjBaselineNotReady => 'Baseline not ready';

  @override
  String get subjNoTopicsQualify => 'No topics qualify yet';

  @override
  String get subjBaselineBody =>
      'We need a solid sample of scored answers where you were very or somewhat sure. Keep using confidence on tests so we can set your global rate and list topics that beat it.';

  @override
  String get subjNoQualifyBody =>
      'In this subject, no topic is clearly above your overall confident-correct rate yet. The list will update as you add more very sure or somewhat sure attempts.';

  @override
  String get subjAttemptMore => 'Attempt more';

  @override
  String get subjMockPrepFailed => 'Could not load mock-prep tips.';

  @override
  String get subjInsightsFailed => 'Could not load insights.';

  @override
  String notifPaperBody(int count) {
    return '$count MCQs from the news you just read';
  }

  @override
  String notifPaperBodyTonight(int count, String topics) {
    return '$count MCQs from the news · Tonight: $topics';
  }

  @override
  String prelimsDaysTo(int days) {
    return '$days days to UPSC Prelims';
  }

  @override
  String prelimsBodyDays(int days) {
    return '$days days to go\nSmall steps, every day — that\'s the edge.';
  }

  @override
  String get notifNoTestTitle => 'Find where UPSC Wars gives you an edge';

  @override
  String get notifNoTestBody =>
      'Take 7 quick MCQs. Get coached to eliminate better, spot weak areas, and see where you’re strong.';

  @override
  String get notifBattleInviteTitle => 'Battle invite';

  @override
  String get notifTapToJoin => 'Tap to join';

  @override
  String get notifCaShotTitle => 'CA Shot';

  @override
  String get notifTapToRead => 'Tap to read & attempt';

  @override
  String get notifNewMessage => 'New message';

  @override
  String get notifTapToOpenChat => 'Tap to open chat';

  @override
  String get notifPaperTitle => 'Today\'s paper quiz is live';

  @override
  String get prelimsToday => 'Prelims is today';

  @override
  String get prelimsBodyToday =>
      'It\'s the exam day,\nYou\'ve prepared for this — breathe and execute.';

  @override
  String get prelimsBodyOneDay => '1 day to go,\nOne calm session at a time.';

  @override
  String dcaProgressFailed(String error) {
    return 'Could not load progress: $error';
  }

  @override
  String dcaOfCount(int count) {
    return 'of $count';
  }

  @override
  String dcaAvailableIn(String countdown) {
    return 'Test available in $countdown';
  }

  @override
  String dcaJoinedCount(int count) {
    return '$count joined';
  }

  @override
  String dcaTestFromNews(String date) {
    return 'This test is from questions from $date.';
  }

  @override
  String dcaNoChampionYet(String date) {
    return '$date · No champion locked yet';
  }

  @override
  String dcaJoinedLocked(String date, int count) {
    return '$date · $count joined · Champion locked';
  }

  @override
  String dcaJoinedLive(String date, int count) {
    return '$date · $count joined · live';
  }

  @override
  String dcaYouAir(int air) {
    return 'You · AIR $air';
  }

  @override
  String dcaStartFrom(String date) {
    return 'Daily tests start from $date.';
  }

  @override
  String dcaTenFromPaper(String date) {
    return '10 MCQs from the $date paper';
  }

  @override
  String dcaLiveIn(String t) {
    return 'Live in $t';
  }

  @override
  String dcaNextTestIn(String t) {
    return 'Next test in $t';
  }

  @override
  String get dcaThisMonth => 'This month';

  @override
  String get dcaReviewOrRevise => 'Review or revise';

  @override
  String get dcaTakeTodays => 'Take today\'s test';

  @override
  String get dcaTodaysPaperBtn => 'Today\'s paper';

  @override
  String get dcaNoRanks =>
      'No ranks yet. Be the first to finish today\'s paper.';

  @override
  String get dcaSubmitFailed => 'Submit failed';

  @override
  String get dcaLoadingResults => 'Loading your results…';

  @override
  String get dcaTodaysBoard => 'Today\'s board';

  @override
  String get dcaRanksPreview => 'Ranks are in preview.';

  @override
  String get dcaSignInForAir =>
      'Sign in from Profile to join today\'s All-India Rank.';

  @override
  String get dcaUnrankedLocked =>
      'Unranked · this paper\'s Champion is already locked.';

  @override
  String get dcaSubmitted => 'Submitted.';

  @override
  String get dcaTodaysLeaderboard => 'Today\'s leaderboard';

  @override
  String get dcaReviewAnswers => 'Review answers';

  @override
  String get dcaLiveUnranked => 'Unranked · Champion already locked.';

  @override
  String get dcaLiveAir => 'AIR can still move. Champion locks at 6 AM IST.';

  @override
  String get dcaNotAvailableCopy =>
      'Questions for this date are not available yet.';

  @override
  String get dcaGenericLoadCopy =>
      'Could not load test. Check your connection and try again.';

  @override
  String get testStartTest => 'Start test';

  @override
  String get dcaNotLiveTitle => 'Questions aren\'t live yet';

  @override
  String get dcaSoonTitle => 'Questions will be available soon';

  @override
  String get dcaNotLiveBody =>
      'This morning\'s paper was generated, but it has not been published to the app yet. Pull home to refresh in a minute.';

  @override
  String get dcaSoonBody =>
      'Each paper is built from news articles. It tests how well you read the previous day\'s news — yesterday\'s newspaper, this morning\'s quiz.';

  @override
  String get dcaSeePast => 'See past current affairs MCQs';

  @override
  String get dcaChampionLocked => 'Champion is locked for this paper.';

  @override
  String get dcaPullRefresh => 'Pull to refresh. Champion locks at 6 AM.';

  @override
  String get dcaLinkFailed => 'Could not open this link.';

  @override
  String get dcaReviseThisDayRec =>
      'You can revise this day\'s current affairs from our recommended links.';

  @override
  String get dcaAvailableSoon => 'Available soon';

  @override
  String get dcaReviseThisTest => 'Revise this test';

  @override
  String get dcaStartTodays => 'Start today\'s test';

  @override
  String get dcaStartTheTest => 'Start the test';

  @override
  String get dcaFavSources =>
      'These are our favourite sources for this day\'s current affairs.';

  @override
  String get dcaQuizNotOpen =>
      'Today\'s quiz isn\'t open yet. Check back after 6 AM, or pick a past day below.';

  @override
  String get dcaAlreadySubmitted =>
      'You already submitted. Review answers or revise in learning mode.';

  @override
  String get dcaSameQuestions =>
      'Same questions for everyone — based on yesterday\'s news.';

  @override
  String get dcaReviseLearning => 'Revise (learning)';

  @override
  String get dcaSignInLeaderboard => 'Sign in to see the leaderboard.';

  @override
  String get dcaEyebrowToday => 'TODAY';

  @override
  String get dcaEyebrowYesterday => 'YESTERDAY';

  @override
  String get dcaLiveFirst => 'Live ranks · be the first to finish';

  @override
  String get dcaSeeAllRanks => 'See all ranks';

  @override
  String get dcaFinishToAppear => 'Finish the paper to appear on the board.';

  @override
  String get dcaTodayOpens => 'Today\'s test opens at 6 AM';

  @override
  String get dcaTomorrowOpens => 'Tomorrow\'s test opens at 6 AM';

  @override
  String get dcaGoesLive6 =>
      'Today\'s current affairs test, from yesterday\'s news, goes live at 6 AM.';

  @override
  String get dcaNoPaperToday =>
      'No paper today. The next one lands tomorrow at 6 AM.';

  @override
  String get dcaQuizDone =>
      'Quiz done. Open the explanations if a line still nags.';

  @override
  String get dcaCaFromYesterday =>
      'Current affairs test from yesterday\'s news.';

  @override
  String get dcaReviseThisDay =>
      'You can revise this day\'s current affairs from these links.';

  @override
  String get dcaNotStartedYet => 'Not started yet';

  @override
  String get dcaViewResults => 'View results';

  @override
  String get dcaReviseYesterdayRec =>
      'You can revise yesterday\'s current affairs from our recommended links.';

  @override
  String get dcaReviseYesterday =>
      'You can revise yesterday\'s current affairs from these links.';

  @override
  String get dcaTestWillBeFrom => 'Today\'s test will be from :\n';

  @override
  String get dwStarting => 'Starting…';

  @override
  String dwStartsIn(String t) {
    return 'Starts in $t';
  }

  @override
  String get dwJoinNow => 'Join now';

  @override
  String get dwSignInJoin => 'Sign in to join';

  @override
  String get dwAttemptUnranked => 'Attempt unranked';

  @override
  String get dwSignInAttempt => 'Sign in to attempt';

  @override
  String get dwLobbyOpen => 'LOBBY OPEN';

  @override
  String get dwInProgress => 'IN PROGRESS';

  @override
  String get dwSundayOff => 'SUNDAY OFF';

  @override
  String get dwOpenAttempt => 'Open your attempt';

  @override
  String get dwAspirantsInLobby => 'aspirants in the lobby';

  @override
  String get dwWritingNow => 'writing right now';

  @override
  String get dwLateJoinClosed => 'Late join closed';

  @override
  String get dwPaperNotLoaded =>
      'Tonight\'s paper isn\'t loaded yet. Try again in some time.';

  @override
  String get dwHistory => 'History';

  @override
  String dwTomorrowTopics(String topics) {
    return 'Tomorrow · $topics';
  }

  @override
  String get dwPractice => 'Practice';

  @override
  String dwNextEventMonday(String event) {
    return 'Next $event is Monday at 9:00 PM IST.';
  }

  @override
  String dwEventLobbyOpen(String event) {
    return '$event lobby is open.';
  }

  @override
  String dwEventIsLive(String event) {
    return '$event is live.';
  }

  @override
  String dwEventTonight(String event) {
    return '$event TONIGHT';
  }

  @override
  String dwSatEventStarts(String event) {
    return 'Saturday $event starts at 9:00 PM IST.';
  }

  @override
  String dwEventStarts(String event) {
    return '$event starts at 9:00 PM IST.';
  }

  @override
  String dwFooterTonight(String event) {
    return 'Tonight\'s $event starts at 9 PM';
  }

  @override
  String dwFooterMonday(String event) {
    return 'Monday\'s $event starts at 9 PM';
  }

  @override
  String dwFooterNext(String event) {
    return 'Next $event starts at 9 PM';
  }

  @override
  String dwRestDay(String event) {
    return 'Rest day · $event returns Monday 9 PM';
  }

  @override
  String dwWeekComplete(int n) {
    return 'Week $n complete';
  }

  @override
  String dwNightsOf(int a, int b) {
    return '$a of $b nights';
  }

  @override
  String dwTopicsWentBy(int n) {
    return '$n topics went by · nothing lost for Monday';
  }

  @override
  String dwTopicsLanded(int n) {
    return '$n topics landed';
  }

  @override
  String dwStillOpen(int n) {
    return ' · $n still open';
  }

  @override
  String dwTonightTopics(String topics) {
    return 'Tonight: $topics';
  }

  @override
  String dwDailyDrillSubject(String subject) {
    return 'Daily Drill · $subject';
  }

  @override
  String dwHowWorks(String program) {
    return 'How $program works';
  }

  @override
  String dwHelpLiveBody(int wq, int wm, int gq, int gm, String event) {
    return 'Same paper, All-India · ${wq}Q / ${wm}m weeknights · ${gq}Q / ${gm}m Sat $event';
  }

  @override
  String dwAirAt(String t) {
    return 'AIR at $t';
  }

  @override
  String dwHelpRhythmBody(String event) {
    return '2 topics Mon–Fri · $event Sat · Sunday off';
  }

  @override
  String dwDrawsFromMany(int n) {
    return 'Tonight\'s war draws from these $n topics. Run the PYQs now so you walk in warm.';
  }

  @override
  String dwYourWeekIn(String program) {
    return 'Your week in $program';
  }

  @override
  String dwUpRanks(int n) {
    return 'up $n ranks';
  }

  @override
  String dwRanksLockAfter(String date) {
    return '$date · Ranks lock after the paper closes';
  }

  @override
  String dwBadgesLoadFailed(String error) {
    return 'Could not load badges: $error';
  }

  @override
  String dwEventSaturday(String event) {
    return '$event · SATURDAY';
  }

  @override
  String dwMoreSeeAll(int n) {
    return '+ $n more · See all →';
  }

  @override
  String dwTopicsCovered(int covered, int total) {
    return '$covered of $total topics covered';
  }

  @override
  String dwTonightAdds(int n) {
    return 'tonight adds $n';
  }

  @override
  String dwWarStartsIn(String t) {
    return 'WAR STARTS IN $t';
  }

  @override
  String dwTimerStartsOnEntry(String t) {
    return 'Your timer starts on entry — the $t close does not move.';
  }

  @override
  String dwEntryClosesIn(String t) {
    return 'ENTRY CLOSES IN $t';
  }

  @override
  String dwYourAirReady(int air) {
    return 'Your AIR $air is ready';
  }

  @override
  String dwTonightEventLive(String event) {
    return 'Tonight\'s $event is live';
  }

  @override
  String dwAspirantsTopics(String n, String topics) {
    return '$n aspirants · $topics';
  }

  @override
  String dwSeeYourAir(int air) {
    return 'See your AIR $air';
  }

  @override
  String dwTonightsResult(String date) {
    return 'TONIGHT\'S RESULT · $date';
  }

  @override
  String dwAspirantsWroteIt(String n) {
    return '$n aspirants wrote it';
  }

  @override
  String dwPracticedUnranked(String score) {
    return 'You practiced unranked · $score';
  }

  @override
  String dwBadgesCount(int kinds, int earned) {
    return '$kinds badges · $earned total earns';
  }

  @override
  String dwEventIsLiveCaps(String event) {
    return '$event IS LIVE';
  }

  @override
  String dwNoLiveNext(String event) {
    return 'No live paper today. Next $event is Monday at 9:00 PM IST.';
  }

  @override
  String dwPlusMore(int n) {
    return '+ $n more';
  }

  @override
  String dwSeeAllTopics(int n) {
    return 'See all $n topics →';
  }

  @override
  String dwJoinUntilLeft(String t) {
    return 'Join until 9:10 · $t left';
  }

  @override
  String dwNoPaperNext(String event) {
    return 'No paper today · next $event Monday 9:00 PM';
  }

  @override
  String dwLateClosedAirAt(String t) {
    return 'Late join closed · AIR at $t';
  }

  @override
  String dwStartFailed(String error) {
    return 'Could not start War: $error';
  }

  @override
  String dwLoadFailed(String error) {
    return 'Could not load Static War: $error';
  }

  @override
  String dwPaperLoadFailed(String error) {
    return 'Could not load tonight\'s paper: $error';
  }

  @override
  String dwBattleStartsLeft(String t) {
    return 'Battle starts at 9:00 PM IST · $t left.';
  }

  @override
  String dwRulesLobby(int q, int m) {
    return '$q Q · $m MIN · ONE ATTEMPT';
  }

  @override
  String get dwNoLivePaper => 'No live paper today.';

  @override
  String get dwYouWereIn => 'You were in tonight\'s paper.';

  @override
  String get dwOpenRankExpl => 'Open your rank and explanations.';

  @override
  String get dwAttemptInResultsFollow =>
      'Your attempt is in. Results will follow.';

  @override
  String get dwPaperStarts9 => 'Paper starts at 9:00 PM IST.';

  @override
  String get dwLiveNow => 'LIVE NOW';

  @override
  String get dwLiveJoinBefore =>
      'All-India live paper. Join before the window closes.';

  @override
  String get dwEntryClosedRanks =>
      'Entry closed at 9:10 PM IST. Ranks at 9:40 PM.';

  @override
  String get dwWindowClosed => 'Tonight\'s live window has closed.';

  @override
  String get dwStillUnranked => 'You can still attempt this paper unranked.';

  @override
  String get dwWeekRevision => 'Week revision. Same paper, All-India.';

  @override
  String get dwLobbyOpens859 => 'All-India live paper. Lobby opens at 8:59 PM.';

  @override
  String get dwSundayNoBattle => 'SUNDAY · NO BATTLE TONIGHT';

  @override
  String get dwQuietWeek => 'A quiet week';

  @override
  String get dwNoBattleNights =>
      'No battle nights this week · Monday is a fresh start';

  @override
  String get dwStreakSafe => 'Streak safe · revise or rest until Monday';

  @override
  String get dwFullWeekSummary => 'Full week summary';

  @override
  String get dwTopicsMonday => 'Topics up Monday morning';

  @override
  String get dwCatchUp => 'Catch up';

  @override
  String get dwReviseWeek => 'Revise week';

  @override
  String get dwPracticeEarly => 'Practice early';

  @override
  String get dwUpNext => 'UP NEXT';

  @override
  String get dwMonday9 => 'Monday · 9 PM';

  @override
  String get dwWeekStrip =>
      'Mon–Fri new topics · Sat revises the week · Sunday off';

  @override
  String get dwExplainerHead => 'Full syllabus.\nTwo topics at a time.';

  @override
  String get dwExplainerSub =>
      '9 PM live paper. Same questions. Then you see the leaderboard.';

  @override
  String get dwPaperIsTheseSat => 'Saturday\'s paper is these:';

  @override
  String get dwPaperIsThis => 'Tonight\'s paper is this:';

  @override
  String get dwPaperIsThese => 'Tonight\'s paper is these:';

  @override
  String get dwWeekTopicsLand => 'This week\'s two topics land here.';

  @override
  String get dwTonightTopicsLand => 'Tonight\'s two topics land here.';

  @override
  String get dwTry10 => 'Try 10 questions on these';

  @override
  String get dwQuick10 => '10 quick MCQs on tonight\'s subject';

  @override
  String get commonTryAgainError => 'Something went wrong. Please try again.';

  @override
  String get dwStep2 => 'STEP 2 · PREPARE';

  @override
  String get dwHelpLiveTitle => 'Live at 9:00 PM';

  @override
  String get dwHelpAirBody =>
      'See your score on submission · we\'ll notify you when ranks are ready';

  @override
  String get dwHelpRhythmTitle => 'Week rhythm';

  @override
  String get dwHelpMissedTitle => 'Missed a night?';

  @override
  String get dwHelpMissedBody => 'Practice later · no rank · streak breaks';

  @override
  String get dwReviseBefore9 => 'Revise before 9 PM';

  @override
  String get dwDrawsFromOne =>
      'Tonight\'s war draws from this topic. Run the PYQs now so you walk in warm.';

  @override
  String get dwRevisionNoRank =>
      'Revision here does not count towards your war rank.';

  @override
  String get dwNoQuestionsTopic => 'No questions available for this topic yet.';

  @override
  String get dwStartPractice => 'Start practice';

  @override
  String get dwNightsAttempted => 'nights attempted';

  @override
  String get dwConfidentlyWrong => 'Confidently wrong';

  @override
  String get dwConfWrongBody =>
      'Topics where you marked Sure / Educated guess and missed.';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get dwDangerLoadFailed => 'Couldn\'t load danger topics.';

  @override
  String get dwNoAttemptsWeek => 'No attempts this week yet.';

  @override
  String get dwNoneWeek => 'None this week — keep that map clean.';

  @override
  String get dwBadgesEarned => 'Badges earned';

  @override
  String get dwShowUpMonday => 'Show up Monday to start collecting.';

  @override
  String get dwNoBadgesWeek => 'No badges this week.';

  @override
  String get dwNoBadgesNight => 'No badges earned this night yet.';

  @override
  String get dwTiersNote =>
      'Consistency tiers climb over 30 War nights. Miss two nights in a row and you fall one tier.';

  @override
  String get dwTonight => 'TONIGHT';

  @override
  String get dwLastNight => 'LAST NIGHT';

  @override
  String get dwLastWar => 'LAST WAR';

  @override
  String get dwSeeBoard => 'See board';

  @override
  String get dwNoChampionYet =>
      'No champion yet. Ranks land here after the paper locks.';

  @override
  String get dwEarnedBadges => 'EARNED BADGES';

  @override
  String get dwNoBadgeYet => 'You have not yet earned a badge';

  @override
  String get dwStarts9 => 'STARTS 9:00 PM IST';

  @override
  String get dwLobbyFilling => 'The lobby is filling up';

  @override
  String get dwEnterLobby => 'Enter lobby';

  @override
  String get dwWarIsLive => 'WAR IS LIVE';

  @override
  String get dwStarted9 => 'STARTED 9:00 PM IST';

  @override
  String get dwJoinUntil910 => 'You can still join until 9:10';

  @override
  String get dwYoureIn => 'YOU\'RE IN';

  @override
  String get dwEntryClosed910 => 'ENTRY CLOSED 9:10 PM';

  @override
  String get dwAttemptInAir940 => 'Your attempt is in · AIR at 9:40 PM IST';

  @override
  String get dwLateJoinClosedDot => 'Late join closed.';

  @override
  String get dwEntryCloses910 => 'Entry closes at 9:10.';

  @override
  String get dwTodaysWarLive => 'Today\'s war is live';

  @override
  String get dwResultsEyebrow => 'RESULTS';

  @override
  String get dwAirAt940 => 'AIR AT 9:40 PM';

  @override
  String get dwScoreInNotify =>
      'Your score is in · we\'ll notify you when AIR is ready';

  @override
  String get dwBattleOverAir => 'Tonight\'s battle is over · AIR at 9:40 PM';

  @override
  String get dwFullResults => 'Full results & review';

  @override
  String get dwBattleOverCaps => 'TONIGHT\'S BATTLE IS OVER';

  @override
  String get dwSatOut => 'You sat this one out';

  @override
  String get dwAttemptInPending => 'Your attempt is in · rank pending';

  @override
  String get dwSeeTonightsPaper => 'See tonight\'s paper';

  @override
  String get dwUnrankedAttempt => 'Unranked attempt';

  @override
  String get dwSeeYourAttempt => 'See your attempt';

  @override
  String get dwTomorrow9 => 'Tomorrow · 9:00 PM IST';

  @override
  String get dwNoQuestionsAvail => 'No questions available';

  @override
  String get dwStaticWarRevise => 'Static War revise';

  @override
  String get dwTonightsLeaderboard => 'Tonight\'s war · leaderboard';

  @override
  String get dwLeaderboardNotReady => 'Leaderboard not ready yet.';

  @override
  String get dwBadgesSyncNote =>
      'Counts sync from your Static War nights — kept on this device and in the cloud.';

  @override
  String get dwResultsTitle => 'Static War results';

  @override
  String get dwSubmitting => 'Submitting your answers…';

  @override
  String get dwDemoted =>
      'Your paper came in after the live window closed, so it\'s saved as an unranked attempt.';

  @override
  String get dwUnrankedNotOfficial => 'Unranked · not an official AIR';

  @override
  String get dwSubmittedAirReady =>
      'Submitted · AIR will be ready at 9:40 PM IST. We\'ll notify you.';

  @override
  String get dwTomorrow => 'Tomorrow';

  @override
  String get dwTonightsLeaderboardBtn => 'Tonight\'s leaderboard';

  @override
  String get dwNotAvailable => 'Static War is not available.';

  @override
  String get dwNotAvailableAccount =>
      'Static War is not available on this account yet.';

  @override
  String get dwSundayOffTitle => 'Sunday off';

  @override
  String get dwPracticeTopics => 'Practice these topics →';

  @override
  String get dwOpenHistory => 'Open History';

  @override
  String get dwCantJoinNow => 'You can\'t join now';

  @override
  String get dwComeBack859 => 'Come back at 8:59 PM IST to enter the lobby.';

  @override
  String get dwResultsReady => 'RESULTS READY';

  @override
  String get dwPrepareToday => 'Prepare today · lobby opens 8:59 PM';

  @override
  String get dwRanksCalculating => 'Ranks calculating…';

  @override
  String get dwResultsReadyTitle => 'Results ready';

  @override
  String get dwReady => 'Ready';

  @override
  String get dwHistoryCaps => 'HISTORY';

  @override
  String get dwSignInAttemptWar => 'Sign in to attempt this War.';

  @override
  String get dwSignInJoinWar => 'Sign in to join tonight\'s War.';

  @override
  String get dwAlreadySubmitted => 'You already submitted this War.';

  @override
  String get dwAlreadyPracticed => 'You already practiced this War.';

  @override
  String get dwUpdateApp =>
      'Update the app to attempt tonight\'s War — some of this paper isn\'t in your question bank yet.';

  @override
  String get dwTopicsLoadFailed => 'Couldn\'t load tonight\'s topics';

  @override
  String get dwTopicsFinding => 'Finding tonight\'s topics…';

  @override
  String get dwTwoTopics => 'Two topics a night';

  @override
  String get dwPaperOpenRanksTomorrow =>
      'Tonight\'s paper is open. Ranks show here tomorrow.';

  @override
  String dwLateClosedUnrankedAt(String t) {
    return 'Late join closed · unranked at $t';
  }

  @override
  String dwWarriorsThatNight(String n) {
    return '$n warriors that night';
  }

  @override
  String dwAirLabel(int air) {
    return 'AIR $air';
  }

  @override
  String dwBetterThan(String pct) {
    return 'Better than $pct%';
  }

  @override
  String dwPts(String score) {
    return '$score pts';
  }

  @override
  String dwTopNOf(int n, int count) {
    return 'Top $n of $count';
  }

  @override
  String dwSeeAllCount(int count) {
    return 'See all $count';
  }

  @override
  String get dwSavedOnDevice => 'Saved on this device';

  @override
  String get dwPaperNotPublished => 'Paper not published yet';

  @override
  String get dwStartDayTest => 'Start this day\'s test';

  @override
  String get dwReviseThisPaper => 'Revise this paper';

  @override
  String get dwLeaderboardCaps => 'LEADERBOARD';

  @override
  String get dwArchiveTitle => 'Static War archive';

  @override
  String get dwYourAttemptCaps => 'YOUR ATTEMPT';

  @override
  String get dwNotAttempted => 'Not attempted';

  @override
  String get dwStartAboveToTake => 'Start the test above to take this paper.';

  @override
  String get dwPendingRank => 'Pending rank';

  @override
  String get dwSkip => 'Skip';

  @override
  String get dwNoRankedFinishers => 'No ranked finishers yet';

  @override
  String get dwRanksLandAfter =>
      'Ranks land after the paper closes · All-India board fills here';

  @override
  String get dwLeaderboardTitle => 'Leaderboard';

  @override
  String get ocPleaseNote => 'Please note:';

  @override
  String ocTooltipLine(String eta) {
    return 'One live challenge per 24h · next slot ~$eta';
  }

  @override
  String ocBodyCopy(String eta) {
    return 'You already have a live challenge. Next create in ~$eta.';
  }

  @override
  String ocPickCopy(String eta) {
    return 'Still on cooldown — next create in ~$eta.';
  }

  @override
  String qotdSubjectsFailed(String error) {
    return 'Could not load subjects: $error';
  }

  @override
  String ocPickSubtitle(int n) {
    return 'Pick one subject or mixed misc · 10 MCQs · Timed ($n min)';
  }

  @override
  String get ocAlreadyAttempted => 'You have already attempted this challenge.';

  @override
  String get ocExpired => 'This challenge has expired.';

  @override
  String get ocSignInSave => 'Sign in to save your score to the leaderboard.';

  @override
  String get ocSaveFailed => 'Could not save your score';

  @override
  String get commonCheckConnection => 'Check your connection and try again.';

  @override
  String get ocPublishingScore => 'Publishing your score';

  @override
  String get ocLocking =>
      'Locking your answers onto the leaderboard — almost there.';

  @override
  String get ocRule1 =>
      'You will answer 10 questions in exam mode — no hints, no explanations.';

  @override
  String get ocRule2 => 'Your score is posted publicly with your name.';

  @override
  String get ocRule3 => 'You can only attempt each challenge once.';

  @override
  String get ocRule4 => 'Ties are broken by who attempted earlier.';

  @override
  String get ocBeforeStart => 'Before you start';

  @override
  String get ocConfidenceNote =>
      'While selecting an option, marking confidence level is optional, but we recommend it for better insights.';

  @override
  String get ocAMoment => 'a moment';

  @override
  String get qotdNoQuestions => 'No questions found for this subject.';

  @override
  String get qotdLoadFailed => 'Could not load that question.';

  @override
  String get qotdPickFirst => 'Pick a subject first.';

  @override
  String get ocPickSubject => 'Pick your subject';

  @override
  String get qotdIntro =>
      'One random question from your bank · shuffle, attempt, then post to Community QOTD.';

  @override
  String get commonSubject => 'Subject';

  @override
  String get qotdContinue => 'Continue to question';

  @override
  String get qotdNoneLoaded => 'No question loaded.';

  @override
  String get qotdShuffle => 'Shuffle question';

  @override
  String get qotdReadExpl => 'Read explanation';

  @override
  String get qotdPostThis => 'Post this question';

  @override
  String get qotdTabIntro =>
      'Share a tough question with the Community. Tap a card to expand, react, and attempt.';

  @override
  String get qotdFeedFailed => 'Could not load QOTD feed';

  @override
  String get qotdEmpty =>
      'No questions shared yet. Pull to refresh, or tap Create to post one (for example after you attempt a question in a test).';

  @override
  String get ocCreateChallenge => 'Create challenge';

  @override
  String get ocPickNote =>
      'Ten questions are chosen at random from your local bank for this subject. Timer runs during the challenge.';

  @override
  String get ocSubjectsFailed => 'Could not load subjects';

  @override
  String get ocStartMyAttempt => 'Start my challenge attempt';

  @override
  String get ocBeginTimed => 'Begin the timed 10-MCQ challenge';

  @override
  String get commonJustNow => 'just now ✨';

  @override
  String commonMinAgo(int n) {
    return '${n}m ago';
  }

  @override
  String commonHrAgo(int n) {
    return '${n}h ago';
  }

  @override
  String commonDayAgo(int n) {
    return '${n}d ago';
  }

  @override
  String commonWeekAgo(int n) {
    return '${n}w ago';
  }

  @override
  String blockedUnblocked(String name) {
    return '$name has been unblocked.';
  }

  @override
  String blockedUnblockFailed(String error) {
    return 'Could not unblock: $error';
  }

  @override
  String connectChallengeUser(String target) {
    return 'Challenge $target in a battle.';
  }

  @override
  String ocCreatedBy(String name) {
    return 'Created by $name';
  }

  @override
  String ocLiveTill(String t) {
    return 'Live till $t';
  }

  @override
  String ocYourScore(int s) {
    return 'Your score: $s / 10';
  }

  @override
  String ocBeatenBy(String name) {
    return '$name has beaten your score';
  }

  @override
  String ocCreatedMin(int n) {
    return 'Created ${n}m ago';
  }

  @override
  String ocCreatedHr(int n) {
    return 'Created ${n}h ago';
  }

  @override
  String ocCreatedDay(int n) {
    return 'Created ${n}d ago';
  }

  @override
  String commLastRefreshed(String t) {
    return 'Last refreshed: $t';
  }

  @override
  String commKeepProfile(String app) {
    return 'Keep your profile updated so others can connect with you even outside $app.';
  }

  @override
  String qotdMinChars(int n) {
    return 'Write at least $n characters, or leave this blank.';
  }

  @override
  String qotdMaxChars(int n) {
    return 'Please keep it under $n characters.';
  }

  @override
  String qotdMoreChars(int n, int need) {
    return '$n more characters to reach $need, or clear the field to post without a comment.';
  }

  @override
  String ocGreatScore(int n) {
    return 'Great score ($n/10). Post this set as an open challenge so others can try the same questions in Community.';
  }

  @override
  String ocByName(String name) {
    return 'by $name';
  }

  @override
  String ocTries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries',
      one: '1 try',
    );
    return '$_temp0';
  }

  @override
  String ocYouScore(int n) {
    return 'You $n/10';
  }

  @override
  String commBlockedMsg(String name) {
    return 'You will not see messages or battle invites from $name.';
  }

  @override
  String commBlockUpdateFailed(String error) {
    return 'Could not update block: $error';
  }

  @override
  String commChatStartFailed(String error) {
    return 'Could not start chat: $error';
  }

  @override
  String commLastOnline(String t) {
    return 'Last online: $t';
  }

  @override
  String get blockedNone => 'No one blocked';

  @override
  String get blockedNote =>
      'People you block won’t be able to message you or send battle invites.';

  @override
  String get blockedUnblock => 'Unblock';

  @override
  String get connectRandomIntro => 'Start a random battle connect.';

  @override
  String get connectStartChallenge => 'Start Challenge';

  @override
  String get connectNote =>
      'You will briefly see joined players, then battle auto-starts.';

  @override
  String get ocNotFound => 'Challenge not found';

  @override
  String get ocExpired24 =>
      'This challenge has expired (challenges last 24 hours).';

  @override
  String get ocWinnerSoFar => 'You are the winner so far 🏆';

  @override
  String get ocReviewExpl => 'Review explanations';

  @override
  String get ocAccept => 'Accept Challenge';

  @override
  String get ocCreatedJustNow => 'Created just now';

  @override
  String get commRecentFailed => 'Could not load recent users';

  @override
  String get commTapUser => 'Tap a user to view profile and social links.';

  @override
  String get commNoUsers => 'No users found in the latest window.';

  @override
  String get commPullRefresh => 'Pull down to refresh.';

  @override
  String get commLoadingRecent => 'Loading recent users…';

  @override
  String get commSetVisibility => 'Set Visibility';

  @override
  String get commAcceptInvites => 'Accept battle invites';

  @override
  String get commReceivingInvites => 'You are receiving battle invites.';

  @override
  String get commNotReceivingInvites => 'You are not receiving battle invites.';

  @override
  String get commShowBattleStatus => 'Show my in-battle status';

  @override
  String get commOthersCanSee => 'Others can see when you are in a battle.';

  @override
  String get commOthersCannotSee => 'Others cannot see your in-battle status.';

  @override
  String get commSaveFailed => 'Failed to save settings';

  @override
  String get commonSave => 'Save';

  @override
  String get commTapRandom => 'Tap below for Random Battle Connect';

  @override
  String get qotdNoteIntro =>
      'Optional note for the community. You learned something new? Spotted something ironic? A concept felt challenged? Be specific — or leave this blank.';

  @override
  String get qotdCommentLabel => 'Comment (optional)';

  @override
  String get qotdCommentHint => 'Leave blank, or write at least 50 characters…';

  @override
  String get qotdSignInKept => 'Sign in to post. Your comment is kept.';

  @override
  String get qotdPost => 'Post';

  @override
  String get qotdSignInPost => 'Sign in to post';

  @override
  String get ocShareChallenge => 'Share the challenge';

  @override
  String get ocPublishCommunity => 'Publish to Community';

  @override
  String get ocTempUnavailable => 'Temporarily unavailable';

  @override
  String get ocPosting => 'Posting…';

  @override
  String get ocPostAsChallenge => 'Post as open challenge';

  @override
  String get qotdRule1 =>
      'Each QOTD stays in Community for 24 hours from when you post it.';

  @override
  String get qotdRule2 =>
      'One random MCQ is drawn from your offline catalog for the subject you pick.';

  @override
  String get qotdRule3 =>
      'Shuffle until you find a question worth sharing, then attempt it.';

  @override
  String get qotdRule4 =>
      'You post after attempting; your pick is stored with the community post.';

  @override
  String get qotdRule5 =>
      'Your name and an optional short comment appear on the QOTD card.';

  @override
  String get qotdBeforeProceed => 'Before you proceed';

  @override
  String get qotdWhoAnswered => 'Who answered';

  @override
  String get qotdAttemptsFailed => 'Could not load attempts.';

  @override
  String get qotdNoAttempts => 'No attempts yet.';

  @override
  String get qotdProfileUnavailable =>
      'Profile is not available for this attempt yet.';

  @override
  String get qotdWhatIs => 'What is QOTD?';

  @override
  String get qotdWhat1 => 'Share a question from your test with the community.';

  @override
  String get qotdWhat2 => 'Others attempt it and react.';

  @override
  String get qotdWhat3 => 'It stays live for 24 hours.';

  @override
  String get ocPublishingChallenge => 'Publishing your challenge…';

  @override
  String get ocStepFailed =>
      'Could not complete this step. Check your connection and try again.';

  @override
  String get ocWhatIs => 'What is an open challenge?';

  @override
  String get ocWhat1 =>
      'A warrior posts their 10-question exam for everyone to try.';

  @override
  String get ocWhat2 => 'Same 10 questions for every challenger.';

  @override
  String get ocWhat3 => 'Beat the top score on the leaderboard.';

  @override
  String get ocWhat4 => 'Each challenge stays live for 24 hours.';

  @override
  String get ocWhatSignIn => 'Sign in to join a challenge and post your own.';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get qotdPosted => 'Posted to Community QOTD';

  @override
  String get ocSectionIntro =>
      'Same 10 questions — beat the room! Tap a card for the full story.';

  @override
  String get ocStartNew => 'Start a new 10-question challenge';

  @override
  String get ocLoadFailed => 'Could not load challenges';

  @override
  String get ocNoneYet => 'No challenges yet — you could be first!';

  @override
  String get ocCrushIntro =>
      'Crush a 10Q exam, then hit Create to drop a challenge for everyone.';

  @override
  String get ocWhatIsShort => 'What is open challenge';

  @override
  String get ocPickedForYou => 'Picked for you';

  @override
  String get commLinkFailed => 'Could not open link';

  @override
  String get commFighting => 'fighting a battle';

  @override
  String get commAvailable => 'available';

  @override
  String get commBlockTitle => 'Block this user?';

  @override
  String get commBlockBody => 'This will close this chat and block them.';

  @override
  String get commSignInMsg => 'Sign in to send messages.';

  @override
  String get commChatStartSignIn =>
      'Could not start chat. Please sign in again.';

  @override
  String get commSendMessage => 'Send Message';

  @override
  String get commThatsAll => 'That\'s all';

  @override
  String bcSubInvite(String name, int mins) {
    return 'Battle vs $name · 10 MCQs · Timed ($mins min)';
  }

  @override
  String bcSubPick(int mins) {
    return 'Pick one subject or mixed misc · 10 MCQs · Timed ($mins min)';
  }

  @override
  String bcErrSetup(String code) {
    return 'Battle setup failed ($code).';
  }

  @override
  String bwJoinWindow(String window, String remaining) {
    return 'If your opponent joins within $window, \nyou can start the battle. Time remaining: $remaining.';
  }

  @override
  String bsoSubmitted(String name) {
    return '$name has submitted; unanswered questions stay blank.';
  }

  @override
  String bsoLockedAll(String name) {
    return '$name has locked in every answer.';
  }

  @override
  String bsoStillWorking(String name) {
    return '$name is still working through the paper.';
  }

  @override
  String bsoCloseBody(String name) {
    return '$name is still answering. Stop the live duel anyway?';
  }

  @override
  String bsoLeaveBody(String name) {
    return '$name is still answering. Do you want to stop watching?';
  }

  @override
  String get bjSignIn => 'Sign in to join this battle.';

  @override
  String get bjNotFound => 'This battle was not found. It may have expired.';

  @override
  String get bjNotPvp => 'This link is not for a player-vs-player battle.';

  @override
  String get bjWrongAccount => 'This invite was sent to a different account.';

  @override
  String get bjClosed =>
      'This battle is no longer accepting joins. It may have already started.';

  @override
  String get bjIncomplete => 'Battle data is incomplete.';

  @override
  String get bjJoinFailed => 'Could not join battle.';

  @override
  String get bjTitle => 'Join battle';

  @override
  String get bjSomethingWrong => 'Something went wrong.';

  @override
  String get commonHome => 'Home';

  @override
  String get brTitle => 'Battle Result';

  @override
  String get commonBackToHome => 'Back to Home';

  @override
  String get bcTitle => 'Configure battle';

  @override
  String get bcPick => 'Pick your battlefield';

  @override
  String get bcMisc => 'Misc';

  @override
  String get bcTimerNote =>
      'Timer runs during the battle. Answers lock in once chosen, with explanations shown so you learn as you go.';

  @override
  String get bcLoadFailed => 'Could not load subjects';

  @override
  String get bcUnblockFirst =>
      'Unblock this player in Community before inviting them.';

  @override
  String get bcErrPermission =>
      'Could not save the battle room. Sign in and try again, or check Firestore rules.';

  @override
  String get bcErrUnavailable =>
      'Firestore is temporarily unavailable. Check your connection and try again.';

  @override
  String get bcErrTimeout =>
      'Saving the battle timed out. Check your internet connection and try again.';

  @override
  String get bwLeaveTitle => 'Leave match?';

  @override
  String get bwLeaveBody => 'Your opponent may still be waiting in the lobby.';

  @override
  String get bwStay => 'Stay';

  @override
  String get bwStartFailed => 'Could not start battle. Try again.';

  @override
  String get bwMatch => 'Match';

  @override
  String get bwBattleId => 'Battle ID';

  @override
  String get bw2Joined => '2 joined';

  @override
  String get commonYou => 'You';

  @override
  String get bwStartingSoon =>
      'Please wait… battle is starting in a few seconds.';

  @override
  String get bwOppJoined =>
      'Opponent joined. Start the battle when you are ready.';

  @override
  String get bwWaitOppJoin =>
      'Waiting for your opponent to open the invite and join.';

  @override
  String get bwStarting => 'Starting battle…';

  @override
  String get bwWaitHost => 'Waiting for the host to start the battle.';

  @override
  String get bwOppInLobby => 'Opponent in lobby';

  @override
  String get bwWaitOpp => 'Waiting for opponent';

  @override
  String get bwTimedOut =>
      'We timed out while waiting for your opponent to join. You can keep waiting in case they are slow, or go back.';

  @override
  String get commonGoBack => 'Go back';

  @override
  String get bwKeepWaiting => 'Keep waiting';

  @override
  String get bshScores => 'Scores';

  @override
  String get bshFinished => 'Battle finished';

  @override
  String get bsnTitle => 'Submit your answers?';

  @override
  String get bsnBodyWatch =>
      'Your score will lock in. You can watch your opponent finish on a live board, or go straight to results.';

  @override
  String get bsnBodyPlain =>
      'Your score will lock in and you will see the outcome.';

  @override
  String get bsnContinue => 'Continue battle';

  @override
  String get bsnWatch => 'Submit and Watch their progress';

  @override
  String get bsnSeeResults => 'Submit & see results';

  @override
  String get bsoYourOpp => 'Your opponent';

  @override
  String get bsoTie => 'Tie on points.';

  @override
  String get bsoYouAhead => 'You were ahead on points.';

  @override
  String get bsoOppAhead => 'Your opponent was ahead on points.';

  @override
  String get bsoYouAheadNow => 'You are ahead on points (for now).';

  @override
  String get bsoOppAheadNow => 'Your opponent is ahead on points (for now).';

  @override
  String get bsoClose => 'Scores are very close.';

  @override
  String get bsoTimerEnded =>
      'The timer window ended; the room will not add more live marks.';

  @override
  String get bsoCloseTitle => 'Close live duel?';

  @override
  String get bsoStop => 'Stop';

  @override
  String get bsoLeaveTitle => 'Leave the live board?';

  @override
  String get bsoKeepWatching => 'Keep watching';

  @override
  String get bsoBattleOver => 'Battle over';

  @override
  String get bsoLiveDuel => 'Live duel';

  @override
  String get bsoStopFollowing => 'Stop following';

  @override
  String get bsoClosePanel => 'Close panel';

  @override
  String bcfSendFailed(String error) {
    return 'Failed to send: $error';
  }

  @override
  String bcfLoadFailed(String error) {
    return 'Could not load messages: $error';
  }

  @override
  String bsbAcc(int pct, int correct, int wrong) {
    return '$pct% accuracy · $correct correct, $wrong wrong';
  }

  @override
  String bsbAccUn(int pct, int correct, int wrong, int un) {
    return '$pct% accuracy · $correct correct, $wrong wrong, $un unanswered';
  }

  @override
  String bsbAheadBy(String delta) {
    return 'You were ahead by $delta points';
  }

  @override
  String bsbLedBy(String delta) {
    return 'They led by $delta points';
  }

  @override
  String get btOpenFailed => 'Could not open battle.';

  @override
  String get btLeaveTitle => 'Leave battle?';

  @override
  String get btLeaveBody =>
      'Going back means you want to quit the battle, but your progress will be saved.';

  @override
  String get btGridTooltip => 'Question grid';

  @override
  String get btWaitJoin =>
      'Waiting for your opponent to join before you can answer.';

  @override
  String get btRevisit => 'Revisit';

  @override
  String get btSubmitFailed => 'Could not submit battle. Please retry.';

  @override
  String get btGridTitle => 'Question Grid';

  @override
  String get btAnswer => 'Answer';

  @override
  String get bcfCloseTitle => 'Close chat?';

  @override
  String get bcfCloseBody => 'Are you sure you want to hide this battle chat?';

  @override
  String get commonClose => 'Close';

  @override
  String get bcfStartConv => 'Start the conversation.';

  @override
  String get bcfHint => 'Type a message';

  @override
  String get commonOpponent => 'Opponent';

  @override
  String get bsbNoAttempts => 'no scored attempts';

  @override
  String get bsbYouCaps => 'YOU';

  @override
  String get bsbTieTitle => 'Neck and neck!';

  @override
  String get bsbTieSub => 'It is a tie. That was intense.';

  @override
  String get bsbLoseTitle => 'So close!';

  @override
  String get bsbLoseSub => 'You lost this one. Come back stronger.';

  @override
  String get bsbTiedPoints => 'Scores are tied on points.';

  @override
  String get bsbVictory => 'Victory unlocked!';

  @override
  String get bsbOutplayed => 'You outplayed your opponent this round.';

  @override
  String get bsbStacked => 'How you stacked up';

  @override
  String get bsbTiePts => 'Tie on points';

  @override
  String get bspWaitJoin => 'Waiting for your opponent to join…';

  @override
  String get bspRecordFailed => 'Could not record your answer.';

  @override
  String get bspSubmitFailed => 'Could not submit battle.';

  @override
  String get bspPermDenied => 'Battle permission denied by Firestore rules.';

  @override
  String get bspNetwork =>
      'Network unavailable. Please check internet and retry.';

  @override
  String get bspStartFailed => 'Could not start online battle. Please retry.';

  @override
  String get bicSent => 'Battle invite sent.';

  @override
  String get bicNoToken =>
      'Invitee has no push token yet. They can still join using the session link.';

  @override
  String get bicPushFailed =>
      'Push could not be sent. They can still join using the session link.';

  @override
  String get bicUnclear =>
      'Invite status unclear. Check Firebase Functions logs.';

  @override
  String gmSetTitle(String subject, int n, int total) {
    return '$subject · Set $n/$total';
  }

  @override
  String gmCorrectOfTotal(int correct, int total) {
    return '$correct of $total correct';
  }

  @override
  String gmOddTitle(String subject) {
    return 'Odd One Out · $subject';
  }

  @override
  String gmNOfTotal(int n, int total) {
    return '$n of $total';
  }

  @override
  String gmFobStep2(int seconds) {
    return 'You have $seconds seconds on the clock.';
  }

  @override
  String gmSubjNOfTotal(String subject, int n, int total) {
    return '$subject · $n of $total';
  }

  @override
  String gmDuelYouWin(String name) {
    return 'You win, $name';
  }

  @override
  String gmDuelWins(String name) {
    return '$name wins';
  }

  @override
  String get gmDescMemory => 'Match terms to answers — train recall.';

  @override
  String get gmDescTimeline => 'Put events in the right order.';

  @override
  String get gmOddStep2 => 'Pick the odd one out.';

  @override
  String get gmDescFob => 'Ten seconds. Trust your gut.';

  @override
  String get gmDescCtd => 'Find the hidden link.';

  @override
  String get gmDescDuel => 'One phone, two players, fastest wins.';

  @override
  String gmStartN(int n) {
    return 'Start · $n questions';
  }

  @override
  String get gmTlStep1 => 'Read the shuffled events for the set.';

  @override
  String get gmTlStep2 => 'Hold and drag rows to place them in order.';

  @override
  String get gmTlStep3 => 'Tap Check to reveal years and what you got right.';

  @override
  String get gmNextSet => 'Next set →';

  @override
  String get gmCheck => 'Check';

  @override
  String get gmNoContent => 'No content';

  @override
  String get gmTlHint => 'Hold and drag to reorder, then check.';

  @override
  String get gmErrNoTimeline => 'No timeline sets found.';

  @override
  String get gmOddStep1 => 'Look at all four options.';

  @override
  String get gmOddStep3 => 'See the highlight and explanation instantly.';

  @override
  String get gmNext => 'Next →';

  @override
  String get gmErrNoOdd => 'No odd-one-out items found.';

  @override
  String get gmFobStep1 => 'Read the statement fast.';

  @override
  String get gmFobStep3 => 'Tap FACT or BLUFF before time runs out.';

  @override
  String get gmGotIt => 'You got it';

  @override
  String get gmNotThisTime => 'Not this time';

  @override
  String get gmTooSlow => 'Too slow';

  @override
  String get gmErrNoFob => 'No fact-or-bluff items found.';

  @override
  String get gmCtdStep1 => 'Read all three clues together.';

  @override
  String get gmCtdStep2 => 'Think about what links them.';

  @override
  String get gmCtdStep3 => 'Tap the option that ties them together.';

  @override
  String get gmCtdHidden => 'What\'s the hidden link?';

  @override
  String get gmErrNoCtd => 'No connect-the-dots items found.';

  @override
  String get gmDuelStart => 'Start match';

  @override
  String get gmDuelStep1 => 'Lay the phone flat on the table between you.';

  @override
  String get gmDuelStep2 =>
      'Same question, 2 options each — mirrored top and bottom.';

  @override
  String get gmDuelStep3 =>
      'Both pick (or pass) first — correct answer reveals only when both have locked in.';

  @override
  String get gmDuelNoQ => 'No question';

  @override
  String get gmDuelPass => 'Pass';

  @override
  String get gmDuelPassedWait => 'Passed — waiting…';

  @override
  String get gmDuelPassed => 'Passed';

  @override
  String get gmDuelPoint => 'Point!';

  @override
  String get gmDuelEven => 'Evenly matched';

  @override
  String get gmDuelExit => 'Exit';

  @override
  String get gmDuelRematch => 'Rematch';

  @override
  String get gmErrNoDuel => 'No duel questions found.';

  @override
  String get gmSessionComplete => 'Session complete';

  @override
  String get gmSolid => 'Solid recall.';

  @override
  String get gmAnotherPass => 'Worth another pass.';

  @override
  String get gmPlayAgain => 'Play again';

  @override
  String get gmBackToGames => 'Back to games';

  @override
  String get gmHowToPlay => 'How to play';

  @override
  String get gmDontShow => 'Don\'t show again';

  @override
  String get gmHomeSubtitle =>
      'Recall, timeline, fact-or-bluff — train the UPSC way';

  @override
  String get gmConfig => 'Config';

  @override
  String get gmSetup => 'Set up your session';

  @override
  String get gmLanguage => 'Language';

  @override
  String get gmSubjects => 'Subjects';

  @override
  String get gmAll => 'All';

  @override
  String get gmStart => 'Start';

  @override
  String mpPairsCount(int n) {
    return '$n pairs';
  }

  @override
  String mpUnlock(int n, String subject) {
    return 'To unlock, attempt $n $subject questions';
  }

  @override
  String mpUnlockDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String mpDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String mpWkAgo(int n) {
    return '$n wk ago';
  }

  @override
  String mpMoAgo(int n) {
    return '$n mo ago';
  }

  @override
  String mpMatched(int done, int total) {
    return '$done/$total matched';
  }

  @override
  String mpTimeErrors(String time, int n) {
    return '$time · $n errors';
  }

  @override
  String mpStarsVerdict(int stars, String verdict) {
    return '$stars / 5 · $verdict';
  }

  @override
  String mpWrongPairs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pairs you got wrong',
      one: '1 pair you got wrong',
    );
    return '$_temp0';
  }

  @override
  String mpTopics(int n) {
    return '$n topics';
  }

  @override
  String mpQuickDrill(int n) {
    return 'Quick $n-pair recall drill — tap Start when you are ready.';
  }

  @override
  String get mpPlayNow => 'Play now';

  @override
  String get mpCards => 'Cards';

  @override
  String get mpList => 'List';

  @override
  String get mpTapRow => 'Tap a row to reveal its answer';

  @override
  String get mpNeverPlayed => 'Never played';

  @override
  String get mpToday => 'Today';

  @override
  String get mpYesterday => 'Yesterday';

  @override
  String get mpPairsInRound => 'Pairs in round';

  @override
  String get mpBestTime => 'Best time';

  @override
  String get mpLastPlayed => 'Last played';

  @override
  String get mpRevise => 'Revise';

  @override
  String get mpErrors => 'Errors';

  @override
  String get mpProgress => 'Progress';

  @override
  String get mpTerms => 'Terms';

  @override
  String get mpAnswers => 'Answers';

  @override
  String get mpAllMatched => 'All pairs matched';

  @override
  String get mpPaused => 'Paused';

  @override
  String get mpResume => 'Resume';

  @override
  String get mpQuitToSet => 'Quit to set';

  @override
  String get mpComplete => 'Complete';

  @override
  String get mpTime => 'Time';

  @override
  String get mpTotalTime => 'Total time';

  @override
  String get mpTotalErrors => 'Total errors';

  @override
  String get mpPairsCleared => 'Pairs cleared';

  @override
  String get mpNewBest => 'New best time for this set';

  @override
  String get mpFullRecall => 'No wrong taps — full recall';

  @override
  String get mpTryAnother => 'Try another set';

  @override
  String get mpBackToSets => 'Back to sets';

  @override
  String get mpV5 => 'Razor sharp';

  @override
  String get mpV4 => 'Strong recall';

  @override
  String get mpV3 => 'Solid, can be faster';

  @override
  String get mpV2 => 'Recall is slow';

  @override
  String get mpV1 => 'Needs heavy revision';

  @override
  String get mpTagline => 'Learn. Recall. Master.';

  @override
  String get mpBrowse => 'Browse by Subject';

  @override
  String get mpHowItWorksQ => 'How it works?';

  @override
  String get mpGroupedNote =>
      'Topics are grouped by difficulty. Earn stars as you master harder topics!';

  @override
  String get mpTerm => 'Term';

  @override
  String get mpTapTerm => 'Tap to see term';

  @override
  String get mpTapFlip => 'Tap to flip · swipe any direction for next';

  @override
  String get mpPlay => 'Play';

  @override
  String get mpHowItWorks => 'How it works';

  @override
  String get mpTrain => 'Train recall in under a minute';

  @override
  String get mpStep1T => 'Pick a subject';

  @override
  String get mpStep1B => 'Browse Polity, History, Geography, and more.';

  @override
  String get mpStep2T => 'Choose a topic';

  @override
  String get mpStep2B => 'Each set has a difficulty tag — easy to hard.';

  @override
  String get mpStep3T => 'Match the pairs';

  @override
  String get mpStep3B =>
      'Tap a term, then its answer. Beat your best time and earn stars.';

  @override
  String get mpGotIt => 'Got it';

  @override
  String get mpOpenFailed => 'Could not open game';

  @override
  String get mpGoHome => 'Go home';

  @override
  String get mpRevisionGame => 'Revision Game';

  @override
  String get mpBrowseAll => 'Browse all sets';

  @override
  String get mpSetDetail => 'Set detail';

  @override
  String get mpSummary => 'Summary';

  @override
  String get chatNotSignedIn =>
      'You are not signed in. Please sign in and try again.';

  @override
  String get chatBlockedSend =>
      'You have blocked this person. Unblock them in Settings to send messages.';

  @override
  String chatSendFailed(String error) {
    return 'Message failed to send: $error';
  }

  @override
  String cpUpdateFailed(String error) {
    return 'Could not update profile: $error';
  }

  @override
  String cpPrivacy(String app) {
    return 'Privacy note: Apple may not share your real email/name on future sign-ins. We store this name only to show it inside $app.';
  }

  @override
  String fpCanYou(String line) {
    return '$line. Can you?';
  }

  @override
  String fpPhoto(String name) {
    return 'Photo: $name';
  }

  @override
  String fpSource(String name) {
    return 'Source: $name';
  }

  @override
  String fpMetaLine(String date, int n) {
    return '$date  ·  $n min read  ·  High Relevance';
  }

  @override
  String fpBreakdown(int a, int c, int w) {
    return '$a attempted · $c got it right · $w got it wrong';
  }

  @override
  String fpTrap(int a, int p) {
    return '$a attempted · $p% fell for it';
  }

  @override
  String get chatListTitle => 'Chats';

  @override
  String get chatNone => 'No chats yet';

  @override
  String get chatStartConv => 'Start the conversation';

  @override
  String get chatStartFailed => 'Could not start chat. Go back and try again.';

  @override
  String get chatSignInAgain => 'Sign in again to send messages.';

  @override
  String get chatBlockedHidden =>
      'You have blocked this person. Their messages are hidden. Unblock them in Settings to chat.';

  @override
  String get chatOpenLink => 'Could not open link';

  @override
  String get cpPhotoUpdated => 'Photo updated';

  @override
  String get cpNameNotAllowed => 'UPSC War is not allowed in name';

  @override
  String get cpEnterName => 'Please enter your name';

  @override
  String get cpProfileUpdated => 'Profile updated';

  @override
  String get cpTitle => 'Complete your profile';

  @override
  String get cpSignInContinue => 'Sign in to continue';

  @override
  String get cpConnect =>
      'Connect your account to sync your profile and progress across devices.';

  @override
  String get cpSigningIn => 'Signing in…';

  @override
  String get cpSignIn => 'Sign in';

  @override
  String get cpHelps =>
      'This helps others recognize you in Community and chat.';

  @override
  String get cpPhotoWeb =>
      'Profile photo can be changed in the Android or iOS app.';

  @override
  String get cpYourName => 'Your name';

  @override
  String get cpNameHint => 'e.g. Sachin';

  @override
  String get cpSaving => 'Saving…';

  @override
  String get cpPhotoAnytime =>
      'You can change your photo anytime from Profile.';

  @override
  String get ddOpenFailed => 'Could not open revision queue';

  @override
  String get fpWhatsThis => 'What\'s this?';

  @override
  String get fpNone =>
      'No CA Shots yet. Breaking CA briefings will show up here.';

  @override
  String get fpWhatAre => 'What are CA Shots?';

  @override
  String get fpWhatBody =>
      'Think of these as short daily drills — shots you can take every day to prepare for your final battle.';

  @override
  String get fpAlertsT => 'Frequent alerts';

  @override
  String get fpAlertsB =>
      'You get notified when a UPSC-relevant article is worth your attention.';

  @override
  String get fpMcqT => 'One focused MCQ';

  @override
  String get fpMcqB =>
      'Each shot gives one concept-based MCQ from that article, with explanation.';

  @override
  String get fpReadyT => 'Battle readiness';

  @override
  String get fpReadyB =>
      'Take these shots daily so your concepts stay sharp for the final battle.';

  @override
  String get fpNotDone => 'Not done';

  @override
  String get fpDoneCorrect => 'Done · Correct';

  @override
  String get fpDoneWrong => 'Done · Wrong';

  @override
  String get fpUndated => 'Undated';

  @override
  String get fpReadSource => 'Read source';

  @override
  String get fpShare => 'Share';

  @override
  String get fpLoadFailed => 'Could not load this CA Shot.';

  @override
  String get fpCheckNet => 'Check your internet connection and try again.';

  @override
  String get fpNewsSummary => 'News Summary';

  @override
  String get fpShowLess => 'Show less';

  @override
  String get fpReadMore => 'Read more';

  @override
  String get fpWhyRelevant => 'Why is this relevant for UPSC?';

  @override
  String get fpReviewAttempt => 'Review your MCQ Attempt';

  @override
  String get fpAttemptMcq => 'Attempt the MCQ';

  @override
  String get fpExpired => 'This CA Shot has expired.';

  @override
  String get fpAttempt => 'Attempt';

  @override
  String get fpPickSee => 'Pick an option to see answer and explanation.';

  @override
  String get fpCorrectBang => 'Correct!';

  @override
  String get fpBackToShot => 'Back to CA Shot';

  @override
  String get fpHomeSub => 'Breaking news brief + 1 MCQ based on it.';

  @override
  String get fpAnswerThis => 'Answer this Pulse';

  @override
  String get fpPickSubmit => 'Pick an option to submit your answer.';

  @override
  String get fpNoAttempts => 'No attempts yet';

  @override
  String get fpBeFirst => 'Be the first to attempt this.';

  @override
  String tcOnlyAvail(String n) {
    return 'Only $n available';
  }

  @override
  String tcMinutesTotal(int n) {
    return '$n minutes total';
  }

  @override
  String get tcCoach1T => 'Pick question count';

  @override
  String get tcCoach1B =>
      'Choose how many questions you want in this session — 10 for a quick drill, 25 for a full practice block.';

  @override
  String get tcCoach2T => 'Choose a mode';

  @override
  String get tcCoach2B =>
      'Exam hides all explanations until the test ends — just like the real paper. Learning shows the answer and explanation right after each question.';

  @override
  String tcCoach3B(int n) {
    return 'Each question gets ${n}s. Toggle this off if you prefer practising without the clock.';
  }

  @override
  String glTitle(String app) {
    return 'Sign in to $app';
  }

  @override
  String pcDays(int n) {
    return 'Prelims: $n days';
  }

  @override
  String get pdLead => 'You’re missing updates and reminders. Please enable ';

  @override
  String get pdLink => 'notifications';

  @override
  String get pdTrail => '.';

  @override
  String get tcWentWrong => 'Something went wrong. Please try again.';

  @override
  String get tcConfOff => 'Confidence rating is off';

  @override
  String get tcConfOffBody =>
      'Turn it on to track how sure you were before reveal and unlock Danger Zone insights.';

  @override
  String get tcExamDesc =>
      'Simulate real conditions. Explanation after test ends.';

  @override
  String get tcLearnDesc => 'See explanation after each question.';

  @override
  String get tcNoQuestions => 'No questions available for this topic.';

  @override
  String get tcTimePerQ => 'Time per question';

  @override
  String get tcNoLimit => 'No limit';

  @override
  String get tcStartExam => 'Start exam';

  @override
  String get tcStartLearning => 'Start learning session';

  @override
  String get tcNoTimeLimit => 'No time limit';

  @override
  String get tcTakeTime => 'Take as long as you need on each question.';

  @override
  String get tcExamNote =>
      'Exam mode is a timed test with explanations after it ends.';

  @override
  String get tcLearnNote =>
      'No clock running — ideal for deep reading and revision.';

  @override
  String get glBody =>
      'Save your progress, sync stats across devices, and keep your streak safe.';

  @override
  String get glSigningIn => 'Signing in...';

  @override
  String get glApple => 'Continue with Apple';

  @override
  String get glGoogle => 'Continue with Google';

  @override
  String get glAgree =>
      'By continuing, you agree to our Privacy Policy and to authenticate with Apple or Google via Firebase.';

  @override
  String get glReadPolicy => 'Read full privacy policy';

  @override
  String get cuGetInTouch => 'Get in touch';

  @override
  String get cuBody =>
      'If something is unclear, you have a feature idea, or any feedback — pick what works best for you.';

  @override
  String get cuTgDirect => 'Telegram (direct message)';

  @override
  String get cuTgDirectSub => 'Quick questions & updates';

  @override
  String get cuTgGroup => 'Telegram group';

  @override
  String get cuTgGroupSub => 'Community & discussion';

  @override
  String get cuOpenFailed => 'Could not open link.';

  @override
  String get cuRate => 'Rate / review';

  @override
  String get rrTitle => 'Built by an Aspirant, for Aspirants';

  @override
  String get rrBody1 =>
      'Built by an ex-UPSC aspirant who faced the same struggle of solving endless MCQs without clearly knowing where marks were being lost.';

  @override
  String get rrBody2 =>
      'The goal was simple: help aspirants prepare smarter by identifying confident mistakes, danger zones, safe risk areas, and better revision priorities.';

  @override
  String get rrJourney => 'Read About Journey of UPSC Wars';

  @override
  String get rrBody3 =>
      'If UPSC Wars is helping your preparation, your review can help other aspirants find it too.';

  @override
  String get rrRate => '⭐ Rate & Review UPSC Wars';

  @override
  String get qpTitle => 'Choose mode';

  @override
  String get qpSub => 'How would you like to practice?';

  @override
  String get qpTutor => 'Tutor Mode';

  @override
  String get qpTutorDesc => 'See explanations after each question';

  @override
  String get qpExam => 'Exam Mode';

  @override
  String get qpExamDesc => 'Get results at the end';

  @override
  String get pcToday => 'Prelims: today';

  @override
  String get pcOneDay => 'Prelims: 1 day';

  @override
  String get pcTitle => 'UPSC PRELIMS COUNTDOWN';

  @override
  String get pcUnits => 'Days : Hours : Min : Sec';

  @override
  String get pdTitle => 'You’re missing drill, CA & community alerts';

  @override
  String get pdBody =>
      'Turn on notifications for Daily Drill, current affairs, CA Shots, and community invites.';

  @override
  String get pdEnable => 'Enable alerts';

  @override
  String get suStoreFailed => 'Could not open the store.';

  @override
  String get suAvailable => 'Update available';

  @override
  String get suUpdate => 'Update';

  @override
  String get suLater => 'Later';

  @override
  String get kuTitle => 'Update required';

  @override
  String get kuBody =>
      'This version is no longer supported.\n Kindly Update to keep practicing.';

  @override
  String get kuContinue => 'Update from the store to continue';

  @override
  String get vbDismissQ => 'Dismiss?';

  @override
  String get vbDismissBody =>
      'Are you sure? You will not be reminded of this again.';

  @override
  String get commonYes => 'Yes';

  @override
  String get vbDefault => 'We posted a short video that may help.';

  @override
  String get vbWatch => 'Watch video';

  @override
  String get lbSignIn => 'Sign in to see the leaderboard';

  @override
  String get obgOdd => 'Spot the one that doesn’t belong.';

  @override
  String get obgFob => 'Ten seconds on the clock — trust your gut.';

  @override
  String get obgCtd => 'Find the hidden link between clues.';

  @override
  String get obgDuel => 'One phone, two players — fastest wins.';

  @override
  String ecWatchOut(String title) {
    return 'Watch out - $title';
  }

  @override
  String srYou(String opt) {
    return 'You: ($opt)';
  }

  @override
  String srCorrect(String opt) {
    return 'Correct: ($opt)';
  }

  @override
  String srYourAnswer(String opt) {
    return 'Your answer: ($opt)';
  }

  @override
  String stSharedWithYou(String name) {
    return '$name shared this test with you.';
  }

  @override
  String stSubjectTopic(String subject, String topic) {
    return 'Subject: $subject · $topic';
  }

  @override
  String stSubject(String subject) {
    return 'Subject: $subject';
  }

  @override
  String stQuestions(int n) {
    return 'Questions: $n';
  }

  @override
  String get obgTitle => 'Six games. Zero boring revision.';

  @override
  String get obgStart => 'Get started';

  @override
  String get srTitle => 'Session review';

  @override
  String get srBookmark => 'Bookmark';

  @override
  String get srRevisionMode => 'Revision mode';

  @override
  String get stNameHint =>
      'If you don\'t want to give your name, enter any random name';

  @override
  String get stBefore => 'Before you begin';

  @override
  String get stEnterName => 'Enter your display name';

  @override
  String get stTop5 => 'Leaderboard · Top 5';

  @override
  String get stBeFirst => 'Be the first to take this test.';

  @override
  String get stAbout => 'You are about to start a shared practice test.';

  @override
  String get stTitle => 'Shared test';

  @override
  String get stOhSnap => 'Oh snap.';

  @override
  String get stExpired =>
      'This link is unavailable or expired.\nAsk your friend to reshare.';

  @override
  String get stOpening => 'Opening shared test…';

  @override
  String get stPreparing => 'Preparing configuration…';
}
