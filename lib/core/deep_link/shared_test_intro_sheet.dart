import 'package:flutter/material.dart';

import 'package:upsc_wars/core/deep_link/shared_session_firestore.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

/// Result of the colorful shared-test landing (name + Top 5 leaderboard).
class SharedTestIntroOutcome {
  const SharedTestIntroOutcome({required this.participantName});

  final String participantName;
}

String capitalizeShareDisplayName(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  final parts = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
  return parts
      .map((w) {
        final lower = w.toLowerCase();
        if (lower.length == 1) return lower.toUpperCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

/// Name entry + green Top-5 leaderboard. Same landing as the web player.
Future<SharedTestIntroOutcome?> showSharedTestIntroSheet({
  required BuildContext context,
  required String sharedBy,
  required String subject,
  String? topic,
  required int questionCount,
  required List<SharedLeaderboardEntry> leaderboard,
  String initialName = '',
  bool dismissible = false,
}) {
  return showModalBottomSheet<SharedTestIntroOutcome>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: dismissible,
    enableDrag: dismissible,
    builder: (ctx) => _SharedTestIntroSheetBody(
      sharedBy: sharedBy,
      subject: subject,
      topic: topic,
      questionCount: questionCount,
      leaderboard: leaderboard,
      initialName: initialName,
      dismissible: dismissible,
    ),
  );
}

class _SharedTestIntroSheetBody extends StatefulWidget {
  const _SharedTestIntroSheetBody({
    required this.sharedBy,
    required this.subject,
    required this.topic,
    required this.questionCount,
    required this.leaderboard,
    required this.initialName,
    required this.dismissible,
  });

  final String sharedBy;
  final String subject;
  final String? topic;
  final int questionCount;
  final List<SharedLeaderboardEntry> leaderboard;
  final String initialName;
  final bool dismissible;

  @override
  State<_SharedTestIntroSheetBody> createState() =>
      _SharedTestIntroSheetBodyState();
}

class _SharedTestIntroSheetBodyState extends State<_SharedTestIntroSheetBody> {
  late final TextEditingController _controller;
  String _validationError = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _validationError =
            "If you don't want to give your name, enter any random name";
      });
      return;
    }
    Navigator.pop(
      context,
      SharedTestIntroOutcome(
        participantName: capitalizeShareDisplayName(name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topic = widget.topic?.trim() ?? '';
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Before you begin',
                        style: AppTextStyles.h3().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (widget.dismissible)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${widget.sharedBy} shared this test with you.',
                  style: AppTextStyles.body().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  autofocus: _controller.text.trim().isEmpty,
                  decoration: InputDecoration(
                    labelText: 'Your name',
                    hintText: 'Enter your display name',
                    errorText: _validationError.isEmpty ? null : _validationError,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.correct,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Leaderboard · Top 5',
                            style: AppTextStyles.label().copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (widget.leaderboard.isEmpty)
                        Text(
                          'Be the first to take this test.',
                          style: AppTextStyles.bodySm().copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        )
                      else
                        for (
                          var i = 0;
                          i < widget.leaderboard.length && i < 5;
                          i++
                        )
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    '#${i + 1}',
                                    style: AppTextStyles.caption().copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    widget.leaderboard[i].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySm().copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '${widget.leaderboard[i].score.toStringAsFixed(1)}%',
                                  style: AppTextStyles.bodySm().copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 0.6,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are about to start a shared practice test.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        topic.isNotEmpty
                            ? 'Subject: ${widget.subject} · $topic'
                            : 'Subject: ${widget.subject}',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Questions: ${widget.questionCount}',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
