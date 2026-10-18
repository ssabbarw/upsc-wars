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
  String get commonLogOut => 'लॉग आउट';

  @override
  String get languagePickerTitle => 'भाषा चुनें';

  @override
  String get languagePickerSubtitle => 'पूरे ऐप और सवालों के लिए एक ही भाषा।';

  @override
  String get languagePickerHintEn => 'ऐप और सवाल, दोनों English में।';

  @override
  String get languagePickerHintHi => 'ऐप और सवाल, दोनों हिन्दी में।';

  @override
  String get languagePickerPracticeTest => 'प्रैक्टिस टेस्ट';

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
  String get settingsLoggingOut => 'लॉग आउट हो रहा है...';

  @override
  String get settingsSignOutSubtitle => 'इस डिवाइस से साइन आउट करें';

  @override
  String get settingsLogOutConfirmTitle => 'लॉग आउट करें?';

  @override
  String get settingsLogOutConfirmBody =>
      'क्या आप सच में लॉग आउट करना चाहते हैं?';

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
    return 'नमस्ते, $name';
  }

  @override
  String get homeGoodMorning => 'सुप्रभात';

  @override
  String get homeGoodAfternoon => 'शुभ दोपहर';

  @override
  String get homeGoodEvening => 'शुभ संध्या';

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
      other: '$count तरह के traps',
      one: '1 तरह के trap',
    );
    return 'आप $_temp0 में फँसे हैं';
  }

  @override
  String homeStartNQuestionTest(int count) {
    return '$count सवालों का टेस्ट शुरू करें';
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
  String get homeGreetingGeneric => 'नमस्ते';

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
  String get activationStartTest => 'टेस्ट शुरू करें';

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
  String get demoPoint3Title => 'टेस्ट खत्म होते ही detailed insights';

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
  String get todayPaperQuizTitle => 'आज का paper quiz';

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
  String get progressTabHistory => 'टेस्ट हिस्ट्री';

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
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get profileYourProfile => 'आपकी प्रोफ़ाइल';

  @override
  String get profileSignInPitch =>
      'Community से जुड़ने, battles में हिस्सा लेने और अपनी प्रोफ़ाइल बनाने के लिए sign in करें।';

  @override
  String get authSigningIn => 'Sign in हो रहा है...';

  @override
  String get authContinueApple => 'Apple से जारी रखें';

  @override
  String get authContinueGoogle => 'Google से जारी रखें';

  @override
  String get profilePhotoUpdated => 'प्रोफ़ाइल फ़ोटो अपडेट हो गई';

  @override
  String get profilePhotoWebHint =>
      'प्रोफ़ाइल फ़ोटो Android या iOS ऐप में बदली जा सकती है।';

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
  String get profileCommunityUpdated => 'Community प्रोफ़ाइल अपडेट हो गई';

  @override
  String get profileCommunityTitle => 'Community प्रोफ़ाइल';

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
      'Marks explanation में हैं — elimination, statement analysis और trap option।';

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
  String get commonSomethingWrong => 'कुछ गड़बड़ हो गई';

  @override
  String get testSessionLoadFailed => 'Test session load नहीं हो सका।';

  @override
  String get testTimerPausedNotice =>
      'ऐप बंद रहने के दौरान Timer रुका रहा। बचा हुआ समय सही न हो सकता है।';

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
  String get historyTitle => 'हिस्ट्री';

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
}
