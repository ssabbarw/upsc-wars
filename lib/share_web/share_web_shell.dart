import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:upsc_wars/core/deep_link/share_link_kind.dart';
import 'package:upsc_wars/core/deep_link/shared_session_firestore.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/domain/entities/test_question_share_map.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/core/theme/app_theme.dart';
import 'package:upsc_wars/features/history/widgets/explanation_card.dart';
import 'package:upsc_wars/share_web/share_web_session_chrome.dart';
import 'package:upsc_wars/web_player/web_player_welcome_sheet.dart';
import 'package:upsc_wars/shared/extensions/context_extensions.dart';
import 'package:upsc_wars/shared/widgets/question_table_view.dart';
import 'package:upsc_wars/core/constants/app_constants.dart';
import 'package:upsc_wars/shared/widgets/selectable_copy_search_text.dart';

class ShareWebRoot extends StatefulWidget {
  const ShareWebRoot({super.key});

  @override
  State<ShareWebRoot> createState() => _ShareWebRootState();
}

class _ShareWebRootState extends State<ShareWebRoot> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.appDisplayName} — Shared practice',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: ShareWebShell(
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
  _Attempt({this.selectedOption, this.confidence, this.revealed = false});

  String? selectedOption;
  String? confidence;
  bool revealed;
}

