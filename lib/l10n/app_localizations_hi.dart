// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonRetry => 'फिर कोशिश करें';

  @override
  String get commonDone => 'हो गया';

  @override
  String get commonContinue => 'आगे बढ़ें';

  @override
  String get commonExit => 'बाहर निकलें';

  @override
  String get commonLogOut => 'Log out';

  @override
  String get languagePickerTitle => 'भाषा चुनें';

  @override
  String get languagePickerSubtitle => 'पूरे ऐप और सवालों के लिए एक ही भाषा।';

  @override
  String get languagePickerHintEn => 'ऐप और सवाल, दोनों English में।';

  @override
  String get languagePickerHintHi => 'ऐप और सवाल, दोनों हिन्दी में।';

  @override
  String get languagePickerPracticeTest => 'Practice test';

  @override
  String get readingSizeSmall => 'छोटा';

  @override
  String get readingSizeDefault => 'डिफ़ॉल्ट';

  @override
  String get readingSizeMedium => 'मध्यम';

  @override
  String get readingSizeLarge => 'बड़ा';

  @override
  String get readingSizeExtraLarge => 'बहुत बड़ा';

  @override
  String get routerExitDialogTitle => 'ऐप बंद करें?';

  @override
  String routerExitDialogBody(String appName) {
    return 'आप $appName से बाहर निकल जाएँगे।';
  }

  @override
  String settingsSeriesUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series unlock हैं',
      one: '1 series unlock है',
    );
    return '$_temp0';
  }

  @override
  String settingsBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लोग',
      one: '1 व्यक्ति',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSubtitleEn => 'ऐप और सवाल English में';

  @override
  String get settingsLanguageSubtitleHi => 'ऐप और सवाल हिन्दी में';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsSectionPreferences => 'प्राथमिकताएँ';

  @override
  String get settingsSectionSupport => 'सहायता';

  @override
  String get settingsSendFeedback => 'फीडबैक भेजें';

  @override
  String get settingsTelegramDirect => 'Telegram (डायरेक्ट)';

  @override
  String get settingsTelegramGroup => 'Telegram (ग्रुप)';

  @override
  String get settingsSectionAbout => 'जानकारी';

  @override
  String get settingsAboutUs => 'हमारे बारे में';

  @override
  String get settingsAboutUsSubtitle => 'हम क्या बना रहे हैं, और क्यों';

  @override
  String get settingsRateApp => 'ऐप को रेट करें';

  @override
  String get settingsOpenAppStore => 'App Store खोलें';

  @override
  String get settingsOpenPlayStore => 'Play Store खोलें';

  @override
  String get settingsSectionPrivacy => 'प्राइवेसी';

  @override
  String get settingsSectionAccount => 'अकाउंट';

  @override
  String get settingsFooter =>
      'हर गंभीर aspirant के लिए पूरे ध्यान से बनाया गया।';

  @override
  String get settingsStoreOpenFailed =>
      'स्टोर नहीं खुल सका। बाद में फिर कोशिश करें।';

  @override
  String get settingsHeaderTagline => 'ऐप को अपने हिसाब से सेट करें।';

  @override
  String get settingsNoOneBlocked => 'किसी को ब्लॉक नहीं किया';

  @override
  String get settingsBlockedUsers => 'ब्लॉक किए गए यूज़र';

  @override
  String get settingsLoggingOut => 'Log out हो रहा है...';

  @override
  String get settingsSignOutSubtitle => 'इस डिवाइस से साइन आउट करें';

  @override
  String get settingsLogOutConfirmTitle => 'Log out करें?';

  @override
  String get settingsLogOutConfirmBody =>
      'क्या आप सच में log out करना चाहते हैं?';

  @override
  String get settingsLinkOpenFailed => 'लिंक नहीं खुल सका।';

  @override
  String get settingsLanguageTitle => 'भाषा';

  @override
  String get settingsDarkMode => 'डार्क मोड';

  @override
  String get settingsDarkModeSubtitle =>
      'लंबे समय तक पढ़ने के लिए आरामदायक कंट्रास्ट।';

  @override
  String get settingsReadingSize => 'पढ़ने का साइज़';

  @override
  String get settingsReadingSizeSubtitle => 'सवाल और explanation का टेक्स्ट।';

  @override
  String get settingsReadingSmaller => 'छोटा करें';

  @override
  String get settingsReadingLarger => 'बड़ा करें';

  @override
  String get settingsPreview => 'प्रीव्यू';

  @override
  String get settingsConfidenceTitle => 'जवाब देखने से पहले Confidence';

  @override
  String get settingsConfidenceSubtitle =>
      'जवाब दिखाने से पहले पूछें, “आप कितने sure हैं?”';

  @override
  String get settingsStatusBarReminder => 'Status bar रिमाइंडर';

  @override
  String get settingsAndroidOnly => 'सिर्फ़ Android पर उपलब्ध।';

  @override
  String get settingsStatusBarReminderSubtitle =>
      'Prelims तक बचे दिनों की गिनती दिखती रहे।';

  @override
  String get routerGoHome => 'Home पर जाएँ';

  @override
  String get routerLinkFailedTitle => 'लिंक नहीं खुल सका';

  @override
  String get routerErrorTitle => 'ओह! कुछ गड़बड़ हो गई';

  @override
  String get routerLinkFailedBody =>
      'यह लिंक नहीं खुल सका।\nकृपया फिर से कोशिश करें।';

  @override
  String get routerErrorBody => 'कुछ गड़बड़ हो गई।\nकृपया फिर से कोशिश करें।';

  @override
  String get revisionQueueEmptyLine => 'Queue में अभी कुछ नहीं है';

  @override
  String get commonNone => 'कोई नहीं';

  @override
  String get revisionIncorrectMcqs => 'गलत MCQs';

  @override
  String get revisionBookmarkedMcqs => 'Bookmarked MCQs';

  @override
  String revisionCountIncorrect(int count) {
    return '$count गलत';
  }

  @override
  String revisionCountBookmark(int count) {
    return '$count bookmark';
  }

  @override
  String get ritualCaShotsWhen => 'पूरे दिन';

  @override
  String get ritualCaShotsBody =>
      'Breaking news brief + 1 MCQ। जब shot आए, बस दो मिनट।';

  @override
  String get ritualDailyCaWhen => 'सुबह 6 बजे खुलता है';

  @override
  String get ritualDailyCaBody =>
      'कल की खबरों का scored paper। कोई भी पुराना दिन revise करें।';

  @override
  String get ritualDailyWarWhen => 'रात 9 बजे · सोम–शुक्र';

  @override
  String get ritualDailyWarBody =>
      'All-India live static GS paper। सबके लिए वही सवाल, फिर rank।';

  @override
  String homeStreakMilestoneToast(int count) {
    return '$count-day streak. ऐसे ही लगे रहिए।';
  }

  @override
  String homeStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
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
      other: '$count तरह के trap',
      one: '1 तरह के trap',
    );
    return 'आप $_temp0 में फँसे हैं';
  }

  @override
  String homeStartNQuestionTest(int count) {
    return '$count सवालों का test शुरू करें';
  }

  @override
  String homeCountAvailable(int count) {
    return '$count उपलब्ध';
  }

  @override
  String activationLeftAt(int done, int total) {
    return 'आप सवाल $done/$total पर रुके थे। वहीं से आगे बढ़ें।';
  }

  @override
  String homeAnsweredOf(int done, int total) {
    return 'आप $total में से $done सवाल हल कर चुके हैं।';
  }

  @override
  String homeResumeProgress(int done, int total) {
    return 'जारी रखें · $total में से $done पूरे';
  }

  @override
  String restoreProgressTests(int done, int total) {
    return '$total में से $done tests';
  }

  @override
  String revisionPickPool(int count) {
    return 'एक pool चुनिए। इन सवालों में से एक छोटा random test मिलेगा — एक बार में अधिकतम $count सवाल।';
  }

  @override
  String homeOpenChallengeBy(String name) {
    return '$name का Open challenge';
  }

  @override
  String homeGoalOthersLive(String goal, int count) {
    return '$goal · +$count live';
  }

  @override
  String homeChallengeGoalMixed(String who, int score) {
    String _temp0 = intl.Intl.selectLogic(who, {
      'poster': 'Mixed subjects में उनके $score/10 के score को हराइए',
      'other': 'Mixed subjects में $score/10 के top score को हराइए',
    });
    return '$_temp0';
  }

  @override
  String homeChallengeGoalSubject(String who, int score, String subject) {
    String _temp0 = intl.Intl.selectLogic(who, {
      'poster': '$subject में उनके $score/10 के score को हराइए',
      'other': '$subject में $score/10 के top score को हराइए',
    });
    return '$_temp0';
  }

  @override
  String homeDangerLocked(int total) {
    return 'जो सवाल आपने sure होकर भी गलत किए। $total सवालों पर unlock होगा।';
  }

  @override
  String homeDangerLockedProgress(int total, int scored) {
    return 'जो सवाल आपने sure होकर भी गलत किए। $total सवालों पर unlock होगा — अभी $scored/$total।';
  }

  @override
  String homeWeekReviewCount(int mistakes) {
    return 'पिछले हफ़्ते जहाँ आप चूके थे, ऐसे $mistakes सवाल।';
  }

  @override
  String homeDrillSubjectBit(String subject) {
    return '10 $subject सवाल, तुरंत feedback के साथ।';
  }

  @override
  String homeDrillOpenAgain(String counts) {
    return '$counts। चाहें तो एक और set खोलें।';
  }

  @override
  String homeDrillShortSet(String counts) {
    return '$counts। गलत या bookmark किए सवालों का छोटा set।';
  }

  @override
  String get homeStreak3Toast => '3-day streak — आदत बन रही है।';

  @override
  String get homeQuestionBankUnavailable => 'Question bank उपलब्ध नहीं है';

  @override
  String get homeQuestionBankUnavailableBody =>
      'Question database नहीं खुल सका। ऐप दोबारा install करें या देखें कि storage उपलब्ध है, फिर restart करें।';

  @override
  String get homeGreetingGeneric => 'Hey there';

  @override
  String get homeResumeDemoTest => 'Demo test जारी रखें';

  @override
  String get homeStartWithDemoTest => 'Demo test से शुरू करें';

  @override
  String get homeRateReview => 'रेट और रिव्यू करें';

  @override
  String get homePickAnySubject => 'कोई भी विषय चुनें';

  @override
  String get homeSubjects => 'विषय';

  @override
  String get homeQuestionsYouSaved => 'आपके सेव किए हुए सवाल';

  @override
  String get activationStartHere => 'यहाँ से शुरू करें';

  @override
  String get activationTakeDemo => 'पाँच मिनट का Demo test दीजिए';

  @override
  String get activationPickUp => 'जहाँ छोड़ा था, वहीं से शुरू करें।';

  @override
  String get activationDemoPitch =>
      'देखिए, trap सवाल कैसे confident aspirants को भी फँसा देते हैं — और Danger Zone उसे कैसे पकड़ता है।';

  @override
  String get activationStartTest => 'Test शुरू करें';

  @override
  String get activationHideTitle => 'अभी छुपाएँ?';

  @override
  String get activationHideBody => 'हम इसे कल फिर दिखाएँगे।';

  @override
  String get activationHideConfirm => 'अभी छुपाएँ';

  @override
  String get activationKeepGoing => 'जारी रखें';

  @override
  String get drillSubjectTitle => 'आज की practice का विषय';

  @override
  String get drillSubjectBody =>
      'चुनिए, आपकी Daily Drill किस विषय पर focus करे।';

  @override
  String get revisionEmptyPools =>
      'जो सवाल आप गलत करेंगे या bookmark करेंगे, वे यहाँ दिखेंगे। फिर आप दोनों में से किसी भी pool से छोटा random test दे सकते हैं।';

  @override
  String get revisionPoolWrongBody => 'आपके गलत किए सवालों से एक random test।';

  @override
  String get revisionPoolSavedBody =>
      'आपके bookmark किए सवालों से एक random test।';

  @override
  String get ritualsIntroTitle => 'आपका daily loop';

  @override
  String get ritualsIntroOne => 'Home पर। रोज़ उसी जगह।';

  @override
  String get ritualsIntroTwo => 'Home पर दो चीज़ें। रोज़ उसी जगह।';

  @override
  String get ritualsIntroThree => 'Home पर तीन चीज़ें। रोज़ उसी जगह।';

  @override
  String get commonGotIt => 'समझ गया';

  @override
  String get restorePaused => 'Restore रुका हुआ है';

  @override
  String get restoreFailedBody => 'आपका डेटा restore नहीं हो सका।';

  @override
  String get restoreDoneTitle => 'आपका डेटा वापस आ गया';

  @override
  String get restoreDoneBody => 'आपके tests restore हो गए।';

  @override
  String get restoreInProgressTitle => 'आपका डेटा restore हो रहा है…';

  @override
  String get commonDismiss => 'हटाएँ';

  @override
  String get restoreKeepUsing =>
      'जब तक यह पूरा हो, आप ऐप इस्तेमाल करते रह सकते हैं।';

  @override
  String get homeNoQuestionsYet => 'अभी तक कोई सवाल हल नहीं किया।';

  @override
  String get commonResume => 'जारी रखें';

  @override
  String get demoInProgress => 'Demo test जारी है';

  @override
  String get commonStartOver => 'फिर से शुरू करें';

  @override
  String get demoTry => 'Demo test दीजिए';

  @override
  String get demoTrySuffix => ' — देखिए UPSC Wars आपको क्या edge देता है';

  @override
  String get demoRemindTomorrow => 'कल याद दिलाएँ';

  @override
  String get demoNotNowTitle => 'अभी नहीं?';

  @override
  String get demoNotNowBody =>
      'यह 5 मिनट का demo उन सवालों को पकड़ता है जिनके बारे में आप sure होते हैं पर गलत कर देते हैं — यही UPSC Wars की असली edge है। जब तक आप एक test पूरा नहीं करते, हम कल फिर याद दिलाएँगे।';

  @override
  String get demoTryDiagnostic => 'इसके बजाय Diagnostic आज़माएँ';

  @override
  String get demoIntroTitle => 'देखिए UPSC Wars आपको कहाँ edge देता है';

  @override
  String get demoIntroBody =>
      'यह demo दीजिए — current affairs और static मिलाकर, हर जवाब के बाद तुरंत feedback।';

  @override
  String get demoPoint1Title => '8 MCQs · कोई timer नहीं';

  @override
  String get demoPoint1Body =>
      'Current affairs और static — साथ-साथ explanation देखिए।';

  @override
  String get demoPoint2Title => 'अपना confidence चुनिए';

  @override
  String get demoPoint2Body =>
      'Sure, educated guess या unsure — हम पकड़ते हैं कि क्या सही लगता है पर होता नहीं।';

  @override
  String get demoPoint3Title => 'Test खत्म होते ही detailed insights';

  @override
  String get demoPoint3Body =>
      'Confident mistakes, trap patterns, और आगे क्या revise करना है।';

  @override
  String get demoPoint4Title => 'ऐसे Explanations जो सच में सिखाएँ';

  @override
  String get demoPoint4Body =>
      'Traps, elimination, statement analysis — सिर्फ़ सही-गलत नहीं।';

  @override
  String get demoLetsGo => 'चलिए शुरू करें';

  @override
  String get demoSkipToHome => 'Skip करके Home पर जाएँ';

  @override
  String get todayCaLive => 'Live है — कल की खबरों पर आधारित।';

  @override
  String get todayCaNotDone => 'कल की खबरों पर आधारित current affairs test।';

  @override
  String get todayDone => 'आज हो गया';

  @override
  String get todayQuizDoneOpenAnswers => 'Quiz पूरा — answers खोलें';

  @override
  String get todaySignInOpenChallenge =>
      'Open challenge में जुड़ने के लिए sign in करें।';

  @override
  String get todayDangerUnlocked =>
      'जो सवाल आपने sure होकर भी गलत किए — trap patterns।';

  @override
  String get todayWhatIsThis => 'यह क्या है?';

  @override
  String get todayCaShotSubtitle => 'Breaking news brief + उस पर आधारित 1 MCQ।';

  @override
  String get todayPaperQuizTitle => 'आज का Current affairs quiz';

  @override
  String get todayPaperQuizBody =>
      'कल की खबरों पर आधारित। सबके लिए वही सवाल — फिर All-India Rank।';

  @override
  String get todayOpenPaper => 'Paper खोलें';

  @override
  String get todayWeekDone => 'Week review पूरा';

  @override
  String get todayWeekDoneBody =>
      'आपने पिछले हफ़्ते की गलतियाँ देख लीं। Streak बरकरार है।';

  @override
  String get todaySeeResults => 'Results देखें';

  @override
  String get todayWeekEmpty => 'इस हफ़्ते कोई गलती नहीं';

  @override
  String get todayWeekEmptyBody =>
      'पिछले हफ़्ते कोई गलती नहीं — आप बिल्कुल clean हैं।';

  @override
  String get todayQuickPracticeInstead => 'इसके बजाय Quick practice';

  @override
  String get todayWeekReviewTitle => 'पिछले हफ़्ते की गलतियाँ review करें';

  @override
  String get todayStartReview => 'Review शुरू करें';

  @override
  String get todayDrillDone => 'Drill पूरी';

  @override
  String get todayDrillTitle => 'आज की Drill';

  @override
  String get todayDrillBody => '10 सवाल, तुरंत feedback के साथ।';

  @override
  String get todayDrillInBooks => 'आज की Drill पूरी हो गई।';

  @override
  String get todayOpenAgain => 'फिर से खोलें';

  @override
  String get commonStart => 'शुरू करें';

  @override
  String get progressPerfectWeek => 'Perfect week — सातों दिन पूरे 🔥';

  @override
  String progressDaysSealed(int count) {
    return 'इस हफ़्ते 7 में से $count दिन पूरे';
  }

  @override
  String progressWrongAnswersAllTime(int count) {
    return 'गलत जवाब (all-time) · ';
  }

  @override
  String progressAttemptedAccuracy(int attempted, String accuracy) {
    return '$attempted attempt · $accuracy accuracy';
  }

  @override
  String progressWrongAllTime(int count) {
    return '$count गलत (all-time)';
  }

  @override
  String profileAppVersion(String version) {
    return 'ऐप वर्ज़न: $version';
  }

  @override
  String get progressTabHistory => 'Test History';

  @override
  String get progressLoadFailed => 'Overview load नहीं हो सका।';

  @override
  String get progressSubtitle => 'सभी विषयों में आपका performance';

  @override
  String get progressSubjectsPractised => ' विषय practise किए';

  @override
  String get progressSortMostMistakes => 'सबसे ज़्यादा गलतियाँ';

  @override
  String get progressNotStarted => 'शुरू नहीं हुआ';

  @override
  String get profileMadeWithLove => 'प्यार से बनाया ';

  @override
  String get profileInDelhi => ' दिल्ली में';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileYourProfile => 'आपकी Profile';

  @override
  String get profileSignInPitch =>
      'Community से जुड़ने, battles में हिस्सा लेने और अपनी Profile बनाने के लिए sign in करें।';

  @override
  String get authSigningIn => 'Sign in हो रहा है...';

  @override
  String get authContinueApple => 'Apple से जारी रखें';

  @override
  String get authContinueGoogle => 'Google से जारी रखें';

  @override
  String get profilePhotoUpdated => 'Profile फ़ोटो अपडेट हो गई';

  @override
  String get profilePhotoWebHint =>
      'Profile फ़ोटो Android या iOS ऐप में बदली जा सकती है।';

  @override
  String get profileNoEmail => 'कोई ईमेल नहीं';

  @override
  String get profileAuthentication => 'लॉगिन का तरीका';

  @override
  String get profileAccountConnected => 'अकाउंट जुड़ा हुआ है';

  @override
  String get profileDataSecure => 'आपका अकाउंट डेटा सुरक्षित है';

  @override
  String get profileTelegramSlash => 'Telegram username में / नहीं होना चाहिए';

  @override
  String get profileInstagramSlash =>
      'Instagram username में / नहीं होना चाहिए';

  @override
  String get profileCommunityUpdated => 'Community Profile अपडेट हो गई';

  @override
  String get profileCommunityTitle => 'Community Profile';

  @override
  String get profileCommunityBody =>
      'ये fields भरिए ताकि दूसरे aspirants आपसे जुड़ सकें।';

  @override
  String get profileOptionalSubject => 'वैकल्पिक विषय';

  @override
  String get profileInstagramLabel => 'Instagram (@ के बिना)';

  @override
  String get profileTelegramLabel => 'Telegram (@ के बिना)';

  @override
  String get profileUpdating => 'अपडेट हो रहा है...';

  @override
  String get profileUpdate => 'अपडेट करें';

  @override
  String get riskLower => 'कम जोखिम';

  @override
  String get riskMedium => 'मध्यम जोखिम';

  @override
  String get riskHigher => 'ज़्यादा जोखिम';

  @override
  String testQuestionOfTotal(int current, int total) {
    return 'Q$current/$total';
  }

  @override
  String historySessionsCount(int count) {
    return '$count sessions';
  }

  @override
  String historyScoreDone(String score) {
    return '$score पूरे';
  }

  @override
  String reviewCorrectWrong(int correct, int wrong) {
    return '$correct सही · $wrong गलत';
  }

  @override
  String reviewQuestionOfTotal(int current, int total) {
    return 'सवाल $current/$total';
  }

  @override
  String get testCorrect => 'सही';

  @override
  String get testNotThisTime => 'इस बार नहीं';

  @override
  String get testHintCorrect =>
      'असली सीख explanation में है — elimination, statement analysis और trap option।';

  @override
  String get testHintWrong =>
      'बाकी options कैसे काटने हैं, यह पढ़िए — असली practice यही है।';

  @override
  String get testShowExplanation => 'Explanation दिखाइए';

  @override
  String get testConfidenceIntroTitle =>
      'अब से हम यह भी देखेंगे कि आप कितने sure हैं।';

  @override
  String get testConfidenceWhy => 'क्यों? ';

  @override
  String get testConfidenceWhyBody =>
      'ताकि आपकी confident mistakes पकड़ी जा सकें।';

  @override
  String get testHowSure => 'आप कितने sure हैं?';

  @override
  String get testHowSureBody =>
      'जवाब देखने से पहले चुनिए — इसी से आपका Danger Zone map बनता है।';

  @override
  String get testLeaveDemoTitle => 'Demo छोड़ें?';

  @override
  String get testLeaveDemoBody =>
      'आपकी progress save हो जाएगी। तैयार होने पर Home से जारी रखें।';

  @override
  String get testLeave => 'छोड़ें';

  @override
  String get testGoBackTitle => 'वापस जाएँ?';

  @override
  String get testLeaveTestTitle => 'Test छोड़ें?';

  @override
  String get testGoBackBody =>
      'क्या आप पक्का चाहते हैं? आपकी progress चली जाएगी।';

  @override
  String get testLeaveTestBody =>
      'आपकी progress save हो जाएगी, आप बाद में जारी रख सकते हैं।';

  @override
  String get testGoBack => 'वापस जाएँ';

  @override
  String get testSessionNotFound => 'Session नहीं मिला';

  @override
  String get commonSomethingWrong => 'कुछ गलत हो गया';

  @override
  String get testSessionLoadFailed => 'Test session load नहीं हो सका।';

  @override
  String get testTimerPausedNotice =>
      'ऐप बंद रहने के दौरान Timer रुका रहा। बचा हुआ समय सटीक नहीं हो सकता।';

  @override
  String get testBookmarked => 'Bookmark किया';

  @override
  String get testBookmarkRemoved => 'Bookmark हटाया';

  @override
  String get testGridHint => 'किसी भी नंबर पर tap करके उस सवाल पर जाइए';

  @override
  String get testGridCurrent => 'मौजूदा';

  @override
  String get testGridAttempted => 'Attempt किए';

  @override
  String get testGridFlagged => 'Flag किए';

  @override
  String get testGridNotVisited => 'देखे नहीं';

  @override
  String get testGridSkipped => 'Skip किए';

  @override
  String get testSubmitTest => 'Test submit करें';

  @override
  String get testSubmit => 'Submit करें';

  @override
  String get commonBack => 'वापस';

  @override
  String get testPrev => 'पिछला';

  @override
  String get testNext => 'अगला';

  @override
  String get demoLoadFailed => 'Demo test load नहीं हो सका।';

  @override
  String get historyTitle => 'History';

  @override
  String get historyLoadFailed => 'History load नहीं हो सकी';

  @override
  String get historyEmpty => 'अभी कोई session नहीं';

  @override
  String get historyNoneFound => 'कोई session नहीं मिला';

  @override
  String get historyEmptyHint =>
      'अपनी history यहाँ देखने के लिए एक test पूरा कीजिए';

  @override
  String get historyChangeFilters => 'Filters बदलकर देखिए';

  @override
  String get commonAll => 'सभी';

  @override
  String get historyAbandoned => 'अधूरा छोड़ा';

  @override
  String get historyInProgress => 'जारी है';

  @override
  String get historyRestart => 'फिर से शुरू करें';

  @override
  String get reviewShareTitle => 'यह test share करें';

  @override
  String get reviewShareBody =>
      'इस सवाल (या पूरे test) को दोस्तों को भेजने के लिए Share दबाइए।\n\nकिसी सवाल में गलती मिली? UPSC Wars developer को बताने के लिए Share इस्तेमाल कीजिए।';

  @override
  String get reviewQuestionLabel => 'सवाल';

  @override
  String get reviewPrevArrow => '← पिछला';

  @override
  String get reviewNextArrow => 'अगला →';

  @override
  String get reviewRemoveBookmark => 'Bookmark हटाएँ';

  @override
  String get reviewInRevisionQueue => 'Revision queue में है';

  @override
  String get reviewAddToRevisionQueue => 'Revision queue में जोड़ें';

  @override
  String get reviewCorrectAnswer => 'सही जवाब';

  @override
  String get reviewIncorrect => 'गलत';

  @override
  String get reviewTimesUp => 'समय समाप्त';

  @override
  String get reviewSkipped => 'Skip किया';

  @override
  String get reviewYourPick => 'आपका चुनाव';

  @override
  String get onbSublinePrefix => 'हम हर जवाब का analysis करते हैं ताकि ';

  @override
  String get onbSublinePhrase =>
      'पता चले कि कौन से topics आपका score बढ़ाते या घटाते हैं';

  @override
  String get onbSublineSuffix => '।';

  @override
  String get onbFeatureExplanation => 'विस्तृत explanation';

  @override
  String get onbFeatureStatement => 'Statement analysis';

  @override
  String get onbFeatureElimination => 'Elimination technique';

  @override
  String get onbFeatureDistractor => 'दमदार distractor option';

  @override
  String get onbThesisEyebrow => 'UPSC की सच्चाई';

  @override
  String get onbConfidentWrong => 'Confident\nऔर गलत';

  @override
  String get onbConfidentWrongBody =>
      'वे topics जिनमें आप confident हैं पर गलत करते हैं।';

  @override
  String get onbGuessRight => 'Guess\nऔर सही';

  @override
  String get onbGuessRightBody =>
      'वे topics जहाँ आपके guess अक्सर सही निकलते हैं।';

  @override
  String get onbNext => 'आगे  →';

  @override
  String get onbLead => 'Prelims सब कुछ जानने का नाम नहीं है।';

  @override
  String get onbAccent => 'UPSC Wars दिखाता है कि आप कहाँ खड़े हैं।';

  @override
  String get onbAvoidMistakes => 'महँगी गलतियों से बचिए।';

  @override
  String get onbReviseTopics => 'इन topics को revise कीजिए।';

  @override
  String get onbAttemptMore => 'इन topics से ज़्यादा attempt कीजिए';

  @override
  String get onbGainMarks => 'Positive marks कमाइए।';

  @override
  String get onbDepthEyebrow => 'UPSC की EDGE';

  @override
  String get onbDepthTitle => 'UPSC Wars के\nहर सवाल में है:';

  @override
  String get aboutWhyBody =>
      'मैंने खुद UPSC की तैयारी की है, और समझा कि ज़्यादातर aspirants हज़ारों MCQs हल करते हैं, फिर भी उन्हें पता नहीं चलता कि असल में उनके marks कहाँ कट रहे हैं।\n\nकई बार समस्या knowledge की कमी नहीं होती — वह होती है overconfidence, जोखिम भरे guess, कमज़ोर revision और बार-बार दोहराई गई गलतियाँ।\n\nसाथ ही, तैयारी का मतलब यह जानना भी है कि आप कहाँ सोच-समझकर risk ले सकते हैं और पूरे confidence के साथ ज़्यादा attempt कर सकते हैं।\n\nइसीलिए मैंने UPSC Wars बनाया।';

  @override
  String get aboutGoalBody =>
      'ताकि आपकी तैयारी सिर्फ़ ज़्यादा मेहनत वाली नहीं, ज़्यादा समझदार बने।\n\nमेरा लक्ष्य सीधा है:\n\nAspirants को वैसे तैयारी करने में मदद करना जैसे Prelims निकालने वाला करता है।\n\nयह पूरी तरह independent है। कोई coaching institute नहीं। कोई बड़ी team नहीं। बस UPSC की तैयारी को बेहतर बनाने की एक गंभीर कोशिश।';

  @override
  String get aboutConnectBody =>
      'आपका feedback सीधे UPSC Wars को बेहतर बनाता है।\n\nअगर कुछ कमी लगे, उलझन हो या कुछ काम का लगे, तो मुझे message कीजिए। मैं हर feedback खुद पढ़ता हूँ।\n\n📩 upscwars@gmail.com';

  @override
  String get aboutReviewBody =>
      'अगर UPSC Wars से आपकी तैयारी में मदद मिली हो, तो कृपया एक review दीजिए।\n\nआपका review और गंभीर aspirants को ऐप तक पहुँचाता है और ऐप को तेज़ी से बेहतर बनाने में मदद करता है।';

  @override
  String get aboutBullet1 =>
      '• ऐसे areas जहाँ Sure जवाब या Educated guess अक्सर गलत निकलते हैं\n';

  @override
  String get aboutArrow1 => '  → यहाँ extra risk लेने से बचिए\n\n';

  @override
  String get aboutBullet2 =>
      '• ऐसे areas जहाँ Sure जवाब या Educated guess अक्सर सही निकलते हैं\n';

  @override
  String get aboutArrow2 => '  → यहाँ समझदारी से risk लीजिए\n\n';

  @override
  String get aboutBullet3 =>
      '• UPSC के आम trap patterns और मुश्किल सवालों के प्रकार\n';

  @override
  String get aboutArrow3 => '  → सतर्क रहिए और negative marking से बचिए';

  @override
  String get aboutExAspirant => '(पूर्व aspirant)';

  @override
  String get aboutWhyTitle => 'मैंने UPSC Wars क्यों बनाया';

  @override
  String get aboutHelpsFind => 'यह आपको यह खोजने में मदद करता है:';

  @override
  String get aboutConnect => 'संपर्क करें';

  @override
  String get aboutReviews => 'रिव्यू';

  @override
  String get aboutRateReview => 'UPSC Wars को Rate/Review करें';

  @override
  String get aboutFeedbackEmail => 'Email पर Feedback भेजें';

  @override
  String get aboutFeedbackTelegram => 'Telegram पर Feedback भेजें';

  @override
  String get aboutLinkFailed => 'लिंक नहीं खुल सका';

  @override
  String resultsAccuracyVsLast(String sign, int value) {
    return 'पिछले test से $sign$value% accuracy';
  }

  @override
  String resultsMarksBreakdown(String earned, String lost) {
    return '+$earned मिले · $lost';
  }

  @override
  String get resultsZeroLost => '0 कटे';

  @override
  String resultsMarksLost(String value) {
    return '−$value कटे';
  }

  @override
  String resultsAllQuestions(int total) {
    return 'सभी $total सवाल';
  }

  @override
  String resultsAttemptedSkipped(int attempted, int skipped) {
    return '$attempted attempt · $skipped skip';
  }

  @override
  String resultsCountCorrect(int count) {
    return '$count सही';
  }

  @override
  String resultsCountWrong(int count) {
    return '$count गलत';
  }

  @override
  String resultsCountSkipped(int count) {
    return '$count skip';
  }

  @override
  String resultsCorrectOfAttempted(int correct, int attempted) {
    return '$attempted में से $correct सही';
  }

  @override
  String resultsAddedToQueue(int count) {
    return '$count सवाल revision queue में जुड़े';
  }

  @override
  String resultsTotalInQueue(int count) {
    return 'Queue में कुल $count';
  }

  @override
  String resultsPctWrong(int pct, int wrong, int attempted) {
    return '$pct% गलत ($wrong/$attempted)';
  }

  @override
  String resultsReviewAll(int count) {
    return 'सभी सवाल review करें ($count)';
  }

  @override
  String resultsTimingLine(int avg, int min, int max) {
    return 'औसत ${avg}s प्रति सवाल · सबसे तेज़ ${min}s · सबसे धीमा ${max}s';
  }

  @override
  String resultsYourScore(int pct) {
    return 'आपका score: $pct%';
  }

  @override
  String resultsNameYou(String name) {
    return '$name (आप)';
  }

  @override
  String get resultsAttemptToEarn => 'Marks कमाने के लिए सवाल attempt कीजिए';

  @override
  String get resultsNetMarks => 'Net marks';

  @override
  String get resultsNoneAttempted => 'कोई attempt नहीं';

  @override
  String get resultsNoAttemptsYet => 'अभी कोई attempt नहीं';

  @override
  String get resultsAttemptAccuracy => 'Attempt accuracy';

  @override
  String get resultsNoneAddedToQueue => 'इस test से कोई गलत जवाब नहीं जुड़ा।';

  @override
  String get resultsGoToQueue => 'Queue खोलें';

  @override
  String get resultsWorstTopics => 'सबसे कमज़ोर topics';

  @override
  String get resultsBestTopics => 'सबसे अच्छी accuracy वाले topics';

  @override
  String get commonShowLess => 'कम दिखाएँ';

  @override
  String get commonViewAll => 'सभी देखें';

  @override
  String get resultsBackToHome => 'Home पर लौटें';

  @override
  String get resultsMoreInsights => 'और insights';

  @override
  String get resultsAreYouSure => 'क्या आप पक्का चाहते हैं?';

  @override
  String get resultsReturnHome => 'आप Home screen पर लौट जाएँगे।';

  @override
  String get resultsGoToHome => 'Home पर जाएँ';

  @override
  String get resultsLoadFailed => 'Results load नहीं हो सके';

  @override
  String get resultsShareTest => 'Test share करें';

  @override
  String get resultsSessionSummary => 'Session का सारांश';

  @override
  String get resultsTop5Shared => 'इस shared test के Top 5';

  @override
  String get resultsLeaderboardEmpty => 'अभी खाली है।';

  @override
  String get resultsLeaderboardFailed => 'Leaderboard load नहीं हो सका।';

  @override
  String get shareLinkCopied => 'Link copy हो गया';

  @override
  String get shareTitle => 'Test share करें';

  @override
  String get shareQuestion => 'सवाल';

  @override
  String get shareEntireTest => 'पूरा Test';

  @override
  String get shareGenerating => 'Link बन रहा है...';

  @override
  String get shareInfoFriends =>
      'आप यह link अपने दोस्तों के साथ share कर सकते हैं।';

  @override
  String get shareInfoReport =>
      'इस सवाल में कोई गलती हो तो यही link UPSC Wars team को report करने के लिए इस्तेमाल करें।';

  @override
  String get commonCopy => 'Copy करें';

  @override
  String get shareContactUs => 'हमसे संपर्क करें';

  @override
  String get shareLink => 'Link share करें';

  @override
  String get shareFailed => 'Link नहीं बन सका';

  @override
  String get resultsReviewYourMistakes => 'अपनी गलतियाँ review करें';

  @override
  String resultsRealExamCost(String marks) {
    return 'Real exam में नुकसान: −$marks marks';
  }

  @override
  String resultsTopRisk(String topic) {
    return 'सबसे ज़्यादा risk: $topic';
  }

  @override
  String resultsTopRiskPct(String topic, int pct) {
    return 'सबसे ज़्यादा risk: $topic (आपके नुकसान का $pct%)';
  }

  @override
  String resultsConfidentMistakesTitle(int count) {
    return '$count Confident Mistake';
  }

  @override
  String resultsReviewConfidentCta(int count) {
    return '$count confident mistake review करें';
  }

  @override
  String resultsEduMistakesTitle(int count) {
    return '$count Educated Guess Mistake';
  }

  @override
  String resultsReviewEduCta(int count) {
    return '$count educated guess review करें';
  }

  @override
  String resultsMixedMistakesTitle(int sure, int edu) {
    return '$sure Confident · $edu Educated guess';
  }

  @override
  String resultsIncompleteHeadline(int attempted, int total) {
    return '$total में से $attempted attempt';
  }

  @override
  String resultsLeftUnanswered(int count) {
    return '$count सवाल छूट गए। बेहतर insights के लिए पूरे test दीजिए।';
  }

  @override
  String resultsQrMixed(int total) {
    return 'आपने $total सवालों में marks खोए — कुछ में आप sure थे';
  }

  @override
  String resultsQrSure(int count) {
    return 'आपने $count सवाल में marks खोए — आप उनमें sure थे';
  }

  @override
  String resultsQrEdu(int count) {
    return 'आपने $count सवाल में marks खोए — आपका educated guess काम नहीं आया';
  }

  @override
  String get resultsCaseASubtitle =>
      'आप sure थे, फिर भी गलत। यही rank killers हैं।';

  @override
  String get resultsCaseBSubtitle =>
      'आपकी elimination strategy जितनी बार चली, उससे ज़्यादा बार फेल हुई।';

  @override
  String get resultsCaseCSubtitle =>
      'Overconfidence और risky elimination, दोनों की वजह से marks गए।';

  @override
  String get resultsCaseDSubtitle =>
      'गलत जवाब pure guess थे। फिर भी marks गए, इसलिए review करना ठीक रहेगा।';

  @override
  String get resultsNoConfidentMistakes => 'कोई confident mistake नहीं';

  @override
  String get resultsExcellentEyebrow => 'शानदार SESSION';

  @override
  String get resultsCaseESubtitle =>
      'जब आप confident थे, तब सही रहे। यही momentum बनाए रखें।';

  @override
  String get resultsExcellentTitle => 'शानदार session';

  @override
  String get resultsPracticeMore => 'और practice करें';

  @override
  String get resultsCaseFSubtitle =>
      'आपने कुछ सवाल छोड़ दिए। बेहतर insights के लिए पूरे test दीजिए।';

  @override
  String get resultsIncompleteTitle => 'अधूरा session';

  @override
  String get resultsLockedEyebrow => 'INSIGHTS बंद हैं';

  @override
  String get resultsCaseGSubtitle =>
      'Personalised insights unlock करने के लिए confidence tracking चालू करें।';

  @override
  String get resultsLockedTitle => 'Insights बंद हैं';

  @override
  String get resultsEnableTracking => 'Confidence tracking चालू करें';

  @override
  String get resultsCaseHSubtitle =>
      'क्योंकि यह test confidence mark किए बिना दिया गया था।';

  @override
  String get resultsInsightsUnavailable => 'Confidence insights उपलब्ध नहीं';

  @override
  String get resultsRetryWithConfidence => 'Confidence mark करके दोबारा दें';

  @override
  String get resultsCaseISubtitle =>
      'आपने कोई सवाल हल किए बिना submit कर दिया। तैयार हों तब दोबारा कोशिश करें।';

  @override
  String get resultsNoQuestionsAttempted => 'कोई सवाल attempt नहीं हुआ';

  @override
  String get resultsRetryTest => 'Test दोबारा दें';

  @override
  String get resultsFinishMore =>
      'इसे clean session कहने से पहले test का और हिस्सा पूरा कीजिए।';

  @override
  String get resultsQrTitle => 'REVIEW के लिए सवाल';

  @override
  String get resultsQrReveal => 'ये सवाल बता सकते हैं:';

  @override
  String get resultsQrBullet1 =>
      'ऐसे concepts जो जाने-पहचाने लगते हैं पर पूरी तरह clear नहीं हैं';

  @override
  String get resultsQrBullet2 =>
      'ऐसे topics जहाँ detail मायने रखती है और आप उसे चूक गए';

  @override
  String get resultsQrBullet3 => 'Exam के दिन की टाली जा सकने वाली गलतियाँ';

  @override
  String resultsYouWere(String label) {
    return 'आप $label थे';
  }

  @override
  String resultsNoTierItems(String label) {
    return 'कोई $label item नहीं';
  }

  @override
  String resultsWithOutcome(String outcome) {
    return ' (outcome “$outcome”)';
  }

  @override
  String resultsNoTierBody(String label, String outcome) {
    return 'इस session के किसी scored सवाल को “$label” में log नहीं किया गया$outcome।';
  }

  @override
  String get resultsWrongOnly => ' · सिर्फ़ गलत';

  @override
  String get resultsCorrectOnly => ' · सिर्फ़ सही';

  @override
  String resultsLoggedAs(String tier, String suffix) {
    return 'Log किया: $tier$suffix';
  }

  @override
  String resultsLostMarksOn(int count) {
    return 'आपने $count सवाल में marks खोए';
  }

  @override
  String get resultsWatchOutFor => 'इन पर ध्यान दीजिए:';

  @override
  String get resultsEyebrowSureWrong => 'CONFIDENT · गलत';

  @override
  String get resultsSureDesc =>
      'आप sure थे — फिर भी marks गए।\n\nइन्हें ध्यान से देखिए और जाँचिए कि सवाल गलत पढ़ा या समझ में gap है।';

  @override
  String get resultsSureBullet3 => 'ऐसे Traps जो बाद में साफ़ दिखते हैं';

  @override
  String get resultsEyebrowEduWrong => 'EDUCATED GUESS · गलत';

  @override
  String get resultsEduDesc =>
      'आपको कुछ idea था, पर काफ़ी नहीं। ये साफ़ gaps हैं — confident mistakes से ठीक करना आसान। आप जानते हैं कि इन्हें revise करना है।';

  @override
  String get resultsEduBullet1 => 'ऐसे topics जिन्हें focused revision चाहिए';

  @override
  String get resultsEduBullet2 =>
      'ऐसे concepts जो देखे तो हैं पर पूरी तरह समझे नहीं';

  @override
  String get resultsEduBullet3 =>
      'जहाँ elimination logic मज़बूत करने की ज़रूरत है';

  @override
  String get resultsReviewLoadFailed => 'Review load नहीं हो सका';

  @override
  String get resultsNoDangerItems => 'Danger Zone में कोई item नहीं';

  @override
  String get resultsNoDangerBody =>
      'जिन गलत जवाबों में confidence नहीं चुना गया, या जहाँ आपने \"Pure guess\" चुना, वे यहाँ नहीं दिखते।';

  @override
  String get resultsInvalidFilter => 'Confidence filter सही नहीं है।';

  @override
  String get resultsNoReviewable =>
      'इस session में review करने लायक कोई गलती नहीं।';

  @override
  String get resultsReviewLoadFailedDot => 'Review load नहीं हो सका।';

  @override
  String get resultsSureWrongSeg => 'Sure + गलत';

  @override
  String get resultsEduWrongSeg => 'Edu guess + गलत';

  @override
  String get resultsReviewConfidentMistakes => 'Confident mistakes review करें';

  @override
  String get resultsSwipeBoth => 'दोनों तरह देखने के लिए swipe करें';

  @override
  String get resultsStartReview => 'Review शुरू करें';

  @override
  String resultsUnlockMapBody(int answered) {
    return 'आपने अपने $answered scored सवालों में से किसी पर confidence log नहीं किया। हर जवाब के बाद चुने हुए option के नीचे तीन chips में से एक tap करें — इसी से Danger Zone, tier के हिसाब से accuracy और बेहतर revision hints बनते हैं।';
  }

  @override
  String resultsLogMoreBody(int logged, int answered, String pct) {
    return 'आपने $answered में से $logged scored सवाल tag किए ($pct%)। कम से कम आधे tag करने की कोशिश करें — जितना ज़्यादा log करेंगे, insights उतने सटीक होंगे।';
  }

  @override
  String resultsSureWarn(String pct, int correct, int total) {
    return 'जब आपने Sure चुना, तब आप $pct% बार सही थे ($correct / $total)। Prelims से पहले high-conviction जवाबों पर लगभग 75%+ का target रखें।';
  }

  @override
  String resultsSureOk(String pct, int correct, int total) {
    return 'Sure-tier accuracy $pct% ($correct / $total)। Conviction वाले जवाबों के लिए यह अच्छी range है।';
  }

  @override
  String get resultsMatrixHint =>
      'सिर्फ़ उन सवालों को review करने के लिए cell पर tap करें (इसी session के)।';

  @override
  String get resultsUnlockMap => 'अगली बार यह map unlock करें';

  @override
  String get resultsLogMore => 'अगली बार थोड़ा और log करें';

  @override
  String get resultsMatrixCorrect => 'सही';

  @override
  String get resultsMatrixWrong => 'गलत';

  @override
  String get resultsCoverageHint =>
      'वे सवाल जिनमें जवाब देने के बाद आपने Sure, Educated guess या Pure guess चुना।';

  @override
  String get resultsCoachMistakesTitle => 'सिर्फ़ अपनी गलतियाँ review करें';

  @override
  String get resultsCoachMistakesBody =>
      'सिर्फ़ वे सवाल जो आपने गलत किए — जिन पर वापस जाना ज़रूरी है।';

  @override
  String get resultsCoachAllOr => 'या सभी सवाल review करें';

  @override
  String get resultsCoachAll => 'सभी सवाल review करें';

  @override
  String get resultsCoachAllBody =>
      'पूरा paper, उन सवालों समेत जो आपने सही किए।';

  @override
  String get resultsCoachTopicsTitle => 'यह सब याद रखने की ज़रूरत नहीं';

  @override
  String get resultsCoachTopicsBody =>
      'यही weak और strong topics की list हर subject में मिलती है। जब चाहें Home से कोई subject खोलें।';

  @override
  String get resultsCoachGotIt => 'समझ गया';

  @override
  String get resultsCoachNext => 'आगे';

  @override
  String commonQuestionCount(int count) {
    return '$count सवाल';
  }

  @override
  String bookmarksSavedCount(int count) {
    return '$count saved';
  }

  @override
  String get revisionStartSession => 'Revision session शुरू करें';

  @override
  String get revisionEmptyTitle => 'आपकी revision queue खाली है';

  @override
  String get revisionEmptyBody =>
      'जो सवाल आप गलत करेंगे या bookmark करेंगे, वे यहाँ दिखेंगे';

  @override
  String get revisionNoItemsSubject => 'इस subject में कोई item नहीं है।';

  @override
  String get revisionMastered => 'Mastered';

  @override
  String get revisionInQueue => 'Queue में';

  @override
  String get bookmarkRemoved => 'Bookmark हटा दिया';

  @override
  String get commonUndo => 'वापस करें';

  @override
  String get bookmarksEmptyTitle => 'अभी कोई bookmark नहीं';

  @override
  String get bookmarksEmptyBody =>
      'Test के दौरान सवाल bookmark करें, वे यहाँ save हो जाएँगे';

  @override
  String get commonRemove => 'हटाएँ';

  @override
  String trapsCatalogCount(int count) {
    return '$count UPSC Traps';
  }

  @override
  String trapsCaughtOfTotal(int caught, int total) {
    return '$total में से $caught में आप फँसे';
  }

  @override
  String weakGroupSummary(String questions, String times) {
    return '$questions · $times गलत';
  }

  @override
  String commonTimesCount(int count) {
    return '$count बार';
  }

  @override
  String trapsCaughtByThis(int count) {
    return 'इस Trap में $count सवाल फँसे';
  }

  @override
  String weakNeedMore(String subject) {
    return '$subject में अपने weak areas देखने के लिए और सवाल attempt करें';
  }

  @override
  String trapsCaughtCount(int count) {
    return '$count× फँसाया';
  }

  @override
  String topicInRevisionQueue(int count) {
    return 'Revision queue में $count';
  }

  @override
  String topicDangerLine(int sure, int edu) {
    return 'Sure + गलत: $sure · Educated guess + गलत: $edu (अब तक)';
  }

  @override
  String subjectTestInfo(String questions, int topics) {
    return '$questions सवाल · $topics topics';
  }

  @override
  String pyqNoQuestionsYear(String year) {
    return '$year के लिए अभी कोई सवाल उपलब्ध नहीं है।';
  }

  @override
  String pyqSetOf(int n, int total) {
    return 'Set $n / $total';
  }

  @override
  String pyqFixedOrder(int count) {
    return '$count सवाल (इस set का क्रम तय है)';
  }

  @override
  String pyqTestN(int n) {
    return 'Test $n';
  }

  @override
  String pyqQuestionsRange(int from, int to) {
    return 'सवाल $from–$to';
  }

  @override
  String notifLoadFailed(String error) {
    return 'Message load नहीं हो सका।\n$error';
  }

  @override
  String get trapsNoCatalog => 'अभी कोई Trap catalog नहीं है';

  @override
  String get commonNoDataFound => 'कोई data नहीं मिला';

  @override
  String get weakPracticeSubtopic => 'इस Sub-topic की practice करें';

  @override
  String get weakPracticeTrap => 'इस Trap type की practice करें';

  @override
  String get trapsCaughtZero => 'अभी तक फँसे नहीं — data काफ़ी नहीं है';

  @override
  String get trapsSeeExample => 'Example देखें';

  @override
  String get weakLegend =>
      'Accuracy = topic में attempt किए सवालों में सही का %।\nAttempt = topic के कितने % सवाल आपने attempt किए।';

  @override
  String get trapsExampleEyebrow => 'EXAMPLE';

  @override
  String get trapsExampleLoadFailed => 'Example load नहीं हो सका।';

  @override
  String get trapsNoExample => 'इस Trap का example अभी लिखा नहीं गया है।';

  @override
  String get trapsSpotted => 'आपने पकड़ लिया।';

  @override
  String get trapsThatsTheTrap => 'यही Trap है।';

  @override
  String get trapsTrackingNote =>
      'हम track करते हैं कि कौन-से Traps में आप सबसे ज़्यादा फँसते हैं, ताकि exam में आप उन पर नज़र रख सकें।';

  @override
  String get topicSearchHint => 'Topics खोजें...';

  @override
  String get topicNoMatch => 'आपकी search से कोई topic नहीं मिला।';

  @override
  String get topicLoadFailed => 'Topics load नहीं हो सके।';

  @override
  String get subjectTestChooseBattle => 'Battle शुरू करने के लिए subject चुनें';

  @override
  String get subjectTestChooseBegin => 'शुरू करने के लिए subject चुनें';

  @override
  String get subjectTestStartBattle => 'Battle शुरू करें';

  @override
  String get subjectTestLoadFailed => 'Subjects load नहीं हो सके।';

  @override
  String get pyqLoadFailed => 'PYQ sets load नहीं हो सके';

  @override
  String get commonCompleted => 'पूरा हुआ';

  @override
  String get notifScreenTitle => 'Notification';

  @override
  String get notifNoAnnouncement => 'अभी कोई announcement उपलब्ध नहीं है।';

  @override
  String get notifEmptyAnnouncement => 'यह announcement खाली है।';

  @override
  String topicsAttempts(int count) {
    return '· $count attempt';
  }

  @override
  String commonDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन पहले',
      one: '1 दिन पहले',
    );
    return '$_temp0';
  }

  @override
  String subjCorrectOfTotal(int correct, int total, String pct) {
    return '$total में से $correct सही · $pct%';
  }

  @override
  String subjQuestionsPlain(int count) {
    return '$count सवाल';
  }

  @override
  String dzStartFailed(String error) {
    return 'Session शुरू नहीं हो सका: $error';
  }

  @override
  String dzTitleOf(String label) {
    return '$label का Danger zone';
  }

  @override
  String dzTotalLine(int count, String marks) {
    return 'कुल: $count गलत · लगभग $marks marks कटे (हर गलत जवाब पर 0.66 marks कटते हैं)';
  }

  @override
  String dzApproxMarks(String marks) {
    return '≈ $marks marks';
  }

  @override
  String subjAllTopicsIn(String subject) {
    return '$subject के सभी topics से सवाल';
  }

  @override
  String subjPracticeTopicsCount(int count) {
    return 'चुने हुए topics की practice करें ($count topics)';
  }

  @override
  String subjCompletedSessions(int count) {
    return '$count पूरे session';
  }

  @override
  String get commonWrongLower => 'गलत';

  @override
  String subjTopicOpenFailed(String error) {
    return 'Topic नहीं खुल सका: $error';
  }

  @override
  String subjAdviceFor(String subject) {
    return '$subject के लिए सलाह';
  }

  @override
  String subjSureEduWrong(int sure, int edu) {
    return 'Sure + गलत: $sure · Edu guess + गलत: $edu';
  }

  @override
  String subjConfidentRate(String rate, String global) {
    return 'Confident होने पर: $rate% सही · overall $global% के मुकाबले';
  }

  @override
  String get subjHistLoadFailed => 'History load नहीं हो सकी।';

  @override
  String get subjHistEmptyTitle => 'अभी कोई पूरा session नहीं है।';

  @override
  String get subjHistEmptyBody =>
      'अपने results यहाँ देखने के लिए test शुरू करें।';

  @override
  String get subjStartTest => 'Test शुरू करें';

  @override
  String get commonLoadMore => 'और दिखाएँ';

  @override
  String get topicsNotStarted => 'शुरू नहीं हुआ';

  @override
  String get topicsNoneFound => 'इस subject में कोई topic नहीं मिला।';

  @override
  String get topicsBankInstalling =>
      'अगर आपका question bank अभी install हो रहा है, तो वापस जाकर थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get commonToday => 'आज';

  @override
  String get commonYesterday => 'कल';

  @override
  String get subjModeLearning => 'Learning';

  @override
  String get subjModeExam => 'Exam';

  @override
  String get dzNoQuestions => 'इस category में कोई सवाल नहीं।';

  @override
  String get dzSubtitle => 'Sure या Educated-guess के साथ गलत जवाब (अब तक)';

  @override
  String get dzCalm => 'अभी Sure या Educated-guess के साथ कोई गलत जवाब नहीं।';

  @override
  String get dzSureWrong => 'Sure — गलत';

  @override
  String get dzSureWrongBody => 'आपने Sure चुना और जवाब गलत निकला।';

  @override
  String get dzEduWrong => 'Educated guess — गलत';

  @override
  String get dzEduWrongBody => 'आपने Educated guess चुना और जवाब गलत निकला।';

  @override
  String get commonRevise => 'Revise करें';

  @override
  String get topicSheetNoQuestions => 'इस topic में अभी कोई सवाल नहीं है।';

  @override
  String get topicSheetInsights => 'INSIGHTS';

  @override
  String get topicSheetDzFailed => 'Danger zone load नहीं हो सका।';

  @override
  String get mockReviseTitle => 'अगले Mock से पहले Revise करें';

  @override
  String get mockReviseWhy =>
      'ये वे topics हैं जहाँ आपके Sure + Incorrect और Educated Guess + Incorrect आपके सामान्य औसत से ज़्यादा हैं।';

  @override
  String get mockWhatToDo => 'क्या करें';

  @override
  String get mockReviseAction =>
      'अगले mock से पहले अपने notes से ये topics पहले revise करें, ताकि महँगी गलतियाँ कम हों और score बेहतर हो।';

  @override
  String get mockSafeTitle => 'ज़्यादा Attempt के लिए Safe Areas';

  @override
  String get mockSafeWhy =>
      'ये वे topics हैं जहाँ आपके Sure + Correct और Educated Guess + Correct आपके सामान्य औसत से बेहतर हैं।';

  @override
  String get mockSafeAction =>
      'Mocks और exams में इन topics के सवाल ज़्यादा confidence से attempt करें।';

  @override
  String get mockMoreClarity => 'और clarity चाहिए? ';

  @override
  String get subjFeedbackLead => 'कोई सवाल या feedback?\n';

  @override
  String get subjGetInTouch => 'हमसे संपर्क करें';

  @override
  String get subjBrowseTopicsLower => 'Topics देखें';

  @override
  String get subjNewTestBody =>
      'Test शुरू करें या कुछ चुने हुए topics की practice करें।';

  @override
  String get subjStartAndMark =>
      'Test शुरू करें और अपने insights देखने के लिए confidence mark करें';

  @override
  String get subjBrowseTopics => 'Topics देखें';

  @override
  String get subjPracticeTopics => 'चुने हुए topics की practice करें';

  @override
  String get subjHistoryBody => 'इस subject के पूरे हुए sessions की list।';

  @override
  String get subjSessionCountFailed => 'Session count load नहीं हो सका।';

  @override
  String get subjViewHistory => 'Test history देखें';

  @override
  String get subjNoSessionsYet => 'अभी कोई पूरा session नहीं';

  @override
  String get subjStatsFailed => 'Subject stats load नहीं हो सके।';

  @override
  String get subjMarkHint =>
      'इस subject के scored सवाल हल करते समय Sure या Educated guess mark करें — mock-prep सलाह और आपका confidence breakdown यहाँ दिखेगा।';

  @override
  String get subjStatsSharpen =>
      'Confidence labels के साथ ज़्यादा scored जवाब देने पर ये stats और सटीक होंगे।';

  @override
  String get subjNoAttemptsYet =>
      'अभी कोई attempt किया हुआ जवाब नहीं।\nअपने insights देखने के लिए test शुरू करें और confidence mark करें';

  @override
  String get subjAccuracySuffix => ' accuracy';

  @override
  String get subjMcqsAttempted => ' MCQs attempt किए';

  @override
  String get subjSureNone => 'Sure → गलत: — (अभी कोई Sure-marked जवाब नहीं)';

  @override
  String get subjGuessNone =>
      'Educated guess → गलत: — (अभी कोई Educated-guess जवाब नहीं)';

  @override
  String get subjBreakdownTitle => 'इस subject में आपका confidence breakdown';

  @override
  String get subjNoConfidentWrongs =>
      'अभी analyse करने लायक कोई confident गलती नहीं';

  @override
  String get subjReviseQuestions => 'ये सवाल revise करें';

  @override
  String get subjTopicNotFound => 'Catalog में topic नहीं मिला।';

  @override
  String get subjReviseMcqs => 'MCQs revise करें';

  @override
  String get subjAdviceSubtitle =>
      'कहाँ revise करना है और कहाँ ज़्यादा attempt करना है';

  @override
  String get subjAdviceEmpty =>
      'यहाँ सलाह और insights देखने के लिए confidence mark करते हुए MCQs attempt करना शुरू करें';

  @override
  String get subjReviseTopicsIntro =>
      'Overconfidence और risky guessing की वजह से इन topics में आपके marks जाने की संभावना ज़्यादा है।';

  @override
  String get subjTopicsToRevise => 'Revise करने वाले topics';

  @override
  String get subjNoTopicsToList => 'दिखाने के लिए कोई topic नहीं';

  @override
  String get subjNoTopicsBody =>
      'इस subject के किसी topic में अभी इतने गलत जवाब “Sure” या “Educated guess” के साथ नहीं हैं कि यहाँ दिखाए जा सकें। जैसे ही यह pattern दिखेगा, आपको यह confidence के type के हिसाब से दिखेगा।';

  @override
  String get subjWhyTopics => 'ये topics क्यों?';

  @override
  String get subjRevisitTopic => 'यह topic फिर से देखें';

  @override
  String get subjSafeIntro =>
      'इन topics में आप अपने judgment पर ज़्यादा भरोसा कर सकते हैं। Mocks और exams में यहाँ से ज़्यादा attempt करें।';

  @override
  String get subjSafeTopics => 'Safe scoring topics';

  @override
  String get subjBaselineNotReady => 'Baseline अभी तैयार नहीं';

  @override
  String get subjNoTopicsQualify => 'अभी कोई topic qualify नहीं करता';

  @override
  String get subjBaselineBody =>
      'हमें ऐसे scored जवाबों का अच्छा sample चाहिए जहाँ आप very या somewhat sure थे। Tests में confidence इस्तेमाल करते रहें, ताकि हम आपका global rate तय करके उससे बेहतर topics दिखा सकें।';

  @override
  String get subjNoQualifyBody =>
      'इस subject में अभी कोई topic आपके overall confident-correct rate से साफ़ ऊपर नहीं है। जैसे-जैसे आप very sure या somewhat sure attempts बढ़ाएँगे, list update होगी।';

  @override
  String get subjAttemptMore => 'और attempt करें';

  @override
  String get subjMockPrepFailed => 'Mock-prep tips load नहीं हो सकीं।';

  @override
  String get subjInsightsFailed => 'Insights load नहीं हो सके।';

  @override
  String notifPaperBody(int count) {
    return 'अभी पढ़ी खबरों से $count MCQs';
  }

  @override
  String notifPaperBodyTonight(int count, String topics) {
    return 'खबरों से $count MCQs · आज रात: $topics';
  }

  @override
  String prelimsDaysTo(int days) {
    return 'UPSC Prelims में $days दिन';
  }

  @override
  String prelimsBodyDays(int days) {
    return '$days दिन बाकी\nहर दिन छोटे कदम — यही edge है।';
  }

  @override
  String get notifNoTestTitle => 'देखिए UPSC Wars आपको कहाँ edge देता है';

  @override
  String get notifNoTestBody =>
      'बस 8 quick MCQs दीजिए। बेहतर elimination सीखिए, weak areas पहचानिए और देखिए कि आप कहाँ strong हैं।';

  @override
  String get notifBattleInviteTitle => 'Battle invite';

  @override
  String get notifTapToJoin => 'Join करने के लिए tap करें';

  @override
  String get notifCaShotTitle => 'CA Shot';

  @override
  String get notifTapToRead => 'पढ़ने और attempt करने के लिए tap करें';

  @override
  String get notifNewMessage => 'नया message';

  @override
  String get notifTapToOpenChat => 'Chat खोलने के लिए tap करें';

  @override
  String get notifPaperTitle => 'आज का paper quiz live है';

  @override
  String get prelimsToday => 'Prelims आज है';

  @override
  String get prelimsBodyToday =>
      'आज exam का दिन है,\nआपने इसके लिए तैयारी की है — साँस लीजिए और अपना best दीजिए।';

  @override
  String get prelimsBodyOneDay => 'बस 1 दिन बाकी,\nएक बार में एक शांत session।';

  @override
  String dcaProgressFailed(String error) {
    return 'Progress load नहीं हो सकी: $error';
  }

  @override
  String dcaOfCount(int count) {
    return 'कुल $count participants में से';
  }

  @override
  String dcaAvailableIn(String countdown) {
    return 'Test $countdown में उपलब्ध होगा';
  }

  @override
  String dcaJoinedCount(int count) {
    return '$count शामिल हुए';
  }

  @override
  String dcaTestFromNews(String date) {
    return 'यह test $date की खबरों के सवालों से बना है।';
  }

  @override
  String dcaNoChampionYet(String date) {
    return '$date · Champion अभी lock नहीं हुआ';
  }

  @override
  String dcaJoinedLocked(String date, int count) {
    return '$date · $count शामिल · Champion locked';
  }

  @override
  String dcaJoinedLive(String date, int count) {
    return '$date · $count शामिल · live';
  }

  @override
  String dcaYouAir(int air) {
    return 'आप · AIR $air';
  }

  @override
  String dcaStartFrom(String date) {
    return 'Daily tests $date से शुरू होते हैं।';
  }

  @override
  String dcaTenFromPaper(String date) {
    return '$date के paper से 10 MCQs';
  }

  @override
  String dcaLiveIn(String t) {
    return '$t में live';
  }

  @override
  String dcaNextTestIn(String t) {
    return 'अगला test $t में';
  }

  @override
  String get dcaThisMonth => 'इस महीने';

  @override
  String get dcaReviewOrRevise => 'Review या revise करें';

  @override
  String get dcaTakeTodays => 'आज का test दें';

  @override
  String get dcaTodaysPaperBtn => 'आज का paper';

  @override
  String get dcaNoRanks =>
      'अभी कोई rank नहीं। आज का paper सबसे पहले पूरा करने वाले बनिए।';

  @override
  String get dcaSubmitFailed => 'Submit नहीं हो सका';

  @override
  String get dcaLoadingResults => 'आपके results load हो रहे हैं…';

  @override
  String get dcaTodaysBoard => 'आज का board';

  @override
  String get dcaRanksPreview => 'Ranks अभी preview में हैं।';

  @override
  String get dcaSignInForAir =>
      'आज की All-India Rank में शामिल होने के लिए Profile से sign in करें।';

  @override
  String get dcaUnrankedLocked =>
      'Unranked · इस paper का Champion पहले ही lock हो चुका है।';

  @override
  String get dcaSubmitted => 'Submit हो गया।';

  @override
  String get dcaTodaysLeaderboard => 'आज का Leaderboard';

  @override
  String get dcaReviewAnswers => 'जवाब review करें';

  @override
  String get dcaLiveUnranked => 'Unranked · Champion पहले ही lock हो चुका है।';

  @override
  String get dcaLiveAir =>
      'AIR अब भी बदल सकती है। Champion 6 AM IST पर lock होता है।';

  @override
  String get dcaNotAvailableCopy => 'इस तारीख़ के सवाल अभी उपलब्ध नहीं हैं।';

  @override
  String get dcaGenericLoadCopy =>
      'Test load नहीं हो सका। अपना connection जाँचें और फिर कोशिश करें।';

  @override
  String get testStartTest => 'Test शुरू करें';

  @override
  String get dcaNotLiveTitle => 'सवाल अभी live नहीं हैं';

  @override
  String get dcaSoonTitle => 'सवाल जल्द उपलब्ध होंगे';

  @override
  String get dcaNotLiveBody =>
      'आज सुबह का paper बन चुका है, पर ऐप में अभी publish नहीं हुआ है। एक मिनट बाद Home को नीचे खींचकर refresh करें।';

  @override
  String get dcaSoonBody =>
      'हर paper news articles से बनता है। यह परखता है कि आपने पिछले दिन की खबरें कितना अच्छे से पढ़ीं — कल का अख़बार, आज सुबह का quiz।';

  @override
  String get dcaSeePast => 'पुराने current affairs MCQs देखें';

  @override
  String get dcaChampionLocked => 'इस paper का Champion lock हो चुका है।';

  @override
  String get dcaPullRefresh =>
      'Refresh करने के लिए नीचे खींचें। Champion 6 AM पर lock होता है।';

  @override
  String get dcaLinkFailed => 'यह link नहीं खुल सका।';

  @override
  String get dcaReviseThisDayRec =>
      'इस दिन के current affairs आप हमारे सुझाए links से revise कर सकते हैं।';

  @override
  String get dcaAvailableSoon => 'जल्द उपलब्ध';

  @override
  String get dcaReviseThisTest => 'यह test revise करें';

  @override
  String get dcaStartTodays => 'आज का test शुरू करें';

  @override
  String get dcaStartTheTest => 'Test शुरू करें';

  @override
  String get dcaFavSources =>
      'इस दिन के current affairs के लिए ये हमारे पसंदीदा sources हैं।';

  @override
  String get dcaQuizNotOpen =>
      'आज का quiz अभी खुला नहीं है। 6 AM के बाद आइए, या नीचे से कोई पुराना दिन चुनिए।';

  @override
  String get dcaAlreadySubmitted =>
      'आप पहले ही submit कर चुके हैं। जवाब review करें या learning mode में revise करें।';

  @override
  String get dcaSameQuestions => 'सबके लिए वही सवाल — कल की खबरों पर आधारित।';

  @override
  String get dcaReviseLearning => 'Revise (learning)';

  @override
  String get dcaSignInLeaderboard => 'Leaderboard देखने के लिए sign in करें।';

  @override
  String get dcaEyebrowToday => 'आज';

  @override
  String get dcaEyebrowYesterday => 'कल';

  @override
  String get dcaLiveFirst => 'Live ranks · सबसे पहले पूरा कीजिए';

  @override
  String get dcaSeeAllRanks => 'सभी ranks देखें';

  @override
  String get dcaFinishToAppear => 'Board पर आने के लिए paper पूरा करें।';

  @override
  String get dcaTodayOpens => 'आज का test 6 AM पर खुलेगा';

  @override
  String get dcaTomorrowOpens => 'कल का test 6 AM पर खुलेगा';

  @override
  String get dcaGoesLive6 =>
      'कल की खबरों पर आधारित आज का current affairs test 6 AM पर live होगा।';

  @override
  String get dcaNoPaperToday => 'आज कोई paper नहीं है। अगला कल 6 AM पर आएगा।';

  @override
  String get dcaQuizDone =>
      'Quiz पूरा हुआ। कोई बात अटक रही हो तो explanations खोलिए।';

  @override
  String get dcaCaFromYesterday => 'कल की खबरों से current affairs test।';

  @override
  String get dcaReviseThisDay =>
      'इस दिन के current affairs आप इन links से revise कर सकते हैं।';

  @override
  String get dcaNotStartedYet => 'अभी शुरू नहीं';

  @override
  String get dcaViewResults => 'Results देखें';

  @override
  String get dcaReviseYesterdayRec =>
      'कल के current affairs आप हमारे सुझाए links से revise कर सकते हैं।';

  @override
  String get dcaReviseYesterday =>
      'कल के current affairs आप इन links से revise कर सकते हैं।';

  @override
  String get dcaTestWillBeFrom => 'आज का test इस दिन से होगा:\n';

  @override
  String get dwStarting => 'शुरू हो रहा है…';

  @override
  String dwStartsIn(String t) {
    return '$t में शुरू';
  }

  @override
  String get dwJoinNow => 'अभी join करें';

  @override
  String get dwSignInJoin => 'Join करने के लिए sign in करें';

  @override
  String get dwAttemptUnranked => 'Unranked attempt करें';

  @override
  String get dwSignInAttempt => 'Attempt करने के लिए sign in करें';

  @override
  String get dwLobbyOpen => 'LOBBY खुली है';

  @override
  String get dwInProgress => 'जारी है';

  @override
  String get dwSundayOff => 'रविवार की छुट्टी';

  @override
  String get dwOpenAttempt => 'अपना attempt खोलें';

  @override
  String get dwAspirantsInLobby => 'aspirants lobby में हैं';

  @override
  String get dwWritingNow => 'अभी लिख रहे हैं';

  @override
  String get dwLateJoinClosed => 'Late join बंद';

  @override
  String get dwPaperNotLoaded =>
      'आज रात का paper अभी load नहीं हुआ। थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get dwHistory => 'History';

  @override
  String dwTomorrowTopics(String topics) {
    return 'कल · $topics';
  }

  @override
  String get dwPractice => 'Practice';

  @override
  String dwNextEventMonday(String event) {
    return 'अगला $event सोमवार को 9:00 PM IST पर है।';
  }

  @override
  String dwEventLobbyOpen(String event) {
    return '$event की lobby खुली है।';
  }

  @override
  String dwEventIsLive(String event) {
    return '$event live है।';
  }

  @override
  String dwEventTonight(String event) {
    return '$event आज रात';
  }

  @override
  String dwSatEventStarts(String event) {
    return 'शनिवार का $event 9:00 PM IST पर शुरू होगा।';
  }

  @override
  String dwEventStarts(String event) {
    return '$event 9:00 PM IST पर शुरू होगा।';
  }

  @override
  String dwFooterTonight(String event) {
    return 'आज रात $event 9 PM पर शुरू होगा';
  }

  @override
  String dwFooterMonday(String event) {
    return 'सोमवार का $event 9 PM पर शुरू होगा';
  }

  @override
  String dwFooterNext(String event) {
    return 'अगला $event 9 PM पर शुरू होगा';
  }

  @override
  String dwRestDay(String event) {
    return 'Rest day · $event सोमवार 9 PM पर लौटेगा';
  }

  @override
  String dwWeekComplete(int n) {
    return 'Week $n पूरा';
  }

  @override
  String dwNightsOf(int a, int b) {
    return '$b में से $a रातें';
  }

  @override
  String dwTopicsWentBy(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n topics',
      one: '1 topic',
    );
    return 'इस हफ़्ते $_temp0 छूट गए · कुछ नहीं बिगड़ा, सोमवार से नई शुरुआत';
  }

  @override
  String dwTopicsLanded(int n) {
    return '$n topics कवर हुए';
  }

  @override
  String dwStillOpen(int n) {
    return ' · $n अभी बाकी';
  }

  @override
  String dwTonightTopics(String topics) {
    return 'आज रात: $topics';
  }

  @override
  String dwDailyDrillSubject(String subject) {
    return 'Daily Drill · $subject';
  }

  @override
  String dwHowWorks(String program) {
    return '$program कैसे काम करता है';
  }

  @override
  String dwHelpLiveBody(int wq, int wm, int gq, int gm, String event) {
    return 'वही paper, All-India · हफ़्ते की रातों में ${wq}Q / ${wm}m · शनि $event में ${gq}Q / ${gm}m';
  }

  @override
  String dwAirAt(String t) {
    return '$t पर AIR';
  }

  @override
  String dwHelpRhythmBody(String event) {
    return 'सोम–शुक्र 2 topics · शनि को $event · रविवार off';
  }

  @override
  String dwDrawsFromMany(int n) {
    return 'आज रात का war इन $n topics से है। अभी PYQs कर लें, ताकि आप तैयार होकर जाएँ।';
  }

  @override
  String dwYourWeekIn(String program) {
    return '$program में आपका हफ़्ता';
  }

  @override
  String dwUpRanks(int n) {
    return '$n ranks ऊपर';
  }

  @override
  String dwRanksLockAfter(String date) {
    return '$date · Paper बंद होने के बाद ranks lock होंगी';
  }

  @override
  String dwBadgesLoadFailed(String error) {
    return 'Badges load नहीं हो सके: $error';
  }

  @override
  String dwEventSaturday(String event) {
    return '$event · शनिवार';
  }

  @override
  String dwMoreSeeAll(int n) {
    return '+ $n और · सभी देखें →';
  }

  @override
  String dwTopicsCovered(int covered, int total) {
    return '$total में से $covered topics कवर';
  }

  @override
  String dwTonightAdds(int n) {
    return 'आज रात जुड़ेंगे $n';
  }

  @override
  String dwWarStartsIn(String t) {
    return 'WAR शुरू होने में $t';
  }

  @override
  String dwTimerStartsOnEntry(String t) {
    return 'आपका timer entry पर शुरू होता है — $t का close नहीं बदलता।';
  }

  @override
  String dwEntryClosesIn(String t) {
    return 'ENTRY बंद होने में $t';
  }

  @override
  String dwYourAirReady(int air) {
    return 'आपकी AIR $air तैयार है';
  }

  @override
  String dwTonightEventLive(String event) {
    return 'आज रात का $event live है';
  }

  @override
  String dwAspirantsTopics(String n, String topics) {
    return '$n aspirants · $topics';
  }

  @override
  String dwSeeYourAir(int air) {
    return 'अपनी AIR $air देखें';
  }

  @override
  String dwTonightsResult(String date) {
    return 'आज रात का RESULT · $date';
  }

  @override
  String dwAspirantsWroteIt(String n) {
    return '$n aspirants ने यह लिखा';
  }

  @override
  String dwPracticedUnranked(String score) {
    return 'आपने unranked practice की · $score';
  }

  @override
  String dwBadgesCount(int kinds, int earned) {
    return '$kinds badges · कुल $earned बार जीते';
  }

  @override
  String dwEventIsLiveCaps(String event) {
    return '$event LIVE है';
  }

  @override
  String dwNoLiveNext(String event) {
    return 'आज कोई live paper नहीं है। अगला $event सोमवार को 9:00 PM IST पर है।';
  }

  @override
  String dwPlusMore(int n) {
    return '+ $n और';
  }

  @override
  String dwSeeAllTopics(int n) {
    return 'सभी $n topics देखें →';
  }

  @override
  String dwJoinUntilLeft(String t) {
    return '9:10 तक join करें · $t बाकी';
  }

  @override
  String dwNoPaperNext(String event) {
    return 'आज कोई paper नहीं · अगला $event सोमवार 9:00 PM';
  }

  @override
  String dwLateClosedAirAt(String t) {
    return 'Late join बंद · $t पर AIR';
  }

  @override
  String dwStartFailed(String error) {
    return 'War शुरू नहीं हो सका: $error';
  }

  @override
  String dwLoadFailed(String error) {
    return 'Static War load नहीं हो सका: $error';
  }

  @override
  String dwPaperLoadFailed(String error) {
    return 'आज रात का paper load नहीं हो सका: $error';
  }

  @override
  String dwBattleStartsLeft(String t) {
    return 'Battle 9:00 PM IST पर शुरू होगी · $t बाकी।';
  }

  @override
  String dwRulesLobby(int q, int m) {
    return '$q Q · $m MIN · एक ही ATTEMPT';
  }

  @override
  String get dwNoLivePaper => 'आज कोई live paper नहीं है।';

  @override
  String get dwYouWereIn => 'आप आज रात के paper में थे।';

  @override
  String get dwOpenRankExpl => 'अपनी rank और explanations खोलें।';

  @override
  String get dwAttemptInResultsFollow =>
      'आपका attempt जमा हो गया। Results आगे आएँगे।';

  @override
  String get dwPaperStarts9 => 'Paper 9:00 PM IST पर शुरू होगा।';

  @override
  String get dwLiveNow => 'अभी LIVE';

  @override
  String get dwLiveJoinBefore =>
      'All-India live paper। Window बंद होने से पहले join करें।';

  @override
  String get dwEntryClosedRanks =>
      'Entry 9:10 PM IST पर बंद हुई। Ranks 9:40 PM पर।';

  @override
  String get dwWindowClosed => 'आज रात की live window बंद हो चुकी है।';

  @override
  String get dwStillUnranked =>
      'आप यह paper अब भी unranked attempt कर सकते हैं।';

  @override
  String get dwWeekRevision => 'Week revision। वही paper, All-India।';

  @override
  String get dwLobbyOpens859 =>
      'All-India live paper। Lobby 8:59 PM पर खुलेगी।';

  @override
  String get dwSundayNoBattle => 'रविवार · आज रात कोई Battle नहीं';

  @override
  String get dwQuietWeek => 'शांत हफ़्ता';

  @override
  String get dwNoBattleNights =>
      'इस हफ़्ते कोई battle night नहीं · सोमवार नई शुरुआत है';

  @override
  String get dwStreakSafe =>
      'Streak सुरक्षित · सोमवार तक revise करें या आराम करें';

  @override
  String get dwFullWeekSummary => 'पूरे हफ़्ते का summary';

  @override
  String get dwTopicsMonday => 'Topics सोमवार सुबह आएँगे';

  @override
  String get dwCatchUp => 'Catch up करें';

  @override
  String get dwReviseWeek => 'Week revise करें';

  @override
  String get dwPracticeEarly => 'जल्दी practice करें';

  @override
  String get dwUpNext => 'आगे';

  @override
  String get dwMonday9 => 'सोमवार · 9 PM';

  @override
  String get dwWeekStrip =>
      'सोम–शुक्र नए topics · शनि को हफ़्ते की revision · रविवार off';

  @override
  String get dwExplainerHead => 'पूरा syllabus।\nएक बार में दो topics।';

  @override
  String get dwExplainerSub =>
      '9 PM का live paper। सबके लिए वही सवाल। फिर आप leaderboard देखते हैं।';

  @override
  String get dwPaperIsTheseSat => 'शनिवार का paper ये हैं:';

  @override
  String get dwPaperIsThis => 'आज रात का paper यह है:';

  @override
  String get dwPaperIsThese => 'आज रात का paper ये हैं:';

  @override
  String get dwWeekTopicsLand => 'इस हफ़्ते के दो topics यहाँ आएँगे।';

  @override
  String get dwTonightTopicsLand => 'आज रात के दो topics यहाँ आएँगे।';

  @override
  String get dwTry10 => 'इन पर 10 सवाल आज़माएँ';

  @override
  String get dwQuick10 => 'आज रात के subject पर 10 quick MCQs';

  @override
  String get commonTryAgainError => 'कुछ गलत हो गया। कृपया फिर कोशिश करें।';

  @override
  String get dwStep2 => 'STEP 2 · तैयारी';

  @override
  String get dwHelpLiveTitle => '9:00 PM पर Live';

  @override
  String get dwHelpAirBody =>
      'Submit करते ही अपना score देखें · ranks तैयार होने पर हम आपको बताएँगे';

  @override
  String get dwHelpRhythmTitle => 'Week rhythm';

  @override
  String get dwHelpMissedTitle => 'एक रात छूट गई?';

  @override
  String get dwHelpMissedBody =>
      'बाद में practice करें · rank नहीं · streak टूटती है';

  @override
  String get dwReviseBefore9 => '9 PM से पहले Revise करें';

  @override
  String get dwDrawsFromOne =>
      'आज रात का war इसी topic से है। अभी PYQs कर लें, ताकि आप तैयार होकर जाएँ।';

  @override
  String get dwRevisionNoRank =>
      'यहाँ की revision आपकी war rank में नहीं गिनी जाती।';

  @override
  String get dwNoQuestionsTopic =>
      'इस topic के लिए अभी कोई सवाल उपलब्ध नहीं है।';

  @override
  String get dwStartPractice => 'Practice शुरू करें';

  @override
  String get dwNightsAttempted => 'रातें attempt कीं';

  @override
  String get dwConfidentlyWrong => 'Confidently गलत';

  @override
  String get dwConfWrongBody =>
      'वे topics जहाँ आपने Sure / Educated guess चुना और जवाब गलत निकला।';

  @override
  String get commonLoading => 'Load हो रहा है…';

  @override
  String get dwDangerLoadFailed => 'Danger topics load नहीं हो सके।';

  @override
  String get dwNoAttemptsWeek => 'इस हफ़्ते अभी कोई attempt नहीं।';

  @override
  String get dwNoneWeek => 'इस हफ़्ते कोई नहीं — यह map साफ़ रखिए।';

  @override
  String get dwBadgesEarned => 'Badges मिले';

  @override
  String get dwShowUpMonday => 'Badges जुटाना शुरू करने के लिए सोमवार को आइए।';

  @override
  String get dwNoBadgesWeek => 'इस हफ़्ते कोई badge नहीं।';

  @override
  String get dwNoBadgesNight => 'इस रात अभी कोई badge नहीं मिला।';

  @override
  String dwTiersNote(int days) {
    return 'Consistency tiers $days War nights में बढ़ते हैं। लगातार दो रातें छूटीं तो एक tier नीचे आ जाते हैं।';
  }

  @override
  String get dwTonight => 'आज रात';

  @override
  String get dwLastNight => 'कल रात';

  @override
  String get dwLastWar => 'पिछला WAR';

  @override
  String get dwSeeBoard => 'Board देखें';

  @override
  String get dwNoChampionYet =>
      'अभी कोई champion नहीं। Paper lock होने के बाद ranks यहाँ आएँगी।';

  @override
  String get dwEarnedBadges => 'मिले हुए BADGES';

  @override
  String get dwNoBadgeYet => 'आपने अभी तक कोई badge नहीं जीता';

  @override
  String get dwStarts9 => 'शुरू 9:00 PM IST';

  @override
  String get dwLobbyFilling => 'Lobby भर रही है';

  @override
  String get dwEnterLobby => 'Lobby में जाएँ';

  @override
  String get dwWarIsLive => 'WAR LIVE है';

  @override
  String get dwStarted9 => 'शुरू हुआ 9:00 PM IST';

  @override
  String get dwJoinUntil910 => 'आप 9:10 तक अब भी join कर सकते हैं';

  @override
  String get dwYoureIn => 'आप अंदर हैं';

  @override
  String get dwEntryClosed910 => 'ENTRY बंद 9:10 PM';

  @override
  String get dwAttemptInAir940 =>
      'आपका attempt जमा हो गया · AIR 9:40 PM IST पर';

  @override
  String get dwLateJoinClosedDot => 'Late join बंद हो गया।';

  @override
  String get dwEntryCloses910 => 'Entry 9:10 पर बंद होती है।';

  @override
  String get dwTodaysWarLive => 'आज का war live है';

  @override
  String get dwResultsEyebrow => 'RESULTS';

  @override
  String get dwAirAt940 => 'AIR 9:40 PM पर';

  @override
  String get dwScoreInNotify =>
      'आपका score आ गया · AIR तैयार होने पर हम बताएँगे';

  @override
  String get dwBattleOverAir => 'आज रात की battle ख़त्म · AIR 9:40 PM पर';

  @override
  String get dwFullResults => 'पूरे results और review';

  @override
  String get dwBattleOverCaps => 'आज रात की BATTLE ख़त्म';

  @override
  String get dwSatOut => 'आपने यह रात छोड़ दी';

  @override
  String get dwAttemptInPending => 'आपका attempt जमा हो गया · rank बाकी';

  @override
  String get dwSeeTonightsPaper => 'आज रात का paper देखें';

  @override
  String get dwUnrankedAttempt => 'Unranked attempt';

  @override
  String get dwSeeYourAttempt => 'अपना attempt देखें';

  @override
  String get dwTomorrow9 => 'कल · 9:00 PM IST';

  @override
  String get dwNoQuestionsAvail => 'कोई सवाल उपलब्ध नहीं';

  @override
  String get dwStaticWarRevise => 'Static War revise';

  @override
  String get dwTonightsLeaderboard => 'आज रात का war · leaderboard';

  @override
  String get dwLeaderboardNotReady => 'Leaderboard अभी तैयार नहीं है।';

  @override
  String get dwBadgesSyncNote =>
      'Counts आपकी Static War nights से sync होते हैं — इस device और cloud दोनों में रहते हैं।';

  @override
  String get dwResultsTitle => 'Static War results';

  @override
  String get dwSubmitting => 'आपके जवाब submit हो रहे हैं…';

  @override
  String get dwDemoted =>
      'आपका paper live window बंद होने के बाद आया, इसलिए इसे unranked attempt के रूप में save किया गया है।';

  @override
  String get dwUnrankedNotOfficial => 'Unranked · official AIR नहीं';

  @override
  String get dwSubmittedAirReady =>
      'Submit हो गया · AIR 9:40 PM IST पर तैयार होगी। हम आपको बताएँगे।';

  @override
  String get dwTomorrow => 'कल';

  @override
  String get dwTonightsLeaderboardBtn => 'आज रात का leaderboard';

  @override
  String get dwNotAvailable => 'Static War उपलब्ध नहीं है।';

  @override
  String get dwNotAvailableAccount =>
      'इस account पर Static War अभी उपलब्ध नहीं है।';

  @override
  String get dwSundayOffTitle => 'रविवार की छुट्टी';

  @override
  String get dwPracticeTopics => 'इन topics की practice करें →';

  @override
  String get dwOpenHistory => 'History खोलें';

  @override
  String get dwCantJoinNow => 'आप अभी join नहीं कर सकते';

  @override
  String get dwComeBack859 => 'Lobby में आने के लिए 8:59 PM IST पर लौटिए।';

  @override
  String get dwResultsReady => 'RESULTS तैयार';

  @override
  String get dwPrepareToday => 'आज तैयारी करें · lobby 8:59 PM पर खुलेगी';

  @override
  String get dwRanksCalculating => 'Ranks calculate हो रही हैं…';

  @override
  String get dwResultsReadyTitle => 'Results तैयार';

  @override
  String get dwReady => 'तैयार';

  @override
  String get dwHistoryCaps => 'HISTORY';

  @override
  String get dwSignInAttemptWar =>
      'इस War को attempt करने के लिए sign in करें।';

  @override
  String get dwSignInJoinWar =>
      'आज रात के War में join करने के लिए sign in करें।';

  @override
  String get dwAlreadySubmitted => 'आप इस War को पहले ही submit कर चुके हैं।';

  @override
  String get dwAlreadyPracticed => 'आप इस War की practice पहले ही कर चुके हैं।';

  @override
  String get dwUpdateApp =>
      'आज रात का War attempt करने के लिए ऐप update करें — इस paper के कुछ सवाल आपके question bank में अभी नहीं हैं।';

  @override
  String get dwTopicsLoadFailed => 'आज रात के topics load नहीं हुए';

  @override
  String get dwTopicsFinding => 'आज रात के topics खोजे जा रहे हैं…';

  @override
  String get dwTwoTopics => 'हर रात दो topics';

  @override
  String get dwPaperOpenRanksTomorrow =>
      'आज रात का paper खुला है। Ranks कल यहाँ दिखेंगी।';

  @override
  String dwLateClosedUnrankedAt(String t) {
    return 'Late join बंद · unranked $t पर';
  }

  @override
  String dwWarriorsThatNight(String n) {
    return 'उस रात $n warriors';
  }

  @override
  String dwAirLabel(int air) {
    return 'AIR $air';
  }

  @override
  String dwBetterThan(String pct) {
    return '$pct% warriors से आगे';
  }

  @override
  String dwPts(String score) {
    return '$score pts';
  }

  @override
  String dwTopNOf(int n, int count) {
    return '$count में से Top $n';
  }

  @override
  String dwSeeAllCount(int count) {
    return 'सभी $count देखें';
  }

  @override
  String get dwSavedOnDevice => 'इस device पर save है';

  @override
  String get dwPaperNotPublished => 'Paper अभी publish नहीं हुआ';

  @override
  String get dwStartDayTest => 'इस दिन का test शुरू करें';

  @override
  String get dwReviseThisPaper => 'यह paper revise करें';

  @override
  String get dwLeaderboardCaps => 'LEADERBOARD';

  @override
  String get dwArchiveTitle => 'Static War archive';

  @override
  String get dwYourAttemptCaps => 'आपका ATTEMPT';

  @override
  String get dwNotAttempted => 'Attempt नहीं किया';

  @override
  String get dwStartAboveToTake =>
      'यह paper देने के लिए ऊपर से test शुरू करें।';

  @override
  String get dwPendingRank => 'Rank बाकी';

  @override
  String get dwSkip => 'Skip';

  @override
  String get dwNoRankedFinishers => 'अभी कोई ranked finisher नहीं';

  @override
  String get dwRanksLandAfter =>
      'Paper बंद होने के बाद ranks आएँगी · All-India board यहाँ भरेगा';

  @override
  String get dwLeaderboardTitle => 'Leaderboard';

  @override
  String get ocPleaseNote => 'ध्यान दीजिए:';

  @override
  String ocTooltipLine(String eta) {
    return '24 घंटे में एक live challenge · अगला slot ~$eta';
  }

  @override
  String ocBodyCopy(String eta) {
    return 'आपका एक challenge पहले से live है। अगला ~$eta में बना सकेंगे।';
  }

  @override
  String ocPickCopy(String eta) {
    return 'अभी cooldown चल रहा है — अगला ~$eta में बना सकेंगे।';
  }

  @override
  String qotdSubjectsFailed(String error) {
    return 'Subjects load नहीं हो सके: $error';
  }

  @override
  String ocPickSubtitle(int n) {
    return 'एक subject या mixed misc चुनें · 10 MCQs · Timed ($n मिनट)';
  }

  @override
  String get ocAlreadyAttempted =>
      'आप यह challenge पहले ही attempt कर चुके हैं।';

  @override
  String get ocExpired => 'यह challenge expire हो चुका है।';

  @override
  String get ocSignInSave =>
      'अपना score leaderboard पर save करने के लिए sign in करें।';

  @override
  String get ocSaveFailed => 'आपका score save नहीं हो सका';

  @override
  String get commonCheckConnection =>
      'अपना connection जाँचें और फिर कोशिश करें।';

  @override
  String get ocPublishingScore => 'आपका score publish हो रहा है';

  @override
  String get ocLocking =>
      'आपके जवाब leaderboard पर lock हो रहे हैं — बस थोड़ा और।';

  @override
  String get ocRule1 =>
      'आप exam mode में 10 सवाल हल करेंगे — कोई hint नहीं, कोई explanation नहीं।';

  @override
  String get ocRule2 => 'आपका score आपके नाम के साथ सबके सामने post होगा।';

  @override
  String get ocRule3 => 'हर challenge सिर्फ़ एक बार attempt कर सकते हैं।';

  @override
  String get ocRule4 =>
      'Score बराबर होने पर जिसने पहले attempt किया, वह आगे रहेगा।';

  @override
  String get ocBeforeStart => 'शुरू करने से पहले';

  @override
  String get ocConfidenceNote =>
      'Option चुनते समय confidence level mark करना optional है, पर बेहतर insights के लिए हम इसकी सलाह देते हैं।';

  @override
  String get ocAMoment => 'कुछ पल';

  @override
  String get qotdNoQuestions => 'इस subject के लिए कोई सवाल नहीं मिला।';

  @override
  String get qotdLoadFailed => 'वह सवाल load नहीं हो सका।';

  @override
  String get qotdPickFirst => 'पहले subject चुनिए।';

  @override
  String get ocPickSubject => 'अपना subject चुनिए';

  @override
  String get qotdIntro =>
      'आपके bank से एक random सवाल · shuffle करें, attempt करें, फिर Community QOTD में post करें।';

  @override
  String get commonSubject => 'Subject';

  @override
  String get qotdContinue => 'सवाल पर आगे बढ़ें';

  @override
  String get qotdNoneLoaded => 'कोई सवाल load नहीं हुआ।';

  @override
  String get qotdShuffle => 'सवाल shuffle करें';

  @override
  String get qotdReadExpl => 'Explanation पढ़ें';

  @override
  String get qotdPostThis => 'यह सवाल post करें';

  @override
  String get qotdTabIntro =>
      'Community के साथ कोई मुश्किल सवाल share करें। Card पर tap करके खोलें, react करें और attempt करें।';

  @override
  String get qotdFeedFailed => 'QOTD feed load नहीं हो सकी';

  @override
  String get qotdEmpty =>
      'अभी कोई सवाल share नहीं हुआ। Refresh करने के लिए नीचे खींचें, या Create दबाकर एक post करें (जैसे test में कोई सवाल attempt करने के बाद)।';

  @override
  String get ocCreateChallenge => 'Challenge बनाएँ';

  @override
  String get ocPickNote =>
      'इस subject के लिए आपके local bank से दस सवाल random चुने जाते हैं। Challenge के दौरान timer चलता है।';

  @override
  String get ocSubjectsFailed => 'Subjects load नहीं हो सके';

  @override
  String get ocStartMyAttempt => 'मेरा challenge attempt शुरू करें';

  @override
  String get ocBeginTimed => 'Timed 10-MCQ challenge शुरू करें';

  @override
  String get commonJustNow => 'अभी-अभी ✨';

  @override
  String commonMinAgo(int n) {
    return '$n मिनट पहले';
  }

  @override
  String commonHrAgo(int n) {
    return '$n घंटे पहले';
  }

  @override
  String commonDayAgo(int n) {
    return '$n दिन पहले';
  }

  @override
  String commonWeekAgo(int n) {
    return '$n हफ़्ते पहले';
  }

  @override
  String blockedUnblocked(String name) {
    return '$name को unblock कर दिया गया।';
  }

  @override
  String blockedUnblockFailed(String error) {
    return 'Unblock नहीं हो सका: $error';
  }

  @override
  String connectChallengeUser(String target) {
    return '$target को battle में challenge करें।';
  }

  @override
  String ocCreatedBy(String name) {
    return '$name ने बनाया';
  }

  @override
  String ocLiveTill(String t) {
    return '$t तक live';
  }

  @override
  String ocYourScore(int s) {
    return 'आपका score: $s / 10';
  }

  @override
  String ocBeatenBy(String name) {
    return '$name ने आपका score पीछे छोड़ दिया';
  }

  @override
  String ocCreatedMin(int n) {
    return '$n मिनट पहले बनाया';
  }

  @override
  String ocCreatedHr(int n) {
    return '$n घंटे पहले बनाया';
  }

  @override
  String ocCreatedDay(int n) {
    return '$n दिन पहले बनाया';
  }

  @override
  String commLastRefreshed(String t) {
    return 'आख़िरी refresh: $t';
  }

  @override
  String commKeepProfile(String app) {
    return 'अपनी profile updated रखें, ताकि दूसरे $app के बाहर भी आपसे जुड़ सकें।';
  }

  @override
  String qotdMinChars(int n) {
    return 'कम से कम $n अक्षर लिखें, या इसे खाली छोड़ दें।';
  }

  @override
  String qotdMaxChars(int n) {
    return 'कृपया इसे $n अक्षरों के अंदर रखें।';
  }

  @override
  String qotdMoreChars(int n, int need) {
    return '$need तक पहुँचने के लिए $n और अक्षर चाहिए, या comment के बिना post करने के लिए field खाली कर दें।';
  }

  @override
  String ocGreatScore(int n) {
    return 'बढ़िया score ($n/10)। इस set को open challenge के रूप में post करें, ताकि दूसरे Community में वही सवाल आज़मा सकें।';
  }

  @override
  String ocByName(String name) {
    return '$name द्वारा';
  }

  @override
  String ocTries(int count) {
    return '$count try';
  }

  @override
  String ocYouScore(int n) {
    return 'आप $n/10';
  }

  @override
  String commBlockedMsg(String name) {
    return 'आपको $name के messages या battle invites नहीं दिखेंगे।';
  }

  @override
  String commBlockUpdateFailed(String error) {
    return 'Block update नहीं हो सका: $error';
  }

  @override
  String commChatStartFailed(String error) {
    return 'Chat शुरू नहीं हो सकी: $error';
  }

  @override
  String commLastOnline(String t) {
    return 'आख़िरी बार online: $t';
  }

  @override
  String get blockedNone => 'किसी को block नहीं किया';

  @override
  String get blockedNote =>
      'जिन्हें आप block करेंगे, वे आपको message या battle invite नहीं भेज पाएँगे।';

  @override
  String get blockedUnblock => 'Unblock';

  @override
  String get connectRandomIntro => 'Random battle connect शुरू करें।';

  @override
  String get connectStartChallenge => 'Challenge शुरू करें';

  @override
  String get connectNote =>
      'आपको कुछ देर joined players दिखेंगे, फिर battle अपने-आप शुरू हो जाएगी।';

  @override
  String get ocNotFound => 'Challenge नहीं मिला';

  @override
  String get ocExpired24 =>
      'यह challenge expire हो चुका है (challenge 24 घंटे चलते हैं)।';

  @override
  String get ocWinnerSoFar => 'अब तक आप ही winner हैं 🏆';

  @override
  String get ocReviewExpl => 'Explanations review करें';

  @override
  String get ocAccept => 'Challenge accept करें';

  @override
  String get ocCreatedJustNow => 'अभी बनाया';

  @override
  String get commRecentFailed => 'Recent users load नहीं हो सके';

  @override
  String get commTapUser =>
      'Profile और social links देखने के लिए किसी user पर tap करें।';

  @override
  String get commNoUsers => 'ताज़ा window में कोई user नहीं मिला।';

  @override
  String get commPullRefresh => 'Refresh करने के लिए नीचे खींचें।';

  @override
  String get commLoadingRecent => 'Recent users load हो रहे हैं…';

  @override
  String get commSetVisibility => 'Visibility set करें';

  @override
  String get commAcceptInvites => 'Battle invites स्वीकार करें';

  @override
  String get commReceivingInvites => 'आपको battle invites मिल रहे हैं।';

  @override
  String get commNotReceivingInvites => 'आपको battle invites नहीं मिल रहे।';

  @override
  String get commShowBattleStatus => 'मेरा in-battle status दिखाएँ';

  @override
  String get commOthersCanSee =>
      'जब आप battle में होते हैं, दूसरे देख सकते हैं।';

  @override
  String get commOthersCannotSee =>
      'दूसरे आपका in-battle status नहीं देख सकते।';

  @override
  String get commSaveFailed => 'Settings save नहीं हो सकीं';

  @override
  String get commonSave => 'Save करें';

  @override
  String get commTapRandom => 'Random Battle Connect के लिए नीचे tap करें';

  @override
  String get qotdNoteIntro =>
      'Community के लिए optional note। कुछ नया सीखा? कुछ अजीब दिखा? किसी concept ने चुनौती दी? साफ़ लिखें — या खाली छोड़ दें।';

  @override
  String get qotdCommentLabel => 'Comment (optional)';

  @override
  String qotdCommentHint(int n) {
    return 'खाली छोड़ें, या कम से कम $n अक्षर लिखें…';
  }

  @override
  String get qotdSignInKept =>
      'Post करने के लिए sign in करें। आपका comment सुरक्षित रहेगा।';

  @override
  String get qotdPost => 'Post करें';

  @override
  String get qotdSignInPost => 'Post करने के लिए sign in करें';

  @override
  String get ocShareChallenge => 'Challenge share करें';

  @override
  String get ocPublishCommunity => 'Community में publish करें';

  @override
  String get ocTempUnavailable => 'अभी उपलब्ध नहीं';

  @override
  String get ocPosting => 'Post हो रहा है…';

  @override
  String get ocPostAsChallenge => 'Open challenge के रूप में post करें';

  @override
  String get qotdRule1 =>
      'हर QOTD आपके post करने के बाद 24 घंटे तक Community में रहता है।';

  @override
  String get qotdRule2 =>
      'आपके चुने subject के लिए आपके offline catalog से एक random MCQ आता है।';

  @override
  String get qotdRule3 =>
      'जब तक कोई share करने लायक सवाल न मिले, shuffle करते रहें; फिर उसे attempt करें।';

  @override
  String get qotdRule4 =>
      'आप attempt करने के बाद post करते हैं; आपका pick community post के साथ save होता है।';

  @override
  String get qotdRule5 =>
      'आपका नाम और एक optional छोटा comment QOTD card पर दिखता है।';

  @override
  String get qotdBeforeProceed => 'आगे बढ़ने से पहले';

  @override
  String get qotdWhoAnswered => 'किसने जवाब दिया';

  @override
  String get qotdAttemptsFailed => 'Attempts load नहीं हो सके।';

  @override
  String get qotdNoAttempts => 'अभी कोई attempt नहीं।';

  @override
  String get qotdProfileUnavailable =>
      'इस attempt की profile अभी उपलब्ध नहीं है।';

  @override
  String get qotdWhatIs => 'QOTD क्या है?';

  @override
  String get qotdWhat1 => 'अपने test का कोई सवाल community के साथ share करें।';

  @override
  String get qotdWhat2 => 'दूसरे उसे attempt करते हैं और react करते हैं।';

  @override
  String get qotdWhat3 => 'यह 24 घंटे तक live रहता है।';

  @override
  String get ocPublishingChallenge => 'आपका challenge publish हो रहा है…';

  @override
  String get ocStepFailed =>
      'यह step पूरा नहीं हो सका। अपना connection जाँचें और फिर कोशिश करें।';

  @override
  String get ocWhatIs => 'Open challenge क्या है?';

  @override
  String get ocWhat1 =>
      'कोई warrior अपना 10 सवालों का exam सबके लिए post करता है।';

  @override
  String get ocWhat2 => 'हर challenger के लिए वही 10 सवाल।';

  @override
  String get ocWhat3 => 'Leaderboard का top score पीछे छोड़ें।';

  @override
  String get ocWhat4 => 'हर challenge 24 घंटे तक live रहता है।';

  @override
  String get ocWhatSignIn =>
      'Challenge में शामिल होने और अपना challenge post करने के लिए sign in करें।';

  @override
  String get commonNotNow => 'अभी नहीं';

  @override
  String get qotdPosted => 'Community QOTD में post हो गया';

  @override
  String get ocSectionIntro =>
      'वही 10 सवाल — सबको पीछे छोड़ें! पूरी कहानी के लिए card पर tap करें।';

  @override
  String get ocStartNew => 'नया 10-सवाल का challenge शुरू करें';

  @override
  String get ocLoadFailed => 'Challenges load नहीं हो सके';

  @override
  String get ocNoneYet => 'अभी कोई challenge नहीं — आप पहले बन सकते हैं!';

  @override
  String get ocCrushIntro =>
      '10 सवालों का exam हल करें, फिर Create दबाकर सबके लिए challenge डालें।';

  @override
  String get ocWhatIsShort => 'Open challenge क्या है';

  @override
  String get ocPickedForYou => 'आपके लिए चुना गया';

  @override
  String get commLinkFailed => 'Link नहीं खुल सका';

  @override
  String get commFighting => 'battle लड़ रहे हैं';

  @override
  String get commAvailable => 'उपलब्ध';

  @override
  String get commBlockTitle => 'इस user को block करें?';

  @override
  String get commBlockBody =>
      'इससे यह chat बंद हो जाएगी और उन्हें block कर दिया जाएगा।';

  @override
  String get commSignInMsg => 'Message भेजने के लिए sign in करें।';

  @override
  String get commChatStartSignIn =>
      'Chat शुरू नहीं हो सकी। कृपया फिर से sign in करें।';

  @override
  String get commSendMessage => 'Message भेजें';

  @override
  String get commThatsAll => 'बस इतना ही';

  @override
  String bcSubInvite(String name, int mins) {
    return '$name के साथ Battle · 10 MCQs · Timed ($mins min)';
  }

  @override
  String bcSubPick(int mins) {
    return 'एक subject या mixed misc चुनें · 10 MCQs · Timed ($mins min)';
  }

  @override
  String bcErrSetup(String code) {
    return 'Battle setup नहीं हो सका ($code)।';
  }

  @override
  String bwJoinWindow(String window, String remaining) {
    return 'अगर आपका opponent $window के अंदर join करता है, तो आप battle शुरू कर सकते हैं। बचा हुआ time: $remaining।';
  }

  @override
  String bsoSubmitted(String name) {
    return '$name ने submit कर दिया; unanswered questions खाली रहेंगे।';
  }

  @override
  String bsoLockedAll(String name) {
    return '$name ने हर answer lock कर दिया है।';
  }

  @override
  String bsoStillWorking(String name) {
    return '$name अभी paper हल कर रहा है।';
  }

  @override
  String bsoCloseBody(String name) {
    return '$name अभी answer कर रहा है। फिर भी live duel बंद करें?';
  }

  @override
  String bsoLeaveBody(String name) {
    return '$name अभी answer कर रहा है। क्या आप देखना बंद करना चाहते हैं?';
  }

  @override
  String get bjSignIn => 'इस battle में join करने के लिए sign in करें।';

  @override
  String get bjNotFound => 'यह battle नहीं मिली। शायद expire हो गई हो।';

  @override
  String get bjNotPvp => 'यह link player-vs-player battle के लिए नहीं है।';

  @override
  String get bjWrongAccount => 'यह invite किसी दूसरे account को भेजा गया था।';

  @override
  String get bjClosed =>
      'इस battle में अब join नहीं हो सकता। शायद यह शुरू हो चुकी है।';

  @override
  String get bjIncomplete => 'Battle का data अधूरा है।';

  @override
  String get bjJoinFailed => 'Battle join नहीं हो सकी।';

  @override
  String get bjTitle => 'Battle join करें';

  @override
  String get bjSomethingWrong => 'कुछ गड़बड़ हो गई।';

  @override
  String get commonHome => 'Home';

  @override
  String get brTitle => 'Battle Result';

  @override
  String get commonBackToHome => 'Home पर वापस जाएँ';

  @override
  String get bcTitle => 'Battle configure करें';

  @override
  String get bcPick => 'अपना battlefield चुनें';

  @override
  String get bcMisc => 'Misc';

  @override
  String get bcTimerNote =>
      'Battle के दौरान timer चलता रहता है। Answer चुनते ही lock हो जाता है, और explanations दिखती हैं ताकि आप साथ-साथ सीखें।';

  @override
  String get bcLoadFailed => 'Subjects load नहीं हो सके';

  @override
  String get bcUnblockFirst =>
      'Invite करने से पहले Community में इस player को unblock करें।';

  @override
  String get bcErrPermission =>
      'Battle room save नहीं हो सका। Sign in करके फिर कोशिश करें।';

  @override
  String get bcErrUnavailable =>
      'Service अभी उपलब्ध नहीं है। Connection check करके फिर कोशिश करें।';

  @override
  String get bcErrTimeout =>
      'Battle save करने में time out हो गया। Internet check करके फिर कोशिश करें।';

  @override
  String get bwLeaveTitle => 'Match छोड़ें?';

  @override
  String get bwLeaveBody =>
      'आपका opponent शायद अब भी lobby में इंतज़ार कर रहा है।';

  @override
  String get bwStay => 'रुकें';

  @override
  String get bwStartFailed => 'Battle शुरू नहीं हो सकी। फिर कोशिश करें।';

  @override
  String get bwMatch => 'Match';

  @override
  String get bwBattleId => 'Battle ID';

  @override
  String get bw2Joined => '2 joined';

  @override
  String get commonYou => 'आप';

  @override
  String get bwStartingSoon =>
      'थोड़ा रुकें… battle कुछ ही seconds में शुरू होगी।';

  @override
  String get bwOppJoined =>
      'Opponent join हो गया। तैयार हों तो battle शुरू करें।';

  @override
  String get bwWaitOppJoin =>
      'Opponent के invite खोलकर join करने का इंतज़ार है।';

  @override
  String get bwStarting => 'Battle शुरू हो रही है…';

  @override
  String get bwWaitHost => 'Host के battle शुरू करने का इंतज़ार है।';

  @override
  String get bwOppInLobby => 'Opponent lobby में है';

  @override
  String get bwWaitOpp => 'Opponent का इंतज़ार';

  @override
  String get bwTimedOut =>
      'Opponent के join करने का इंतज़ार करते-करते time out हो गया। अगर वे धीमे हैं तो आप इंतज़ार जारी रख सकते हैं, या वापस जा सकते हैं।';

  @override
  String get commonGoBack => 'वापस जाएँ';

  @override
  String get bwKeepWaiting => 'इंतज़ार करें';

  @override
  String get bshScores => 'Scores';

  @override
  String get bshFinished => 'Battle खत्म';

  @override
  String get bsnTitle => 'Answers submit करें?';

  @override
  String get bsnBodyWatch =>
      'आपका score lock हो जाएगा। आप live board पर opponent को finish करते देख सकते हैं, या सीधे results पर जा सकते हैं।';

  @override
  String get bsnBodyPlain => 'आपका score lock हो जाएगा और आपको नतीजा दिखेगा।';

  @override
  String get bsnContinue => 'Battle जारी रखें';

  @override
  String get bsnWatch => 'Submit करें और उनकी progress देखें';

  @override
  String get bsnSeeResults => 'Submit करें और results देखें';

  @override
  String get bsoYourOpp => 'आपका opponent';

  @override
  String get bsoTie => 'Points पर tie।';

  @override
  String get bsoYouAhead => 'आप points में आगे थे।';

  @override
  String get bsoOppAhead => 'आपका opponent points में आगे था।';

  @override
  String get bsoYouAheadNow => 'आप points में आगे हैं (अभी के लिए)।';

  @override
  String get bsoOppAheadNow => 'आपका opponent points में आगे है (अभी के लिए)।';

  @override
  String get bsoClose => 'Scores बहुत करीब हैं।';

  @override
  String get bsoTimerEnded =>
      'Timer window खत्म हो गई; room में अब live marks नहीं जुड़ेंगे।';

  @override
  String get bsoCloseTitle => 'Live duel बंद करें?';

  @override
  String get bsoStop => 'रोकें';

  @override
  String get bsoLeaveTitle => 'Live board छोड़ें?';

  @override
  String get bsoKeepWatching => 'देखते रहें';

  @override
  String get bsoBattleOver => 'Battle खत्म';

  @override
  String get bsoLiveDuel => 'Live duel';

  @override
  String get bsoStopFollowing => 'Follow करना बंद करें';

  @override
  String get bsoClosePanel => 'Panel बंद करें';

  @override
  String bcfSendFailed(String error) {
    return 'Send नहीं हो सका: $error';
  }

  @override
  String bcfLoadFailed(String error) {
    return 'Messages load नहीं हो सके: $error';
  }

  @override
  String bsbAcc(int pct, int correct, int wrong) {
    return '$pct% accuracy · $correct सही, $wrong गलत';
  }

  @override
  String bsbAccUn(int pct, int correct, int wrong, int un) {
    return '$pct% accuracy · $correct सही, $wrong गलत, $un unanswered';
  }

  @override
  String bsbAheadBy(String delta) {
    return 'आप $delta points से आगे थे';
  }

  @override
  String bsbLedBy(String delta) {
    return 'वे $delta points से आगे थे';
  }

  @override
  String get btOpenFailed => 'Battle खुल नहीं सकी।';

  @override
  String get btLeaveTitle => 'Battle छोड़ें?';

  @override
  String get btLeaveBody =>
      'वापस जाने का मतलब है कि आप battle छोड़ रहे हैं, लेकिन आपकी progress save रहेगी।';

  @override
  String get btGridTooltip => 'Question grid';

  @override
  String get btWaitJoin =>
      'Answer करने से पहले opponent के join करने का इंतज़ार है।';

  @override
  String get btRevisit => 'बाद में देखें';

  @override
  String get btSubmitFailed =>
      'Battle submit नहीं हो सकी। कृपया फिर कोशिश करें।';

  @override
  String get btGridTitle => 'Question Grid';

  @override
  String get btAnswer => 'Answer';

  @override
  String get bcfCloseTitle => 'Chat बंद करें?';

  @override
  String get bcfCloseBody => 'क्या आप इस battle chat को छिपाना चाहते हैं?';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get bcfStartConv => 'बातचीत शुरू करें।';

  @override
  String get bcfHint => 'Message लिखें';

  @override
  String get commonOpponent => 'Opponent';

  @override
  String get bsbNoAttempts => 'कोई scored attempt नहीं';

  @override
  String get bsbYouCaps => 'आप';

  @override
  String get bsbTieTitle => 'कांटे की टक्कर!';

  @override
  String get bsbTieSub => 'Tie हो गया। क्या मुकाबला था!';

  @override
  String get bsbLoseTitle => 'बस थोड़ा सा चूके!';

  @override
  String get bsbLoseSub => 'इस बार हार गए। और मज़बूत होकर लौटिए।';

  @override
  String get bsbTiedPoints => 'Points पर scores बराबर हैं।';

  @override
  String get bsbVictory => 'Victory unlocked!';

  @override
  String get bsbOutplayed => 'इस round में आपने opponent को पीछे छोड़ दिया।';

  @override
  String get bsbStacked => 'आपका प्रदर्शन';

  @override
  String get bsbTiePts => 'Points पर tie';

  @override
  String get bspWaitJoin => 'Opponent के join करने का इंतज़ार है…';

  @override
  String get bspRecordFailed => 'आपका answer record नहीं हो सका।';

  @override
  String get bspSubmitFailed => 'Battle submit नहीं हो सकी।';

  @override
  String get bspPermDenied => 'Battle की permission नहीं मिली।';

  @override
  String get bspNetwork =>
      'Network उपलब्ध नहीं है। Internet check करके फिर कोशिश करें।';

  @override
  String get bspStartFailed =>
      'Online battle शुरू नहीं हो सकी। कृपया फिर कोशिश करें।';

  @override
  String get bicSent => 'Battle invite भेज दिया गया।';

  @override
  String get bicNoToken =>
      'Invitee का push token अभी नहीं है। वे session link से अब भी join कर सकते हैं।';

  @override
  String get bicPushFailed =>
      'Push नहीं भेजा जा सका। वे session link से अब भी join कर सकते हैं।';

  @override
  String get bicUnclear =>
      'Invite का status साफ़ नहीं है। कृपया बाद में फिर कोशिश करें।';

  @override
  String gmSetTitle(String subject, int n, int total) {
    return '$subject · Set $n/$total';
  }

  @override
  String gmCorrectOfTotal(int correct, int total) {
    return '$total में से $correct सही';
  }

  @override
  String gmOddTitle(String subject) {
    return 'Odd One Out · $subject';
  }

  @override
  String gmNOfTotal(int n, int total) {
    return '$total में से $n';
  }

  @override
  String gmFobStep2(int seconds) {
    return 'आपके पास $seconds seconds हैं।';
  }

  @override
  String gmSubjNOfTotal(String subject, int n, int total) {
    return '$subject · $total में से $n';
  }

  @override
  String gmDuelYouWin(String name) {
    return '$name, आप जीते';
  }

  @override
  String gmDuelWins(String name) {
    return '$name जीते';
  }

  @override
  String get gmDescMemory =>
      'Terms को answers से मिलाएँ — recall की practice करें।';

  @override
  String get gmDescTimeline => 'Events को सही क्रम में लगाएँ।';

  @override
  String get gmOddStep2 => 'बेमेल (odd one out) को चुनें।';

  @override
  String get gmDescFob => 'दस seconds। अपने अंदाज़े पर भरोसा करें।';

  @override
  String get gmDescCtd => 'छिपा हुआ link ढूँढें।';

  @override
  String get gmDescDuel => 'एक phone, दो players — जो तेज़, वही जीतेगा।';

  @override
  String gmStartN(int n) {
    return 'शुरू करें · $n सवाल';
  }

  @override
  String get gmTlStep1 => 'Set के shuffled events पढ़ें।';

  @override
  String get gmTlStep2 => 'Rows को hold करके drag करें और सही क्रम में लगाएँ।';

  @override
  String get gmTlStep3 =>
      'Check पर tap करें — years और आपके सही जवाब दिख जाएँगे।';

  @override
  String get gmNextSet => 'अगला set →';

  @override
  String get gmCheck => 'Check';

  @override
  String get gmNoContent => 'कोई content नहीं';

  @override
  String get gmTlHint => 'Hold करके drag करें और क्रम बदलें, फिर check करें।';

  @override
  String get gmErrNoTimeline => 'कोई timeline set नहीं मिला।';

  @override
  String get gmOddStep1 => 'चारों options को देखें।';

  @override
  String get gmOddStep3 => 'Highlight और explanation तुरंत देखें।';

  @override
  String get gmNext => 'अगला →';

  @override
  String get gmErrNoOdd => 'कोई odd-one-out item नहीं मिला।';

  @override
  String get gmFobStep1 => 'Statement को जल्दी पढ़ें।';

  @override
  String get gmFobStep3 => 'Time खत्म होने से पहले FACT या BLUFF पर tap करें।';

  @override
  String get gmGotIt => 'सही पकड़ा!';

  @override
  String get gmNotThisTime => 'इस बार नहीं';

  @override
  String get gmTooSlow => 'बहुत धीमे';

  @override
  String get gmErrNoFob => 'कोई fact-or-bluff item नहीं मिला।';

  @override
  String get gmCtdStep1 => 'तीनों clues को साथ में पढ़ें।';

  @override
  String get gmCtdStep2 => 'सोचें कि इन्हें क्या जोड़ता है।';

  @override
  String get gmCtdStep3 => 'जो option इन्हें जोड़ता है, उस पर tap करें।';

  @override
  String get gmCtdHidden => 'छिपा हुआ link क्या है?';

  @override
  String get gmErrNoCtd => 'कोई connect-the-dots item नहीं मिला।';

  @override
  String get gmDuelStart => 'Match शुरू करें';

  @override
  String get gmDuelStep1 => 'Phone को अपने बीच table पर सीधा रख दें।';

  @override
  String get gmDuelStep2 =>
      'सवाल वही, हर player के 2 options — ऊपर और नीचे आमने-सामने।';

  @override
  String get gmDuelStep3 =>
      'पहले दोनों चुनें (या pass करें) — सही answer तभी दिखेगा जब दोनों lock कर दें।';

  @override
  String get gmDuelNoQ => 'कोई सवाल नहीं';

  @override
  String get gmDuelPass => 'Pass';

  @override
  String get gmDuelPassedWait => 'Pass किया — इंतज़ार…';

  @override
  String get gmDuelPassed => 'Pass किया';

  @override
  String get gmDuelPoint => 'Point!';

  @override
  String get gmDuelEven => 'बराबरी का मुकाबला';

  @override
  String get gmDuelExit => 'बाहर निकलें';

  @override
  String get gmDuelRematch => 'Rematch';

  @override
  String get gmErrNoDuel => 'कोई duel सवाल नहीं मिला।';

  @override
  String get gmSessionComplete => 'Session पूरा हुआ';

  @override
  String get gmSolid => 'बढ़िया recall!';

  @override
  String get gmAnotherPass => 'एक round और करें।';

  @override
  String get gmPlayAgain => 'फिर खेलें';

  @override
  String get gmBackToGames => 'Games पर वापस जाएँ';

  @override
  String get gmHowToPlay => 'कैसे खेलें';

  @override
  String get gmDontShow => 'दोबारा न दिखाएँ';

  @override
  String get gmHomeSubtitle =>
      'Recall, timeline, fact-or-bluff — UPSC वाले अंदाज़ में practice करें';

  @override
  String get gmConfig => 'Config';

  @override
  String get gmSetup => 'अपना session set करें';

  @override
  String get gmLanguage => 'भाषा';

  @override
  String get gmSubjects => 'Subjects';

  @override
  String get gmAll => 'All';

  @override
  String get gmStart => 'शुरू करें';

  @override
  String mpPairsCount(int n) {
    return '$n जोड़े';
  }

  @override
  String mpUnlock(int n, String subject) {
    return 'Unlock करने के लिए $n $subject सवाल attempt करें';
  }

  @override
  String mpUnlockDone(int done, int total) {
    return '$total में से $done पूरे';
  }

  @override
  String mpDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n दिन पहले',
      one: '1 दिन पहले',
    );
    return '$_temp0';
  }

  @override
  String mpWkAgo(int n) {
    return '$n हफ़्ते पहले';
  }

  @override
  String mpMoAgo(int n) {
    return '$n महीने पहले';
  }

  @override
  String mpMatched(int done, int total) {
    return '$done/$total मिलाए';
  }

  @override
  String mpTimeErrors(String time, int n) {
    return '$time · $n गलतियाँ';
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
      other: '$n जोड़े आपने गलत किए',
      one: '1 जोड़ा आपने गलत किया',
    );
    return '$_temp0';
  }

  @override
  String mpTopics(int n) {
    return '$n topics';
  }

  @override
  String mpQuickDrill(int n) {
    return '$n जोड़ों की quick recall drill — तैयार हों तो Start दबाएँ।';
  }

  @override
  String get mpPlayNow => 'अभी खेलें';

  @override
  String get mpCards => 'Cards';

  @override
  String get mpList => 'List';

  @override
  String get mpTapRow => 'Answer देखने के लिए किसी row पर tap करें';

  @override
  String get mpNeverPlayed => 'अभी तक नहीं खेला';

  @override
  String get mpToday => 'आज';

  @override
  String get mpYesterday => 'कल';

  @override
  String get mpPairsInRound => 'इस round के जोड़े';

  @override
  String get mpBestTime => 'Best time';

  @override
  String get mpLastPlayed => 'आख़िरी बार खेला';

  @override
  String get mpRevise => 'Revise करें';

  @override
  String get mpErrors => 'गलतियाँ';

  @override
  String get mpProgress => 'Progress';

  @override
  String get mpTerms => 'Terms';

  @override
  String get mpAnswers => 'Answers';

  @override
  String get mpAllMatched => 'सभी जोड़े मिल गए';

  @override
  String get mpPaused => 'Paused';

  @override
  String get mpResume => 'Resume करें';

  @override
  String get mpQuitToSet => 'Set पर वापस जाएँ';

  @override
  String get mpComplete => 'पूरा हुआ';

  @override
  String get mpTime => 'Time';

  @override
  String get mpTotalTime => 'कुल time';

  @override
  String get mpTotalErrors => 'कुल गलतियाँ';

  @override
  String get mpPairsCleared => 'जोड़े पूरे';

  @override
  String get mpNewBest => 'इस set का नया best time';

  @override
  String get mpFullRecall => 'कोई गलत tap नहीं — पूरा recall!';

  @override
  String get mpTryAnother => 'दूसरा set आज़माएँ';

  @override
  String get mpBackToSets => 'Sets पर वापस जाएँ';

  @override
  String get mpV5 => 'एकदम तेज़!';

  @override
  String get mpV4 => 'मज़बूत recall';

  @override
  String get mpV3 => 'अच्छा, और तेज़ हो सकता है';

  @override
  String get mpV2 => 'Recall धीमा है';

  @override
  String get mpV1 => 'काफ़ी revision की ज़रूरत है';

  @override
  String get mpTagline => 'सीखें। याद करें। Master बनें।';

  @override
  String get mpBrowse => 'Subject के हिसाब से देखें';

  @override
  String get mpHowItWorksQ => 'यह कैसे काम करता है?';

  @override
  String get mpGroupedNote =>
      'Topics difficulty के हिसाब से group हैं। जैसे-जैसे कठिन topics master करेंगे, stars मिलेंगे!';

  @override
  String get mpTerm => 'Term';

  @override
  String get mpTapTerm => 'Term देखने के लिए tap करें';

  @override
  String get mpTapFlip =>
      'Flip करने के लिए tap करें · अगले के लिए किसी भी दिशा में swipe करें';

  @override
  String get mpPlay => 'खेलें';

  @override
  String get mpHowItWorks => 'यह कैसे काम करता है';

  @override
  String get mpTrain => 'एक मिनट से कम में recall की practice';

  @override
  String get mpStep1T => 'Subject चुनें';

  @override
  String get mpStep1B => 'Polity, History, Geography और भी बहुत कुछ देखें।';

  @override
  String get mpStep2T => 'Topic चुनें';

  @override
  String get mpStep2B => 'हर set पर difficulty tag होता है — easy से hard तक।';

  @override
  String get mpStep3T => 'जोड़े मिलाएँ';

  @override
  String get mpStep3B =>
      'पहले term पर tap करें, फिर उसके answer पर। अपना best time तोड़ें और stars कमाएँ।';

  @override
  String get mpGotIt => 'समझ गया';

  @override
  String get mpOpenFailed => 'Game खुल नहीं सकी';

  @override
  String get mpGoHome => 'Home जाएँ';

  @override
  String get mpRevisionGame => 'Revision Game';

  @override
  String get mpBrowseAll => 'सभी sets देखें';

  @override
  String get mpSetDetail => 'Set detail';

  @override
  String get mpSummary => 'Summary';

  @override
  String get chatNotSignedIn =>
      'आप sign in नहीं हैं। कृपया sign in करके फिर कोशिश करें।';

  @override
  String get chatBlockedSend =>
      'आपने इस व्यक्ति को block किया है। Message भेजने के लिए Settings में unblock करें।';

  @override
  String chatSendFailed(String error) {
    return 'Message भेजा नहीं जा सका: $error';
  }

  @override
  String cpUpdateFailed(String error) {
    return 'Profile update नहीं हो सकी: $error';
  }

  @override
  String cpPrivacy(String app) {
    return 'Privacy note: Apple आगे के sign-in में आपका असली email/नाम share नहीं कर सकता। हम यह नाम सिर्फ़ $app के अंदर दिखाने के लिए रखते हैं।';
  }

  @override
  String fpCanYou(String line) {
    return '$line। क्या आप कर पाएँगे?';
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
    return '$date  ·  $n min पढ़ने में  ·  High Relevance';
  }

  @override
  String fpBreakdown(int a, int c, int w) {
    return '$a ने attempt किया · $c सही · $w गलत';
  }

  @override
  String fpTrap(int a, int p) {
    return '$a ने attempt किया · $p% इसमें फँसे';
  }

  @override
  String get chatListTitle => 'Chats';

  @override
  String get chatNone => 'अभी कोई chat नहीं';

  @override
  String get chatStartConv => 'बातचीत शुरू करें';

  @override
  String get chatStartFailed =>
      'Chat शुरू नहीं हो सकी। वापस जाकर फिर कोशिश करें।';

  @override
  String get chatSignInAgain => 'Message भेजने के लिए फिर से sign in करें।';

  @override
  String get chatBlockedHidden =>
      'आपने इस व्यक्ति को block किया है। उनके messages छिपे हैं। Chat के लिए Settings में unblock करें।';

  @override
  String get chatOpenLink => 'Link खुल नहीं सका';

  @override
  String get cpPhotoUpdated => 'Photo update हो गई';

  @override
  String get cpNameNotAllowed => 'नाम में UPSC War की अनुमति नहीं है';

  @override
  String get cpEnterName => 'कृपया अपना नाम लिखें';

  @override
  String get cpProfileUpdated => 'Profile update हो गई';

  @override
  String get cpTitle => 'अपनी profile पूरी करें';

  @override
  String get cpSignInContinue => 'आगे बढ़ने के लिए sign in करें';

  @override
  String get cpConnect =>
      'अपना account connect करें, ताकि आपकी profile और progress सभी devices पर sync रहे।';

  @override
  String get cpSigningIn => 'Sign in हो रहा है…';

  @override
  String get cpSignIn => 'Sign in करें';

  @override
  String get cpHelps =>
      'इससे दूसरे लोग Community और chat में आपको पहचान पाते हैं।';

  @override
  String get cpPhotoWeb =>
      'Profile photo Android या iOS ऐप में बदली जा सकती है।';

  @override
  String get cpYourName => 'आपका नाम';

  @override
  String get cpNameHint => 'जैसे: Sachin';

  @override
  String get cpSaving => 'Save हो रहा है…';

  @override
  String get cpPhotoAnytime => 'आप अपनी photo कभी भी Profile से बदल सकते हैं।';

  @override
  String get ddOpenFailed => 'Revision queue खुल नहीं सका';

  @override
  String get fpWhatsThis => 'यह क्या है?';

  @override
  String get fpNone =>
      'अभी कोई CA Shots नहीं हैं। Breaking CA briefings यहाँ दिखेंगी।';

  @override
  String get fpWhatAre => 'CA Shots क्या हैं?';

  @override
  String get fpWhatBody =>
      'इन्हें छोटी daily drills समझें — ऐसे shots जो आप रोज़ ले सकते हैं ताकि अपनी final battle के लिए तैयार रहें।';

  @override
  String get fpAlertsT => 'बार-बार alerts';

  @override
  String get fpAlertsB =>
      'जब कोई UPSC से जुड़ा article आपके ध्यान लायक हो, तो आपको notification मिलता है।';

  @override
  String get fpMcqT => 'एक focused MCQ';

  @override
  String get fpMcqB =>
      'हर shot में उस article से एक concept-based MCQ मिलता है, explanation के साथ।';

  @override
  String get fpReadyT => 'Battle readiness';

  @override
  String get fpReadyB =>
      'ये shots रोज़ लें, ताकि final battle तक आपके concepts तेज़ रहें।';

  @override
  String get fpNotDone => 'नहीं किया';

  @override
  String get fpDoneCorrect => 'किया · सही';

  @override
  String get fpDoneWrong => 'किया · गलत';

  @override
  String get fpUndated => 'बिना तारीख';

  @override
  String get fpReadSource => 'Source पढ़ें';

  @override
  String get fpShare => 'Share करें';

  @override
  String get fpLoadFailed => 'यह CA Shot load नहीं हो सका।';

  @override
  String get fpCheckNet =>
      'अपना internet connection check करके फिर कोशिश करें।';

  @override
  String get fpNewsSummary => 'खबर का सार';

  @override
  String get fpShowLess => 'कम दिखाएँ';

  @override
  String get fpReadMore => 'और पढ़ें';

  @override
  String get fpWhyRelevant => 'UPSC के लिए यह क्यों ज़रूरी है?';

  @override
  String get fpReviewAttempt => 'अपना MCQ attempt review करें';

  @override
  String get fpAttemptMcq => 'MCQ attempt करें';

  @override
  String get fpExpired => 'यह CA Shot expire हो चुका है।';

  @override
  String get fpAttempt => 'Attempt';

  @override
  String get fpPickSee => 'Answer और explanation देखने के लिए एक option चुनें।';

  @override
  String get fpCorrectBang => 'सही!';

  @override
  String get fpBackToShot => 'CA Shot पर वापस जाएँ';

  @override
  String get fpHomeSub => 'Breaking news brief + उस पर आधारित 1 MCQ।';

  @override
  String get fpAnswerThis => 'इस Pulse का answer दें';

  @override
  String get fpPickSubmit => 'Answer submit करने के लिए एक option चुनें।';

  @override
  String get fpNoAttempts => 'अभी तक कोई attempt नहीं';

  @override
  String get fpBeFirst => 'इसे attempt करने वाले पहले व्यक्ति बनें।';

  @override
  String tcOnlyAvail(String n) {
    return 'सिर्फ़ $n उपलब्ध हैं';
  }

  @override
  String tcMinutesTotal(int n) {
    return 'कुल $n मिनट';
  }

  @override
  String get tcCoach1T => 'सवालों की संख्या चुनें';

  @override
  String get tcCoach1B =>
      'इस session में कितने सवाल चाहिए, चुनें — quick drill के लिए 10, पूरे practice block के लिए 25।';

  @override
  String get tcCoach2T => 'Mode चुनें';

  @override
  String get tcCoach2B =>
      'Exam में test खत्म होने तक सारी explanations छिपी रहती हैं — असली paper की तरह। Learning में हर सवाल के तुरंत बाद answer और explanation दिखती है।';

  @override
  String tcCoach3B(int n) {
    return 'हर सवाल को ${n}s मिलते हैं। अगर बिना घड़ी practice करना चाहें तो इसे off कर दें।';
  }

  @override
  String glTitle(String app) {
    return '$app में sign in करें';
  }

  @override
  String pcDays(int n) {
    return 'Prelims: $n दिन';
  }

  @override
  String get pdLead => 'आप updates और reminders miss कर रहे हैं। कृपया ';

  @override
  String get pdLink => 'notifications';

  @override
  String get pdTrail => ' enable करें।';

  @override
  String get tcWentWrong => 'कुछ गड़बड़ हो गई। कृपया फिर कोशिश करें।';

  @override
  String get tcConfOff => 'Confidence rating बंद है';

  @override
  String get tcConfOffBody =>
      'Answer देखने से पहले आप कितने sure थे, यह track करने और Danger Zone insights unlock करने के लिए इसे on करें।';

  @override
  String get tcExamDesc =>
      'असली exam जैसा माहौल। Explanation test खत्म होने के बाद।';

  @override
  String get tcLearnDesc => 'हर सवाल के बाद explanation देखें।';

  @override
  String get tcNoQuestions => 'इस topic के लिए कोई सवाल उपलब्ध नहीं है।';

  @override
  String get tcTimePerQ => 'हर सवाल का time';

  @override
  String get tcNoLimit => 'कोई limit नहीं';

  @override
  String get tcStartExam => 'Exam शुरू करें';

  @override
  String get tcStartLearning => 'Learning session शुरू करें';

  @override
  String get tcNoTimeLimit => 'कोई time limit नहीं';

  @override
  String get tcTakeTime => 'हर सवाल पर जितना समय चाहें, लें।';

  @override
  String get tcExamNote =>
      'Exam mode एक timed test है, जिसमें explanations test खत्म होने के बाद मिलती हैं।';

  @override
  String get tcLearnNote =>
      'कोई घड़ी नहीं चल रही — गहराई से पढ़ने और revision के लिए बढ़िया।';

  @override
  String get glBody =>
      'अपनी progress save करें, stats सभी devices पर sync करें, और अपना streak सुरक्षित रखें।';

  @override
  String get glSigningIn => 'Sign in हो रहा है...';

  @override
  String get glApple => 'Apple से जारी रखें';

  @override
  String get glGoogle => 'Google से जारी रखें';

  @override
  String get glAgree =>
      'आगे बढ़कर आप हमारी Privacy Policy और Firebase के ज़रिए Apple या Google से authenticate करने के लिए सहमत होते हैं।';

  @override
  String get glReadPolicy => 'पूरी privacy policy पढ़ें';

  @override
  String get cuGetInTouch => 'हमसे संपर्क करें';

  @override
  String get cuBody =>
      'अगर कुछ समझ न आए, कोई feature idea हो, या कोई feedback हो — जो आपको सही लगे वो चुनें।';

  @override
  String get cuTgDirect => 'Telegram (direct message)';

  @override
  String get cuTgDirectSub => 'Quick सवाल और updates';

  @override
  String get cuTgGroup => 'Telegram group';

  @override
  String get cuTgGroupSub => 'Community और discussion';

  @override
  String get cuOpenFailed => 'Link खुल नहीं सका।';

  @override
  String get cuRate => 'Rate / review करें';

  @override
  String get rrTitle => 'एक Aspirant ने बनाया, Aspirants के लिए';

  @override
  String get rrBody1 =>
      'एक पूर्व UPSC aspirant ने बनाया, जिसने भी अंतहीन MCQs हल करते हुए यही संघर्ष झेला कि marks कहाँ कट रहे हैं, साफ़ पता ही नहीं चलता था।';

  @override
  String get rrBody2 =>
      'मक़सद सीधा था: confident गलतियाँ, danger zones, safe risk areas और बेहतर revision priorities पहचानकर aspirants को smarter तरीके से तैयारी करने में मदद करना।';

  @override
  String get rrJourney => 'UPSC Wars का सफ़र पढ़ें';

  @override
  String get rrBody3 =>
      'अगर UPSC Wars आपकी तैयारी में मदद कर रहा है, तो आपका review दूसरे aspirants को भी इसे ढूँढने में मदद करेगा।';

  @override
  String get rrRate => '⭐ UPSC Wars को Rate और Review करें';

  @override
  String get qpTitle => 'Mode चुनें';

  @override
  String get qpSub => 'आप कैसे practice करना चाहेंगे?';

  @override
  String get qpTutor => 'Tutor Mode';

  @override
  String get qpTutorDesc => 'हर सवाल के बाद explanations देखें';

  @override
  String get qpExam => 'Exam Mode';

  @override
  String get qpExamDesc => 'Results आख़िर में मिलेंगे';

  @override
  String get pcToday => 'Prelims: आज';

  @override
  String get pcOneDay => 'Prelims: 1 दिन';

  @override
  String get pcTitle => 'UPSC PRELIMS COUNTDOWN';

  @override
  String get pcUnits => 'दिन : घंटे : मिनट : सेकंड';

  @override
  String get pdTitle => 'आप drill, CA और community alerts miss कर रहे हैं';

  @override
  String get pdBody =>
      'Daily Drill, current affairs, CA Shots और community invites के लिए notifications चालू करें।';

  @override
  String get pdEnable => 'Alerts चालू करें';

  @override
  String get suStoreFailed => 'Store नहीं खुल सका।';

  @override
  String get suAvailable => 'Update उपलब्ध है';

  @override
  String get suUpdate => 'Update करें';

  @override
  String get suLater => 'बाद में';

  @override
  String get kuTitle => 'Update ज़रूरी है';

  @override
  String get kuBody =>
      'यह version अब supported नहीं है।\nPractice जारी रखने के लिए कृपया update करें।';

  @override
  String get kuContinue => 'जारी रखने के लिए store से update करें';

  @override
  String get vbDismissQ => 'हटाएँ?';

  @override
  String get vbDismissBody =>
      'क्या आप पक्का हटाना चाहते हैं? यह आपको दोबारा नहीं दिखाया जाएगा।';

  @override
  String get commonYes => 'हाँ';

  @override
  String get vbDefault => 'हमने एक छोटा video डाला है जो आपके काम आ सकता है।';

  @override
  String get vbWatch => 'Video देखें';

  @override
  String get lbSignIn => 'Leaderboard देखने के लिए sign in करें';

  @override
  String get obgOdd => 'जो बाकियों से मेल नहीं खाता, उसे पहचानें।';

  @override
  String get obgFob => 'घड़ी में दस seconds — अपने अंदाज़े पर भरोसा करें।';

  @override
  String get obgCtd => 'Clues के बीच छिपा link ढूँढें।';

  @override
  String get obgDuel => 'एक phone, दो players — जो तेज़, वही जीतेगा।';

  @override
  String ecWatchOut(String title) {
    return 'सावधान - $title';
  }

  @override
  String srYou(String opt) {
    return 'आप: ($opt)';
  }

  @override
  String srCorrect(String opt) {
    return 'सही: ($opt)';
  }

  @override
  String srYourAnswer(String opt) {
    return 'आपका answer: ($opt)';
  }

  @override
  String stSharedWithYou(String name) {
    return '$name ने यह test आपके साथ share किया है।';
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
    return 'सवाल: $n';
  }

  @override
  String get obgTitle => 'छह games। बिल्कुल boring नहीं revision।';

  @override
  String get obgStart => 'शुरू करें';

  @override
  String get srTitle => 'Session review';

  @override
  String get srBookmark => 'Bookmark करें';

  @override
  String get srRevisionMode => 'Revision mode';

  @override
  String get stNameHint =>
      'अगर आप अपना नाम नहीं देना चाहते, तो कोई भी नाम लिख दें';

  @override
  String get stBefore => 'शुरू करने से पहले';

  @override
  String get stEnterName => 'अपना display name लिखें';

  @override
  String get stTop5 => 'Leaderboard · Top 5';

  @override
  String get stBeFirst => 'यह test देने वाले पहले व्यक्ति बनें।';

  @override
  String get stAbout => 'आप एक shared practice test शुरू करने वाले हैं।';

  @override
  String get stTitle => 'Shared test';

  @override
  String get stOhSnap => 'अरे!';

  @override
  String get stExpired =>
      'यह link उपलब्ध नहीं है या expire हो चुका है।\nअपने दोस्त से दोबारा share करने को कहें।';

  @override
  String get stOpening => 'Shared test खुल रहा है…';

  @override
  String get stPreparing => 'Configuration तैयार हो रही है…';

  @override
  String tsAttemptedOf(int attempted, int total) {
    return '$total में से $attempted tests attempt किए';
  }

  @override
  String tsAccuracyPct(int percent) {
    return '$percent% accuracy';
  }

  @override
  String tsCompletedOf(int attempted, int total) {
    return '$total में से $attempted tests पूरे हुए';
  }

  @override
  String tsTestsIn(String title) {
    return '$title के tests';
  }

  @override
  String tsQAnswered(int n) {
    return '$n सवालों के जवाब दिए';
  }

  @override
  String tsHcTests(int n) {
    return '$n tests: subjects, current affairs और mocks';
  }

  @override
  String tsHcFree(int n) {
    return '$n free tests आज़माने के लिए। Subject tests, current affairs, full mocks।';
  }

  @override
  String tsUnlocksOn(String date) {
    return '$date को unlock होगा';
  }

  @override
  String tsAvailFrom(String date) {
    return '$date से उपलब्ध';
  }

  @override
  String tsLiveSince(String date) {
    return '$date से live';
  }

  @override
  String tsQMin(int q, int m) {
    return '$q सवाल · $m मिनट';
  }

  @override
  String tsInProgress(String meta) {
    return 'जारी है · $meta';
  }

  @override
  String tsScoreLine(String marks, int correct, int wrong, int skipped) {
    return 'Score $marks  ·  $correct सही, $wrong गलत, $skipped छोड़े';
  }

  @override
  String tsNQuestions(int n) {
    return '$n सवाल';
  }

  @override
  String tsNMinutesTimed(int n) {
    return '$n मिनट, timed';
  }

  @override
  String get tsLoadMineFail => 'आपकी test series load नहीं हो सकी।';

  @override
  String get tsNoneStarted => 'आपने अभी तक कोई test series शुरू नहीं की है।';

  @override
  String get tsUnlocked => 'Unlock हो चुकी';

  @override
  String get tsFreeTests => 'Free tests';

  @override
  String get tsPrelimsOver =>
      'Prelims खत्म हो चुका है। सभी tests practice के लिए खुले रहेंगे।';

  @override
  String get tsLoadSeriesFail => 'यह series load नहीं हो सकी।';

  @override
  String get tsLoadSubjectFail => 'यह subject load नहीं हो सका।';

  @override
  String get tsSubjectNotFound => 'Subject नहीं मिला।';

  @override
  String get tsTopicsToRevise => 'Revise करने वाले topics';

  @override
  String get tsNoOwnTests =>
      'इस subject के अपने कोई tests नहीं हैं। इसके numbers आपके full-length tests से आते हैं।';

  @override
  String get tsNoQAnswered => 'अभी तक किसी सवाल का जवाब नहीं दिया';

  @override
  String get tsUnavailable => 'Test series अभी उपलब्ध नहीं है।';

  @override
  String get tsLoadFail =>
      'Test series load नहीं हो सकी। अपना connection check करें।';

  @override
  String get tsHcDefault =>
      'Subject tests, current affairs और full-length mocks।';

  @override
  String get tsFreeLabel => 'Free';

  @override
  String get tsPublishingSoon => 'जल्द ही publish होगा';

  @override
  String get tsReview => 'Review';

  @override
  String get tsSoon => 'जल्द';

  @override
  String get tsLoadTestFail =>
      'यह test load नहीं हो सका। अपना connection check करें और फिर कोशिश करें।';

  @override
  String get tsPractiseAgain => 'दोबारा practice करें (score नहीं होगा)';

  @override
  String get tsMarking => 'सही पर +2, गलत पर −0.66';

  @override
  String get tsOneAttempt =>
      'सिर्फ़ एक scored attempt। इसके बाद आप इसे review कर सकते हैं और अपने stats पर असर डाले बिना दोबारा practice कर सकते हैं।';

  @override
  String get tsUnlockedAll => 'Unlock हो गया! इस series का हर test अब आपका है।';

  @override
  String get tsPurchaseFail => 'Purchase पूरा नहीं हो सका।';

  @override
  String get tsPaymentPendingSeries =>
      'आपका payment pending है। पूरा होते ही series unlock हो जाएगी।';

  @override
  String get tsCodeCheckFail =>
      'Code check नहीं हो सका। अपना connection check करें और फिर कोशिश करें।';

  @override
  String get tsUnlockAll => 'सभी tests unlock करें';

  @override
  String get tsPaidNoAccess =>
      'Payment हो गया, पर access अभी नहीं मिला। Restore purchase पर tap करें, या कुछ देर बाद फिर कोशिश करें।';

  @override
  String tsPwSubject(int n, int questions, int pct) {
    return '$n subject tests, हर एक में $questions सवाल, $pct% PYQs के साथ';
  }

  @override
  String tsPwCa(int n) {
    return '$n current-affairs tests, हर महीने की 1 तारीख़ को जुड़ते हैं';
  }

  @override
  String tsPwMocks(int n, int questions, int hours) {
    return '$n full-length mocks जो असली paper जैसे हैं ($questions सवाल, $hours घंटे)';
  }

  @override
  String tsPwFree(int n) {
    return '$n tests पहले free में आज़माएँ, सभी PYQ tests सहित।';
  }

  @override
  String tsUnlockAllPrice(String price) {
    return 'सभी tests unlock करें · $price';
  }

  @override
  String get tsSignInPurchase =>
      'अपना purchase अपने account में save करने के लिए Google से sign in करें।';

  @override
  String get tsPassUnavailable =>
      'यह pass अभी उपलब्ध नहीं है। कृपया बाद में फिर कोशिश करें।';

  @override
  String get tsPaymentPending => 'आपका payment pending है।';

  @override
  String get tsPurchasesUnavailable =>
      'इस device पर purchases उपलब्ध नहीं हैं।';

  @override
  String get tsCodeNotApplied => 'यह code apply नहीं हो सका।';

  @override
  String get tsAlreadyHaveAccess => 'इस series का access आपके पास पहले से है।';

  @override
  String get tsAccessNotLoaded =>
      'आपका access जुड़ गया है, पर अभी load नहीं हुआ। थोड़ी देर में Restore purchase पर tap करें।';

  @override
  String get tsEnterCode => 'पहले अपना code डालें।';

  @override
  String get tsSignInAccess =>
      'अपना access अपने account में save करने के लिए Google से sign in करें।';

  @override
  String get tsSignInBefore =>
      'उसी Google account से sign in करें जो आपने पहले इस्तेमाल किया था।';

  @override
  String get tsAccessRestored => 'Access वापस मिल गया।';

  @override
  String get tsNothingFoundUnlock =>
      'इस account के लिए कुछ नहीं मिला। आप नीचे से series unlock कर सकते हैं।';

  @override
  String get tsNothingFound => 'इस account के लिए कुछ नहीं मिला।';

  @override
  String get tsRestoreFail =>
      'Restore नहीं हो सका। अपना connection check करके फिर कोशिश करें।';

  @override
  String get tsPayOnce =>
      'एक बार payment। कोई subscription नहीं। हमेशा आपका, बाद में जुड़ने वाला हर test भी।';

  @override
  String get tsPwBilingual =>
      'हर सवाल और explanation हिन्दी और English दोनों में';

  @override
  String get tsPwDash =>
      'Dashboard: subject-wise accuracy, Danger Zone और risk topics';

  @override
  String get tsPwNoPurchases =>
      'इस device या build पर purchases अभी उपलब्ध नहीं हैं।';

  @override
  String get tsPwNotOnSale => 'यह series अभी बिक्री के लिए उपलब्ध नहीं है।';

  @override
  String get tsDiscountCode => 'Discount code';

  @override
  String get tsApply => 'Apply करें';

  @override
  String get tsHaveCode => 'Code है?';

  @override
  String get tsRestorePurchase => 'Purchase restore करें';

  @override
  String get tsMissingQs =>
      'इस test के कुछ सवाल अभी आपके device पर नहीं हैं। अपना connection check करें, या ऐप update करें, और फिर कोशिश करें।';

  @override
  String get tsNoQsRevise =>
      'इस topic में अभी revise करने के लिए कोई सवाल नहीं है।';

  @override
  String get tsOpenTopicFail => 'यह topic खुल नहीं सका। कृपया फिर कोशिश करें।';

  @override
  String get tsSubConf => 'वे सवाल जो आपने high confidence के बावजूद गलत किए।';

  @override
  String get tsSubWrong =>
      'वे सवाल जो आपने गलत किए। उन्हें दोबारा पढ़ने के लिए topic पर tap करें।';

  @override
  String get tsPrevYearQs => 'पिछले वर्षों के सवाल';

  @override
  String tsDoneOf(int a, int t) {
    return '$a/$t पूरे';
  }

  @override
  String tsCompletedSlash(int a, int t) {
    return '$a/$t tests पूरे हुए';
  }

  @override
  String tsFreePyqMix(int n) {
    return '$n free PYQ mix tests';
  }

  @override
  String tsCorrectOf(int c, int a) {
    return '$c/$a सही';
  }

  @override
  String tsMistakesN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n गलतियाँ',
      one: '1 गलती',
    );
    return '$_temp0';
  }

  @override
  String tsSeeAllTopics(int n) {
    return 'सभी topics देखें ($n)';
  }

  @override
  String tsQAnsweredFlt(int n) {
    return 'full-length tests में $n सवालों के जवाब दिए';
  }

  @override
  String get tsWhatYouGet => 'आपको क्या मिलेगा';

  @override
  String tsFltDesc(int questions, int hours) {
    return 'हर test में $questions सवाल, समय $hours घंटे।\nसभी GS subjects + current affairs का test';
  }

  @override
  String tsSubjTestsDesc(int n) {
    return 'GS subjects के लिए topic-wise $n सवालों के tests';
  }

  @override
  String get tsCaEveryMonth => 'हर महीने Current affairs';

  @override
  String get tsCaMonthlyDesc =>
      'हर महीने की 1 तारीख़ को नया test, पिछले महीने के Current affairs से बना।';

  @override
  String get tsKnowMarks => 'जानें कि marks कहाँ कट रहे हैं';

  @override
  String get tsKnowMarksDesc =>
      'Subject-wise accuracy, revise करने वाले topics और safe areas, इस आधार पर कि आप कितने sure थे।';

  @override
  String get tsBilingualOnePay => 'हिन्दी और English, एक ही payment';

  @override
  String get tsNoSubExpire =>
      'कोई subscription नहीं। एक बार pay करें, कभी expire नहीं होगा।';

  @override
  String get tsSubSafe =>
      'वे topics जिनमें आप अपने tests में लगातार सही रहते हैं।';

  @override
  String get tsPrepOverview => 'आपका Preparation Overview';

  @override
  String get tsBasedOn => 'आपके full-length और subject-wise tests के आधार पर।';

  @override
  String get tsFinishATest =>
      'अपनी progress, weak topics और strengths देखने के लिए एक test पूरा करें।';

  @override
  String get tsYourStats => 'आपके STATS';

  @override
  String get tsTestsCompleted => 'पूरे हुए tests';

  @override
  String get tsOverallAccuracy => 'कुल accuracy';

  @override
  String get tsQsAttempted => 'Attempt किए गए सवाल';

  @override
  String get tsReviseFirst => 'पहले revise करने वाले topics';

  @override
  String get tsKeepPractising => 'Practice जारी रखें';

  @override
  String get tsSeeAll => 'सभी देखें';

  @override
  String tsFltIntro(int questions, int hours) {
    return 'असली exam जैसा अनुभव: $questions सवाल, $hours घंटे।';
  }

  @override
  String get tsReviseFromFlts => 'Revise करने वाले topics (FLTs से)';

  @override
  String get tsAvailableTests => 'उपलब्ध Tests';

  @override
  String get tsSubjIntro =>
      'Subject के हिसाब से practice करें और अपने concepts मज़बूत करें।';

  @override
  String get tsFullSyllDesc =>
      'एक ही paper में हर subject, Prelims के अनुपात में।';

  @override
  String get tsBySubject => 'Subject के अनुसार';

  @override
  String get tsPyqCaIntro =>
      'Extra practice। ये tests आपके overview stats में नहीं गिने जाते।';

  @override
  String get tsNewTest1st => 'हर महीने की 1 तारीख़ को नया test आता है।';

  @override
  String get tsNothingYet => 'यहाँ अभी कुछ नहीं है।';

  @override
  String get tsSubSafe2 =>
      'वे topics जिनमें आप लगातार सही रहते हैं। तेज़ रहने के लिए practice करते रहें।';

  @override
  String get tsNoWeak =>
      'अभी कोई weak topic नहीं है। एक test पूरा करें, वे यहाँ दिखने लगेंगे।';

  @override
  String tsNoSafe(int pct, int min) {
    return 'अभी कोई safe area नहीं है। $min+ सवालों में $pct% accuracy होने पर topic safe बनता है।';
  }

  @override
  String get tsFromFlt => 'Full-length tests से';

  @override
  String tsCorrectAnswer(String l) {
    return 'सही answer: $l';
  }

  @override
  String tsCorrectBang(String l) {
    return 'सही! Answer: $l';
  }

  @override
  String tsNotQuite(String l) {
    return 'सही नहीं। Answer है $l';
  }

  @override
  String tsQsCorrectOf(int c, int a) {
    return '$a में से $c सवाल सही';
  }

  @override
  String tsLowScoreStory(String subject, String topic) {
    return 'Subject का कम score पूरी कहानी नहीं है। $subject के अंदर, $topic में आपके असल में marks कटते हैं। वहीं से शुरू करें।';
  }

  @override
  String tsPrelimsOn(String date) {
    return 'Prelims $date को';
  }

  @override
  String tsDaysToGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n दिन बाकी',
      one: '1 दिन बाकी',
    );
    return '$_temp0';
  }

  @override
  String tsSeeAllPyq(int n) {
    return 'सभी $n PYQ tests देखें';
  }

  @override
  String tsFreeInAll(int n) {
    return 'कुल $n tests free हैं, subjects, current affairs और mocks में।';
  }

  @override
  String tsWrapTests(int n) {
    return '$n tests: mocks, subjects और current affairs';
  }

  @override
  String get tsOneTimeNoSub => 'एक बार का payment, कोई subscription नहीं';

  @override
  String get tsYesterdayCa => 'कल के current affairs';

  @override
  String get tsSampleQ => 'Sample सवाल';

  @override
  String get tsHowExplained =>
      'Series के हर सवाल की explanation ऐसे ही होती है।';

  @override
  String get tsTapOption =>
      'Answer और explanation देखने के लिए किसी option पर tap करें।';

  @override
  String get tsJustShow => 'बस answer दिखाएँ';

  @override
  String get tsEveryQDetail =>
      'Series के हर सवाल में इतनी ही detail होती है: English और हिन्दी में।';

  @override
  String get tsExampleNums => 'Sample numbers के साथ example';

  @override
  String get tsTopicByTopic => 'Topic दर topic';

  @override
  String get tsTapTopicHint =>
      'ऐप में किसी भी topic पर tap करके वही सवाल दोबारा पढ़ें जो आपने उसमें attempt किए थे।';

  @override
  String get tsHeroTagline =>
      'Practice करें। सीखें। अपने weak areas खोजें। Prelims के लिए बेहतर तैयार हों।';

  @override
  String get tsTotalTests => 'कुल tests';

  @override
  String get tsFreshMonthly =>
      'हर महीने की 1 तारीख़ को नया test, पिछले महीने की खबरों से बना।';

  @override
  String get tsFreePyqDesc =>
      'UPSC जो सवाल पहले पूछ चुका है, उनसे शुरुआत करें। Paid tests जैसा ही interface, explanations और analysis।';

  @override
  String get tsFromYesterdayCa => 'कल के current affairs से';

  @override
  String get tsSampleGs => 'एक sample GS सवाल';

  @override
  String get tsExplTeach => 'ऐसी explanations जो सच में सिखाती हैं';

  @override
  String get tsExplTeachSub =>
      'आप जवाब भी सीखते हैं, और paper-setter की तरह सोचना भी।';

  @override
  String get tsStmtDesc =>
      'हर statement को सही या गलत ठहराया गया है, कारण के साथ।';

  @override
  String get tsDistractorDesc =>
      'वह option जो सही लगता है पर होता नहीं, और लोग उससे क्यों धोखा खाते हैं।';

  @override
  String get tsElimDesc =>
      'Options काटने का step-by-step तरीका, तब भी जब आप unsure हों।';

  @override
  String get tsValueAddDesc =>
      'याद रखने लायक related facts: एक सवाल, पाँच सीख।';

  @override
  String get tsSeeRealExample => 'एक असली example देखें';

  @override
  String get tsSmarterTitle => 'Score से ज़्यादा smart';

  @override
  String get tsSmarterSub =>
      'ज़्यादातर test series आपके marks पर रुक जाती हैं। हम बताते हैं कि आगे क्या करना है।';

  @override
  String get tsToolQueueTitle => 'आपकी Revision Queue अपने-आप बनती है';

  @override
  String get tsToolQueueBody =>
      'कोई सवाल गलत हुआ? कोई सवाल बाद में देखने के लिए bookmark किया? वह अपने-आप आपकी revision queue में चला जाता है। न notebook, न list बनाने की झंझट। बस queue खोलें और revise करें।';

  @override
  String get tsToolBlindTitle => 'अपने blind spots खोजें';

  @override
  String get tsToolBlindBody =>
      'हम पूछते हैं कि आप कितने sure थे। Confident पर wrong एक blind spot है: पहले इसे ठीक करें। Confident और right एक safe area है: वहाँ ज़्यादा attempt करें और risk लें।';

  @override
  String get tsToolTopicTitle =>
      'ठीक-ठीक जानें कि किन topics में marks कट रहे हैं';

  @override
  String get tsToolTopicBody =>
      'Modern History में accuracy कम है? हम यह भी बताते हैं कि उसके अंदर कौन से topics उसे नीचे खींच रहे हैं, ताकि आप सही chapter revise करें, पूरी book नहीं।';

  @override
  String get tsSeeExample => 'एक example देखें';

  @override
  String get tsSureRight => 'Sure और right';

  @override
  String get tsSafeAction => 'यहाँ ज़्यादा attempt करें। Risk लें।';

  @override
  String get tsSureWrong => 'Sure पर wrong';

  @override
  String get tsBlindAction => 'इन्हें पहले ठीक करें। इनसे marks कटते हैं।';

  @override
  String get tsGuessRight => 'Pure guess और right';

  @override
  String get tsLuckyAction => 'Revise करें ताकि याद रहे।';

  @override
  String get tsGuessWrong => 'Pure guess और wrong';

  @override
  String get tsGapAction => 'Explanation से सीखें।';

  @override
  String get tsPractiseLike => 'Prelims के दिन जैसी practice करें';

  @override
  String get tsMocksMirror => 'Full-length mocks असली paper जैसे होते हैं।';

  @override
  String ts100q2h(int questions, int hours) {
    return '$questions सवाल, $hours घंटे';
  }

  @override
  String get tsTimedPaper => 'सभी GS subjects के साथ timed, exam-style paper।';

  @override
  String get tsRealMarking => 'असली marking';

  @override
  String get tsMarkingSkip => 'सही पर +2, गलत पर −0.66। जानें कब skip करना है।';

  @override
  String get tsOneScored => 'एक scored attempt';

  @override
  String get tsThenReview =>
      'फिर इसे review करें, और stats पर असर डाले बिना दोबारा practice करें।';

  @override
  String get tsBothLangs => 'हर सवाल और explanation, दोनों भाषाओं में।';

  @override
  String get tsOnePayGood => 'एक बार payment। हमेशा के लिए आपका।';

  @override
  String get tsWrapExpl => 'English और हिन्दी में detailed explanations';

  @override
  String get tsWrapQueue =>
      'Revision queue, blind spots और topic-wise analysis';

  @override
  String get tsWrapNoExpiry =>
      'कोई subscription नहीं, कोई expiry नहीं। बाद में जुड़ने वाले tests भी शामिल हैं।';

  @override
  String get tsNotSure => 'अभी पक्का नहीं? पहले free tests आज़माएँ।';

  @override
  String get tsTryFreePyq => 'Free PYQ tests आज़माएँ';

  @override
  String get tsGetHelp => 'मदद चाहिए?';

  @override
  String get tsGetHelpBody =>
      'Unlock, payment या किसी test के बारे में सवाल? लिखें — हम जवाब देते हैं।';

  @override
  String get tsGetHelpTelegram => 'Telegram';

  @override
  String get tsGetHelpEmail => 'Email';
}
