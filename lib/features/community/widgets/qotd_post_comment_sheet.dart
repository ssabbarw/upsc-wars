import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../domain/qotd_comment_rules.dart';

class QotdPostCommentResult {
  const QotdPostCommentResult._({
    required this.posted,
    required this.needsSignIn,
    required this.comment,
  });

  const QotdPostCommentResult.posted()
      : this._(posted: true, needsSignIn: false, comment: '');

  const QotdPostCommentResult.dismissed()
      : this._(posted: false, needsSignIn: false, comment: '');

  const QotdPostCommentResult.needsSignIn(String comment)
      : this._(posted: false, needsSignIn: true, comment: comment);

  final bool posted;
  final bool needsSignIn;
  final String comment;
}

/// Bottom sheet: optional comment with hint; empty or ≥50 chars after normalize; no newlines.
///
/// Unsigned users can draft a comment; tapping Post closes with [needsSignIn]
/// so the caller can sign them in and re-open with [initialComment].
Future<QotdPostCommentResult> showQotdPostCommentSheet(
  BuildContext context, {
  required Future<void> Function(String comment) onPost,
  String initialComment = '',
}) async {
  final result = await showModalBottomSheet<QotdPostCommentResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _QotdPostCommentSheetContent(
      onPost: onPost,
      initialComment: initialComment,
    ),
  );
  return result ?? const QotdPostCommentResult.dismissed();
}

class _QotdPostCommentSheetContent extends StatefulWidget {
  const _QotdPostCommentSheetContent({
    required this.onPost,
    required this.initialComment,
  });

  final Future<void> Function(String comment) onPost;
  final String initialComment;

  @override
  State<_QotdPostCommentSheetContent> createState() =>
      _QotdPostCommentSheetContentState();
}

class _QotdPostCommentSheetContentState
    extends State<_QotdPostCommentSheetContent> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final text = QotdCommentRules.normalize(_controller.text);
    if (!AuthSession.isCurrentAccountSignedIn()) {
      Navigator.of(context).pop(QotdPostCommentResult.needsSignIn(text));
      return;
    }
    setState(() => _isPosting = true);
    try {
      await widget.onPost(text);
      if (!mounted) return;
      Navigator.of(context).pop(const QotdPostCommentResult.posted());
    } catch (e, st) {
      debugPrint('QOTD post failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() => _isPosting = false);
      AppToast.showText(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final signedIn = AuthSession.isCurrentAccountSignedIn();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: sheetBottomPadding(context, base: AppSpacing.lg),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Post to QOTD', style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Optional note for the community. You learned something new? '
                'Spotted something ironic? A concept felt challenged? '
                'Be specific — or leave this blank.',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _controller,
                maxLines: 4,
                minLines: 2,
                enabled: !_isPosting,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                  LengthLimitingTextInputFormatter(
                    QotdCommentRules.maxLength,
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  hintText: 'Leave blank, or write at least 50 characters…',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: QotdCommentRules.validateField,
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, v, _) {
                  final n = QotdCommentRules.normalize(v.text).length;
                  final need = QotdCommentRules.minLengthWhenNonEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n > 0 && n < need)
                          Text(
                            '${need - n} more characters to reach $need, '
                            'or clear the field to post without a comment.',
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.error,
                            ),
                          ),
                        Text(
                          '$n / ${QotdCommentRules.maxLength}',
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (!signedIn) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign in to post. Your comment is kept.',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _isPosting ? null : _submit,
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(signedIn ? 'Post' : 'Sign in to post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