class ShareWebShell extends StatefulWidget {
  const ShareWebShell({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<ShareWebShell> createState() => _ShareWebShellState();
}

class _ShareWebShellState extends State<ShareWebShell>
    with TickerProviderStateMixin {
  static const _prefsPrefix = 'share_web_prog_v2_';

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
  Timer? _timer;
  final Map<String, _Attempt> _attempts = {};

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
    _timer?.cancel();
    super.dispose();
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
        'attempts': attemptsJson,
      }),
    );
  }

  Future<void> _clearSaved() async {
    if (_shareId == null) return;
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefsKey());
  }

  Future<void> _maybeOfferResume() async {
    final saved = await _readSaved();
    if (!mounted) return;
    if (saved == null) {
      await _showUnifiedWelcome();
      return;
    }
    if (saved['completed'] == true) {
      await _showPostCompletionSheet(saved: saved);
      if (!mounted) return;
      final disk = await _readSaved();
      if (disk != null && disk['completed'] == true) {
        setState(() {
          _sessionCompleted = true;
          _completedAtIso = disk['completedAt'] as String?;
        });
      }
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
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applySaved(saved);
              setState(() {
                _running = true;
              });
              _startQuestionTimer();
            },
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
              await _showUnifiedWelcome();
            },
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
          );
        }
      }
    }
  }

  String _scoreSummaryFromSaved(Map<String, dynamic> saved) {
    final am = saved['attempts'];
    if (am is! Map || _questions.isEmpty) {
      return '${_questions.length} questions';
    }
    var correct = 0;
    var incorrect = 0;
    var timedOut = 0;
    for (final q in _questions) {
      final raw = am[q.uuid];
      if (raw is! Map) {
        timedOut++;
        continue;
      }
      final sel = raw['selectedOption'] as String?;
      final rev = raw['revealed'] as bool? ?? false;
      if (!rev) {
        timedOut++;
        continue;
      }
      if (sel == null) {
        timedOut++;
      } else if (sel == q.correctOption.toLowerCase()) {
        correct++;
      } else {
        incorrect++;
      }
    }
    return '$correct correct · $incorrect wrong · $timedOut timed out / unanswered'
        '\n(${_questions.length} questions)';
  }

  String? _humanCompletedAt(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toLocal();
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    } catch (_) {
      return null;
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

  Future<void> _showPostCompletionSheet({
    required Map<String, dynamic> saved,
  }) async {
    if (!mounted) return;
    final when = _humanCompletedAt(saved['completedAt'] as String?);
    final score = _scoreSummaryFromSaved(saved);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _sheet(
        ctx,
        title: 'This set is complete',
        body:
            '${when != null ? 'Finished on $when.\n\n' : ''}$score\n\n'
            'Reattempt clears this browser’s answers and starts from question 1. '
            'Review walks through your last attempt with explanations.',
        actions: [
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
              await _showUnifiedWelcome();
            },
            child: const Text('Reattempt'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applySaved(saved, forReview: true);
              setState(() => _running = true);
              _startQuestionTimer();
            },
            child: const Text('Review'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => unawaited(_launchFeedbackMail()),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Send feedback to team'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishTestRun() async {
    _sessionCompleted = true;
    _completedAtIso = DateTime.now().toUtc().toIso8601String();
    await _writeSaved();
    if (!mounted) return;
    setState(() {
      _running = false;
      _reviewMode = false;
    });
    final snap = await _readSaved();
    if (!mounted || snap == null) return;
    await _showPostCompletionSheet(saved: snap);
  }

  /// One welcome sheet (learning-only for legacy share web).
  Future<void> _showUnifiedWelcome() async {
    if (!mounted) return;
    final kind = _linkKind ?? ShareLinkKind.parse(_kind ?? '');
    if (kind == null) {
      setState(() => _error = 'Invalid share link kind.');
      return;
    }
    final outcome = await showWebPlayerWelcomeSheet(
      context: context,
      kind: kind,
      subject: _subject,
      topic: _topic.isEmpty ? null : _topic,
      questionCount: _questions.length,
      learningOnly: true,
      onFeedbackPressed: () => unawaited(_launchFeedbackMail()),
    );
    if (!mounted || outcome == null) return;
    setState(() {
      _timed = outcome.timed;
      _perQuestionSecs = outcome.perQuestionSecs;
      _running = true;
      _index = 0;
      _attempts.clear();
      _sessionCompleted = false;
      _completedAtIso = null;
      _reviewMode = false;
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

  void _startQuestionTimer() {
    _timer?.cancel();
    if (_reviewMode || !_timed || !_running) {
      _remainingSecs = 0;
      setState(() {});
      return;
    }
    _remainingSecs = _perQuestionSecs;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final att = _attempts[_questions[_index].uuid];
      if (att?.revealed == true) {
        _timer?.cancel();
        return;
      }
      setState(() {
        _remainingSecs = (_remainingSecs - 1).clamp(0, _perQuestionSecs);
      });
      if (_remainingSecs <= 0) {
        _timer?.cancel();
        _onTimeUp();
      }
    });
    setState(() {});
  }

  void _onTimeUp() {
    final q = _questions[_index];
    _attempts[q.uuid] = _Attempt(
      selectedOption: null,
      confidence: null,
      revealed: true,
    );
    unawaited(_writeSaved());
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time is up for this question.')),
    );
  }

  TestQuestion get _q => _questions[_index];

  Future<void> _pickOption(String letter) async {
    final att = _attempts.putIfAbsent(_q.uuid, () => _Attempt());
    if (att.revealed) return;
    att.selectedOption = letter;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                Text(
                  'How sure are you?',
                  style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pick before you see the answer — this builds your Danger Zone map.',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    att.confidence = AnswerConfidence.verySure;
                    Navigator.pop(ctx);
                    _reveal();
                  },
                  child: Text(
                    AnswerConfidence.examShortLabel(AnswerConfidence.verySure),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () {
                    att.confidence = AnswerConfidence.somewhatSure;
                    Navigator.pop(ctx);
                    _reveal();
                  },
                  child: Text(
                    AnswerConfidence.examShortLabel(
                      AnswerConfidence.somewhatSure,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {
                    att.confidence = AnswerConfidence.guessing;
                    Navigator.pop(ctx);
                    _reveal();
                  },
                  child: Text(
                    AnswerConfidence.examShortLabel(AnswerConfidence.guessing),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    setState(() {});
  }

  void _reveal() {
    _timer?.cancel();
    final att = _attempts[_q.uuid]!;
    att.revealed = true;
    unawaited(_writeSaved());
    setState(() {});
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
        setState(() {
          _running = false;
          _reviewMode = false;
        });
        final snap = await _readSaved();
        if (!mounted || snap == null) return;
        await _showPostCompletionSheet(saved: snap);
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
        body: const Center(child: SizedBox.shrink()),
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
    final timedOut = att.revealed && att.selectedOption == null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ShareWebSessionChrome(
              currentIndex: _index,
              totalQuestions: _questions.length,
              contextLine: contextLine,
              uiLanguage: _uiLang,
              onLanguageChanged: (v) => setState(() => _uiLang = v),
              onOpenQuestionGrid: _openQuestionGrid,
              onToggleDarkMode: widget.onToggleTheme,
              timed: _timed,
              remainingSecs: _remainingSecs,
              reviewMode: _reviewMode,
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
                      ShareWebOptionTile(
                        keyLabel: L.toUpperCase(),
                        optionText: switch (L) {
                          'a' => isHi ? q.optionAHi : q.optionA,
                          'b' => isHi ? q.optionBHi : q.optionB,
                          'c' => isHi ? q.optionCHi : q.optionC,
                          _ => isHi ? q.optionDHi : q.optionD,
                        },
                        visual: shareWebOptionVisual(
                          q: q,
                          optionKey: L,
                          revealed: att.revealed,
                          selectedOption: att.selectedOption,
                          timedOut: timedOut,
                        ),
                        onTap: att.revealed ? null : () => _pickOption(L),
                        confidenceStored: att.confidence,
                        showConfidenceHeader:
                            att.revealed &&
                            att.selectedOption != null &&
                            att.selectedOption == L,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (att.revealed) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        (att.selectedOption != null &&
                                att.selectedOption ==
                                    q.correctOption.toLowerCase())
                            ? 'Correct'
                            : (att.selectedOption == null
                                  ? 'Timed out'
                                  : 'Incorrect'),
                        style: AppTextStyles.h3().copyWith(
                          color:
                              (att.selectedOption != null &&
                                  att.selectedOption ==
                                      q.correctOption.toLowerCase())
                              ? AppColors.correctText
                              : AppColors.wrongText,
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
                  onPressed: _canGoNext(att) ? _next : null,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: Text(
                    _index >= _questions.length - 1 ? 'Finish' : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _furthestRevealedIndex() {
    var m = -1;
    for (var i = 0; i < _questions.length; i++) {
      if (_attempts[_questions[i].uuid]?.revealed == true) m = i;
    }
    return m;
  }

  bool _canGoNext(_Attempt att) {
    final last = _index >= _questions.length - 1;
    if (last) return att.revealed;
    return att.revealed || _index < _furthestRevealedIndex();
  }

  void _openQuestionGrid() {
    unawaited(
      showShareWebQuestionGridSheet(
        context: context,
        questions: _questions,
        attemptFor: (uuid) {
          final a = _attempts[uuid];
          if (a == null) {
            return (
              revealed: false,
              selectedOption: null,
              confidence: null,
            );
          }
          return (
            revealed: a.revealed,
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
      ),
    );
  }
}
