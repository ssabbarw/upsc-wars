import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:upsc_wars/core/deep_link/share_link_kind.dart';
import 'package:upsc_wars/core/deep_link/shared_session_firestore.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/session_result.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/domain/entities/test_question_share_map.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/core/theme/app_theme.dart';
import 'package:upsc_wars/features/history/widgets/explanation_card.dart';
import 'package:upsc_wars/web_player/web_player_danger_zone_review_screen.dart';
import 'package:upsc_wars/web_player/web_player_results_screen.dart';
import 'package:upsc_wars/web_player/web_player_ui_tokens.dart';
import 'package:upsc_wars/web_player/web_player_welcome_sheet.dart';
import 'package:upsc_wars/web_player/web_session_chrome.dart';
import 'package:upsc_wars/web_player/web_session_result_builder.dart';
import 'package:upsc_wars/shared/extensions/context_extensions.dart';
import 'package:upsc_wars/shared/widgets/question_table_view.dart';
import 'package:upsc_wars/core/constants/app_constants.dart';
import 'package:upsc_wars/shared/widgets/selectable_copy_search_text.dart';

class WebPlayerRoot extends StatefulWidget {
  const WebPlayerRoot({super.key});

  @override
  State<WebPlayerRoot> createState() => _WebPlayerRootState();
}

class _WebPlayerRootState extends State<WebPlayerRoot> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.appDisplayName} — Shared practice',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: WebPlayerShell(
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.dark;
          });
        },
      ),
    );
  }
}

class _Attempt {
  _Attempt({
    this.selectedOption,
    this.confidence,
    this.revealed = false,
    this.examAnswered = false,
  });

  String? selectedOption;
  String? confidence;
  bool revealed;
  bool examAnswered;
}

