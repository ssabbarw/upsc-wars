import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/deep_link/share_session_opener.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

/// Shows a bottom sheet to share a test with friends.
///
/// Steps:
/// 1. Intro explanation.
/// 2. Loader while generating the link.
/// 3. Success with the link and copy button.
Future<void> showShareTestBottomSheet({
  required BuildContext context,
  required String sessionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ShareTestBottomSheetBody(sessionId: sessionId),
  );
}

class _ShareTestBottomSheetBody extends ConsumerStatefulWidget {
  const _ShareTestBottomSheetBody({required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<_ShareTestBottomSheetBody> createState() =>
      _ShareTestBottomSheetBodyState();
}

class _ShareTestBottomSheetBodyState
    extends ConsumerState<_ShareTestBottomSheetBody> {
  bool _isLoading = false;
  Uri? _generatedUri;

  Future<void> _generateLink() async {
    setState(() => _isLoading = true);
    try {
      final uri = await createShareLinkForSession(
        ref: ref,
        sessionId: widget.sessionId,
      );
      if (mounted) {
        setState(() {
          _generatedUri = uri;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Share Test',
                    style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_isLoading && _generatedUri == null) ...[
              Text(
                'You can share this test with your friends. You will get a shareable link.',
                style: AppTextStyles.body().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _generateLink,
                child: const Text('Generate'),
              ),
            ] else if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              Text(
                'Generating your shareable link...',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else if (_generatedUri != null) ...[
              Text(
                'Your shareable link is ready!',
                style: AppTextStyles.body().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedUri.toString(),
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _copyToClipboard(_generatedUri.toString()),
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: 'Copy to clipboard',
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