class WebPlayerShell extends StatefulWidget {
  const WebPlayerShell({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<WebPlayerShell> createState() => _WebPlayerShellState();
}

class _WebPlayerShellState extends State<WebPlayerShell>
    with TickerProviderStateMixin {
  static const _prefsPrefix = 'web_player_prog_v1_';

  String? _shareId;
  String? _kind;
  ShareLinkKind? _linkKind;
  String _subject = '';
  String _topic = '';
  List<TestQuestion> _questions = [];
  bool _loading = true;
  String? _error;

  int _index = 0;
  String _uiLang = 'en';
  bool _timed = true;
  int _perQuestionSecs = 60;
  int _remainingSecs = 0;
  Timer? _learningQTimer;
  Timer? _examGlobalTimer;
  final Map<String, _Attempt> _attempts = {};

  String _sessionMode = 'learning';
  int _examRemainingSecs = 0;
  int? _examTimeLimitSecs;
  DateTime? _runStartedAt;

  bool _running = false;
  bool _sessionCompleted = false;
  String? _completedAtIso;
  bool _reviewMode = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _learningQTimer?.cancel();
    _examGlobalTimer?.cancel();
    super.dispose();
  }

  void _stopLearningTimer() {
    _learningQTimer?.cancel();
    _learningQTimer = null;
  }

  void _stopExamTimer() {
    _examGlobalTimer?.cancel();
    _examGlobalTimer = null;
  }

  void _stopAllTestTimers() {
    _stopLearningTimer();
    _stopExamTimer();
  }

  Future<void> _bootstrap() async {
    final segs = Uri.base.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length < 3 || segs[0].toLowerCase() != 'share') {
      setState(() {
        _loading = false;
        _error = 'Open a link like /share/test/{share-id}/';
      });
      return;
    }
    _kind = segs[1].toLowerCase();
    _shareId = segs[2];
    try {
      final repo = SharedSessionFirestoreRepository();
      final doc = await repo.fetch(_shareId!);
      _subject = doc.subject;
      _topic = doc.topic ?? '';
      _linkKind = doc.kind;
      final list = <TestQuestion>[];
      for (var i = 0; i < doc.uuids.length; i++) {
        list.add(
          testQuestionFromShareMap(
            doc.uuids[i],
            position: i + 1,
            subject: doc.subject,
            topic: doc.topic ?? '',
          ),
        );
      }
      setState(() {
        _questions = list;
        _loading = false;
      });
      if (!mounted) return;
      await _maybeOfferResume();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _prefsKey() => '$_prefsPrefix$_shareId';

  String _kindLabel() {
    final k = _kind;
    if (k == null || k.isEmpty) return 'set';
    return '${k[0].toUpperCase()}${k.substring(1)}';
  }

  Future<Map<String, dynamic>?> _readSaved() async {
    if (_shareId == null) return null;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKey());
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSaved() async {
    if (_shareId == null) return;
    final p = await SharedPreferences.getInstance();
    final attemptsJson = <String, dynamic>{};
    for (final e in _attempts.entries) {
      attemptsJson[e.key] = {
        'selectedOption': e.value.selectedOption,
        'confidence': e.value.confidence,
        'revealed': e.value.revealed,
        'examAnswered': e.value.examAnswered,
      };
    }
    await p.setString(
      _prefsKey(),
      jsonEncode({
        'completed': _sessionCompleted,
        if (_completedAtIso != null) 'completedAt': _completedAtIso,
        'timed': _timed,
        'perQuestionSecs': _perQuestionSecs,
        'currentIndex': _index,
        'sessionMode': _sessionMode,
        'examRemainingSecs': _examRemainingSecs,
        'examTimeLimitSecs': _examTimeLimitSecs,
        if (_runStartedAt != null)
          'startedAt': _runStartedAt!.toUtc().toIso8601String(),
        'attempts': attemptsJson,
      }),
    );
  }

  Future<void> _clearSaved() async {
    if (_shareId == null) return;
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefsKey());
  }

  SessionResult _buildSessionResult({required DateTime completedAt}) {
    final started = _runStartedAt ?? completedAt;
    final snaps = <String, WebPlayerAttemptSnapshot>{};
    for (final e in _attempts.entries) {
      final a = e.value;
      snaps[e.key] = WebPlayerAttemptSnapshot(
        selectedOption: a.selectedOption,
        confidence: a.confidence,
        revealed: a.revealed,
        examAnswered: a.examAnswered,
      );
    }
    return buildWebPlayerSessionResult(
      shareId: _shareId!,
      subject: _subject,
      topic: _topic.isEmpty ? null : _topic,
      mode: _sessionMode,
      language: _uiLang,
      timeLimitSecs: _sessionMode == 'exam'
          ? (_timed ? _examTimeLimitSecs : null)
          : (_timed ? _perQuestionSecs : null),
      startedAt: started,
      completedAt: completedAt,
      questions: _questions,
      attempts: snaps,
    );
  }

  Widget _webPlayerResultsPage(BuildContext routeContext, SessionResult result) {
    return WebPlayerResultsScreen(
      result: result,
      onReviewDangerZone: result.dangerZoneWrongCount > 0
          ? () {
              final list = _buildDangerZoneQuestionList();
              if (list.isEmpty || !routeContext.mounted) return;
              Navigator.of(routeContext).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      WebPlayerDangerZoneReviewScreen(questions: list),
                ),
              );
            }
          : null,
    );
  }

  List<TestQuestion> _buildDangerZoneQuestionList() {
    final out = <TestQuestion>[];
    for (final q in _questions) {
      final a = _attempts[q.uuid];
      if (a == null) continue;
      final sel = a.selectedOption;
      if (sel == null) continue;
      if (sel == q.correctOption.toLowerCase()) continue;
      if (!AnswerConfidence.isDangerouslyConfident(a.confidence)) continue;
      out.add(
        q.copyWith(
          selectedOption: sel,
          status: 'wrong',
          confidence: a.confidence,
        ),
      );
    }
    return out;
  }

  void _openResultsFromReview() {
    final completedAt =
        DateTime.tryParse(_completedAtIso ?? '')?.toUtc() ??
            DateTime.now().toUtc();
    final result = _buildSessionResult(completedAt: completedAt);
    if (!mounted) return;
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => _webPlayerResultsPage(ctx, result),
        ),
      ),
    );
  }

  Future<void> _pushResultsScreen({required DateTime completedAt}) async {
    final result = _buildSessionResult(completedAt: completedAt);
    if (!mounted) return;
    final action = await Navigator.of(context).push<WebPlayerResultsExit>(
      MaterialPageRoute(
        builder: (ctx) => _webPlayerResultsPage(ctx, result),
      ),
    );
    if (!mounted) return;
    if (action == WebPlayerResultsExit.reattempt) {
      await _clearSaved();
      setState(() {
        _sessionCompleted = false;
        _completedAtIso = null;
        _reviewMode = false;
        _attempts.clear();
        _runStartedAt = null;
        _index = 0;
      });
      await _showModeThenWelcome();
    } else if (action == WebPlayerResultsExit.review) {
      final snap = await _readSaved();
      if (!mounted || snap == null) return;
      _applySaved(snap, forReview: true);
      setState(() => _running = true);
      _startQuestionTimer();
    }
  }

  Future<void> _maybeOfferResume() async {
    final saved = await _readSaved();
    if (!mounted) return;
    if (saved == null) {
      await _showModeThenWelcome();
      return;
    }
    if (saved['completed'] == true) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _applySaved(saved, forReview: false);
        setState(() {});
        final completedAt =
            DateTime.tryParse(saved['completedAt'] as String? ?? '')
                ?.toUtc() ??
            DateTime.now().toUtc();
        await _pushResultsScreen(completedAt: completedAt);
      });
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _sheet(
        ctx,
        title: 'Continue where you left off?',
        body:
            'We saved your progress in this browser. Resume, or start fresh from question 1.',
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applySaved(saved);
              setState(() {
                _running = true;
              });
              _startQuestionTimer();
            },
            style: WebPlayerUiTokens.primaryCta(ctx),
            child: const Text('Resume'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearSaved();
              if (!mounted) return;
              setState(() {
                _sessionCompleted = false;
                _completedAtIso = null;
                _reviewMode = false;
              });
              await _showModeThenWelcome();
            },
            style: WebPlayerUiTokens.outlineFullWidth(ctx),
            child: const Text('Start fresh'),
          ),
        ],
      ),
    );
  }

  void _applySaved(Map<String, dynamic> saved, {bool forReview = false}) {
    _timed = saved['timed'] as bool? ?? true;
    _perQuestionSecs = (saved['perQuestionSecs'] as num?)?.toInt() ?? 60;
    _sessionCompleted = saved['completed'] == true;
    _completedAtIso = saved['completedAt'] as String?;
    _sessionMode = saved['sessionMode'] as String? ?? 'learning';
    _examRemainingSecs = (saved['examRemainingSecs'] as num?)?.toInt() ?? 0;
    _examTimeLimitSecs = (saved['examTimeLimitSecs'] as num?)?.toInt();
    final startedRaw = saved['startedAt'] as String?;
    _runStartedAt =
        startedRaw != null ? DateTime.tryParse(startedRaw)?.toUtc() : null;
    _reviewMode = forReview;
    final rawIndex = (saved['currentIndex'] as num?)?.toInt() ?? 0;
    _index = (forReview ? 0 : rawIndex).clamp(0, _questions.length - 1);
    _attempts.clear();
    final am = saved['attempts'];
    if (am is Map) {
      for (final e in am.entries) {
        final v = e.value;
        if (v is Map) {
          _attempts[e.key.toString()] = _Attempt(
            selectedOption: v['selectedOption'] as String?,
            confidence: v['confidence'] as String?,
            revealed: v['revealed'] as bool? ?? false,
            examAnswered: v['examAnswered'] as bool? ?? false,
          );
        }
      }
    }
  }

  Future<void> _copyFeedbackEmailToClipboard() async {
    await Clipboard.setData(
      ClipboardData(text: AppConstants.supportEmail),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${AppConstants.supportEmail}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _launchFeedbackMail() async {
    final subject =
        '${AppConstants.appDisplayName} — shared ${_kindLabel()} feedback (id: $_shareId)';
    final body = 'Hi,\n\n'
        'Context: shared link in browser\n'
        '- Share ID: $_shareId\n'
        '- Subject: $_subject\n'
        '${_topic.isNotEmpty ? '- Topic: $_topic\n' : ''}'
        '\n';
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: <String, String>{
        'subject': subject,
        'body': body,
      },
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Could not open email. You can copy our address below.',
        ),
        action: SnackBarAction(
          label: 'Copy email',
          onPressed: () {
            unawaited(_copyFeedbackEmailToClipboard());
          },
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _finishTestRun() async {
    _stopAllTestTimers();
    _sessionCompleted = true;
    final completedAt = DateTime.now().toUtc();
    _completedAtIso = completedAt.toIso8601String();
    await _writeSaved();
    if (!mounted) return;
    setState(() {
      _running = false;
      _reviewMode = false;
    });
    await _pushResultsScreen(completedAt: completedAt);
  }

  /// Single welcome sheet — same structure as in-app test config (mode,
  /// fixed count, timed exam / per-question learning, summary).
  Future<void> _showModeThenWelcome() async {
    final kind = _linkKind ?? ShareLinkKind.parse(_kind ?? '');
    if (kind == null) {
      if (mounted) {
        setState(() => _error = 'Invalid share link kind.');
      }
      return;
    }
    if (!mounted) return;
    final outcome = await showWebPlayerWelcomeSheet(
      context: context,
      kind: kind,
      subject: _subject,
      topic: _topic.isEmpty ? null : _topic,
      questionCount: _questions.length,
      onFeedbackPressed: () => unawaited(_launchFeedbackMail()),
    );
    if (!mounted || outcome == null) return;

    final n = _questions.length;
    final budget = outcome.timed
        ? outcome.perQuestionSecs * (n == 0 ? 1 : n)
        : 0;
    setState(() {
      _sessionMode = outcome.sessionMode;
      _timed = outcome.timed;
      _perQuestionSecs = outcome.perQuestionSecs;
      _running = true;
      _index = 0;
      _attempts.clear();
      _sessionCompleted = false;
      _completedAtIso = null;
      _reviewMode = false;
      _runStartedAt = DateTime.now().toUtc();
      if (outcome.sessionMode == 'exam') {
        _examTimeLimitSecs = outcome.timed ? budget : null;
        _examRemainingSecs = outcome.timed ? budget : 0;
      } else {
        _examTimeLimitSecs = null;
        _examRemainingSecs = 0;
      }
    });
    await _clearSaved();
    _startQuestionTimer();
  }

  Widget _sheet(
    BuildContext ctx, {
    required String title,
    String? body,
    Widget? bodyChild,
    required List<Widget> actions,
  }) {
    final scheme = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.h3().copyWith(color: scheme.onSurface)),
            const SizedBox(height: AppSpacing.md),
            if (body != null)
              Text(
                body,
                style: AppTextStyles.body().copyWith(color: scheme.onSurfaceVariant),
              ),
            ?bodyChild,
            const SizedBox(height: AppSpacing.lg),
            ...actions,
          ],
        ),
      ),
    );
  }

  void _startLearningPerQuestionTimer() {
    _stopLearningTimer();
    if (_reviewMode || !_timed || !_running || _sessionMode != 'learning') {
      _remainingSecs = 0;
      setState(() {});
      return;
    }
    final att = _attempts[_questions[_index].uuid];
    if (att?.revealed == true) {
      _remainingSecs = 0;
      setState(() {});
      return;
    }
    _remainingSecs = _perQuestionSecs;
    _learningQTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final a = _attempts[_questions[_index].uuid];
      if (a?.revealed == true) {
        _stopLearningTimer();
        return;
      }
      setState(() {
        _remainingSecs = (_remainingSecs - 1).clamp(0, _perQuestionSecs);
      });
      if (_remainingSecs <= 0) {
        _stopLearningTimer();
        _onLearningTimeUp();
      }
    });
    setState(() {});
  }

  void _ensureExamGlobalTimer() {
    if (_reviewMode ||
        !_timed ||
        !_running ||
        _sessionMode != 'exam' ||
        _examTimeLimitSecs == null ||
        _examTimeLimitSecs! <= 0) {
      return;
    }
    if (_examGlobalTimer?.isActive == true) return;
    _examGlobalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _reviewMode || !_running || _sessionMode != 'exam') {
        return;
      }
      final limit = _examTimeLimitSecs ?? 0;
      if (limit <= 0) return;
      setState(() {
        _examRemainingSecs = (_examRemainingSecs - 1).clamp(0, limit);
      });
      if (_examRemainingSecs > 0 && _examRemainingSecs % 20 == 0) {
        unawaited(_writeSaved());
      }
      if (_examRemainingSecs <= 0) {
        _stopExamTimer();
        unawaited(_onExamTimeUp());
      }
    });
  }

  void _startQuestionTimer() {
    _stopLearningTimer();
    if (_reviewMode || !_running) {
      _remainingSecs = 0;
      setState(() {});
      return;
    }
    if (!_timed) {
      _remainingSecs = 0;
      if (_sessionMode == 'exam') {
        _ensureExamGlobalTimer();
      } else {
        _stopExamTimer();
      }
      setState(() {});
      return;
    }
    if (_sessionMode == 'learning') {
      _stopExamTimer();
      _startLearningPerQuestionTimer();
    } else {
      _ensureExamGlobalTimer();
      _remainingSecs = 0;
      setState(() {});
    }
  }

  Future<void> _onExamTimeUp() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test time is up. Saving your attempt…')),
    );
    await _finishTestRun();
  }

  void _onLearningTimeUp() {
    final q = _questions[_index];
    _attempts[q.uuid] = _Attempt(
      selectedOption: null,
      confidence: null,
      revealed: true,
      examAnswered: false,
    );
    unawaited(_writeSaved());
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time is up for this question.')),
    );
  }

  TestQuestion get _q => _questions[_index];

  bool _optionTapEnabled(_Attempt att) {
    if (_reviewMode) return false;
    if (_sessionMode == 'learning') return !att.revealed;
    return !att.examAnswered;
  }

  /// Normal mode: answer locks immediately; confidence is optional via strip
  /// (same pattern as in-app exam [selectOption] + [ExamOptionConfidenceStrip]).
  void _selectExamOption(String letter) {
    if (_reviewMode) return;
    final att = _attempts.putIfAbsent(_q.uuid, () => _Attempt());
    if (att.examAnswered) return;
    setState(() {
      att.selectedOption = letter;
      att.examAnswered = true;
    });
    unawaited(_writeSaved());
  }

  Future<void> _pickOption(String letter) async {
    if (_sessionMode == 'exam') {
      _selectExamOption(letter);
      return;
    }
    final att = _attempts.putIfAbsent(_q.uuid, () => _Attempt());
    if (att.revealed) return;
    _stopLearningTimer();
    setState(() {
      att.selectedOption = letter;
      att.revealed = true;
      att.confidence = null;
    });
    unawaited(_writeSaved());
  }

  QuestionTranslation _translationFor(TestQuestion q) {
    final isHi = _uiLang == 'hi';
    final sa = isHi ? q.statementAnalysisHi : q.statementAnalysis;
    return QuestionTranslation(
      finalExplanation: isHi ? q.finalExplanationHi : q.finalExplanation,
      statementAnalysis: sa
          .map(
            (e) => StatementAnalysisVm(
              statement: e.label,
              isCorrect: e.isCorrect,
              reason: e.reason,
            ),
          )
          .toList(),
      eliminationLogic: isHi ? q.eliminationLogicHi : q.eliminationLogic,
      strongDistractor: isHi ? q.strongDistractorHi : q.strongDistractor,
      upscTrapExplanation: isHi ? q.upscTrapExplanationHi : q.upscTrapExplanation,
      conceptsUsed: q.conceptsUsed,
    );
  }

  Future<void> _next() async {
    if (_index >= _questions.length - 1) {
      if (_reviewMode) {
        await _writeSaved();
        if (!mounted) return;
        _stopAllTestTimers();
        setState(() {
          _running = false;
          _reviewMode = false;
        });
        final completedAt =
            DateTime.tryParse(_completedAtIso ?? '')?.toUtc() ??
                DateTime.now().toUtc();
        await _pushResultsScreen(completedAt: completedAt);
        return;
      }
      await _finishTestRun();
      return;
    }
    setState(() => _index++);
    _startQuestionTimer();
    unawaited(_writeSaved());
  }

  void _prev() {
    if (_index <= 0) return;
    setState(() => _index--);
    _startQuestionTimer();
    unawaited(_writeSaved());
  }

  int _furthestRevealedIndex() {
    var m = -1;
    for (var i = 0; i < _questions.length; i++) {
      if (_attempts[_questions[i].uuid]?.revealed == true) m = i;
    }
    return m;
  }

  int _furthestExamAnsweredIndex() {
    var m = -1;
    for (var i = 0; i < _questions.length; i++) {
      if (_attempts[_questions[i].uuid]?.examAnswered == true) m = i;
    }
    return m;
  }

  bool _canGoNext(_Attempt att) {
    final last = _index >= _questions.length - 1;
    if (_reviewMode) {
      return true;
    }
    if (_sessionMode == 'learning') {
      if (last) return att.revealed;
      return att.revealed || _index < _furthestRevealedIndex();
    }
    // Exam (in-app): Next disabled on last question — use Submit / grid.
    if (last) return false;
    return att.examAnswered || _index < _furthestExamAnsweredIndex();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (!_running && _questions.isNotEmpty) {
      final scheme = Theme.of(context).colorScheme;
      final isDark = context.isDarkMode;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shared practice'),
          actions: [
            InkWell(
              onTap: widget.onToggleTheme,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              _sessionCompleted
                  ? 'Use the back button on the results screen, or refresh the link.'
                  : 'Pick Normal or Learning to begin.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    final q = _q;
    final att = _attempts.putIfAbsent(q.uuid, () => _Attempt());
    final scheme = Theme.of(context).colorScheme;
    final isHi = _uiLang == 'hi';
    final stem = isHi ? q.displayTextHi : q.displayText;
    final table = isHi ? q.tableDataHi : q.tableData;

    final contextLine =
        _topic.isNotEmpty ? '$_subject · $_topic' : _subject;
    final stemTrimmed = stem.trim();
    final revealKey =
        _reviewMode || (_sessionMode == 'learning' && att.revealed);
    final learningTimedOut =
        _sessionMode == 'learning' &&
        att.revealed &&
        att.selectedOption == null;
    final timedOut = revealKey && learningTimedOut;
    final showVerdictBlock =
        _reviewMode || (_sessionMode == 'learning' && att.revealed);

    String verdictTitle() {
      if (att.selectedOption != null) {
        return att.selectedOption == q.correctOption.toLowerCase()
            ? 'Correct'
            : 'Incorrect';
      }
      if (_sessionMode == 'learning' && att.revealed) return 'Timed out';
      if (_reviewMode && _sessionMode == 'exam' && !att.examAnswered) {
        return 'Unattempted';
      }
      return 'Timed out';
    }

    Color verdictColor() {
      if (att.selectedOption != null) {
        return att.selectedOption == q.correctOption.toLowerCase()
            ? AppColors.correctText
            : AppColors.wrongText;
      }
      if (_reviewMode && _sessionMode == 'exam' && !att.examAnswered) {
        return scheme.onSurfaceVariant;
      }
      return AppColors.wrongText;
    }

    return Scaffold(
      appBar: _reviewMode
          ? AppBar(
              title: GestureDetector(
                onTap: _openResultsFromReview,
                child: const Text('Review explanations'),
              ),
              leading: IconButton(
                style: IconButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                ),
                onPressed: _openResultsFromReview,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            )
          : null,
      body: SafeArea(
        top: !_reviewMode,
        child: Column(
          children: [
            WebPlayerSessionChrome(
              currentIndex: _index,
              totalQuestions: _questions.length,
              contextLine: contextLine,
              uiLanguage: _uiLang,
              onLanguageChanged: (v) => setState(() => _uiLang = v),
              onOpenQuestionGrid: _openQuestionGrid,
              onToggleDarkMode: widget.onToggleTheme,
              timed: _timed,
              remainingSecs: _remainingSecs,
              examRemainingSecs: _examRemainingSecs,
              sessionMode: _sessionMode,
              reviewMode: _reviewMode,
              onSubmitTest: !_reviewMode ? _openQuestionGrid : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stemTrimmed.isNotEmpty)
                      SelectableCopySearchText(
                        stemTrimmed,
                        style: AppTextStyles.question().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    if (q.hasTable && table != null) ...[
                      SizedBox(
                        height: stemTrimmed.isNotEmpty
                            ? AppSpacing.sm
                            : AppSpacing.xs,
                      ),
                      QuestionTableView(table: table),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    for (final L in const ['a', 'b', 'c', 'd']) ...[
                      WebPlayerOptionTile(
                        keyLabel: L.toUpperCase(),
                        optionText: switch (L) {
                          'a' => isHi ? q.optionAHi : q.optionA,
                          'b' => isHi ? q.optionBHi : q.optionB,
                          'c' => isHi ? q.optionCHi : q.optionC,
                          _ => isHi ? q.optionDHi : q.optionD,
                        },
                        visual: webPlayerOptionVisual(
                          q: q,
                          optionKey: L,
                          revealAnswerKey: revealKey,
                          selectedOption: att.selectedOption,
                          timedOut: timedOut,
                        ),
                        onTap: _optionTapEnabled(att)
                            ? () => unawaited(_pickOption(L))
                            : null,
                        confidenceStored: att.confidence,
                        showConfidenceHeader: false,
                        confidenceFooter: !_reviewMode &&
                                att.selectedOption != null &&
                                att.selectedOption == L &&
                                ((_sessionMode == 'exam' &&
                                        att.examAnswered) ||
                                    (_sessionMode == 'learning' &&
                                        att.revealed))
                            ? WebPlayerExamConfidenceStrip(
                                confidence: att.confidence,
                                enabled: _sessionMode == 'exam' ||
                                    att.confidence == null ||
                                    !att.revealed,
                                onTierPressed: (tier) {
                                  final next =
                                      att.confidence == tier ? null : tier;
                                  setState(() => att.confidence = next);
                                  unawaited(_writeSaved());
                                },
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (showVerdictBlock) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        verdictTitle(),
                        style: AppTextStyles.h3().copyWith(
                          color: verdictColor(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: ColoredBox(
                          color: scheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: ExplanationCard(
                              translation: _translationFor(q),
                              showStatements:
                                  (isHi
                                          ? q.statementAnalysisHi
                                          : q.statementAnalysis)
                                      .isNotEmpty,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: WebPlayerUiTokens.outlineFullWidth(context),
                  onPressed: _index > 0 ? _prev : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Prev'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: null,
                tooltip: 'Bookmarks available in the ${AppConstants.appDisplayName} app',
                icon: Icon(
                  Icons.bookmark_border,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: WebPlayerUiTokens.outlineFullWidth(context),
                  onPressed: _canGoNext(att) ? _next : null,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: Text(
                    _sessionMode == 'exam' && !_reviewMode
                        ? 'Next'
                        : (_index >= _questions.length - 1 ? 'Finish' : 'Next'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuestionGrid() {
    final showSubmit = !_reviewMode;
    unawaited(
      showWebPlayerQuestionGridSheet(
        context: context,
        questions: _questions,
        attemptFor: (uuid) {
          final a = _attempts[uuid];
          if (a == null) {
            return (
              revealed: false,
              examAnswered: false,
              selectedOption: null,
              confidence: null,
            );
          }
          return (
            revealed: a.revealed,
            examAnswered: a.examAnswered,
            selectedOption: a.selectedOption,
            confidence: a.confidence,
          );
        },
        currentIndex: _index,
        onJumpToIndex: (i) {
          setState(() => _index = i);
          _startQuestionTimer();
          unawaited(_writeSaved());
        },
        showSubmitPanel: showSubmit,
        isExamMode: _sessionMode == 'exam',
        onSubmitTest: showSubmit ? () => _finishTestRun() : null,
      ),
    );
  }
}
