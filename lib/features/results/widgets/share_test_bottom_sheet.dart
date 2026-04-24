import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:upsc_wars/core/deep_link/share_session_opener.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/shared/widgets/contact_us_entry.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/shared/widgets/app_toast.dart';

/// Shows a bottom sheet to share a test with friends.
///
/// Steps:
/// 1. Intro explanation.
/// 2. Loader while generating the link.
/// 3. Success with the link and copy button.
Future<void> showShareTestBottomSheet({
  required BuildContext context,
  required String sessionId,
  TestQuestion? question,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ShareTestBottomSheetBody(
      sessionId: sessionId,
      question: question,
    ),
  );
}

class _ShareTestBottomSheetBody extends ConsumerStatefulWidget {
  const _ShareTestBottomSheetBody({
    required this.sessionId,
    this.question,
  });
  final String sessionId;
  final TestQuestion? question;

  @override
  ConsumerState<_ShareTestBottomSheetBody> createState() =>
      _ShareTestBottomSheetBodyState();
}

class _ShareTestBottomSheetBodyState
    extends ConsumerState<_ShareTestBottomSheetBody> {
  bool _isLoading = false;
  String _selectedType = 'entire';
  final Map<String, Uri?> _links = {};

  @override
  void initState() {
    super.initState();
    // Default to 'question' if provided, else 'entire'.
    _selectedType = widget.question != null ? 'question' : 'entire';
    // Auto-generate for the default selection.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateLink(_selectedType);
    });
  }

  Future<void> _generateLink(String type) async {
    if (_links[type] != null) {
      setState(() => _selectedType = type);
      return;
    }

    setState(() {
      _selectedType = type;
      _isLoading = true;
    });

    try {
      final uri = type == 'entire'
          ? await createShareLinkForSession(
              ref: ref,
              sessionId: widget.sessionId,
            )
          : await createShareLinkForTestQuestion(
              ref: ref,
              question: widget.question!,
            );

      if (mounted) {
        setState(() {
          _links[type] = uri;
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
      AppToast.showText(
        context,
        'Link copied to clipboard',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasQuestion = widget.question != null;
    final currentUri = _links[_selectedType];

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
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.ios_share_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Share Test',
                    style: AppTextStyles.h3().copyWith(
                      color: scheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (hasQuestion && widget.sessionId.isNotEmpty) ...[
              Row(
                children: [
                  _ModeCard(
                    label: 'Question',
                    icon: Icons.quiz_outlined,
                    isSelected: _selectedType == 'question',
                    onTap: () => _generateLink('question'),
                    scheme: scheme,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _ModeCard(
                    label: 'Entire Test',
                    icon: Icons.assignment_outlined,
                    isSelected: _selectedType == 'entire',
                    onTap: () => _generateLink('entire'),
                    scheme: scheme,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? _buildLoadingState(scheme)
                  : currentUri != null
                      ? _buildSuccessState(currentUri, scheme, isDark)
                      : _buildErrorState(scheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme scheme) {
    return Column(
      key: const ValueKey('loading'),
      children: [
        const SizedBox(height: AppSpacing.xl),
        CircularProgressIndicator(strokeWidth: 3, color: scheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Generating link...',
          style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildSuccessState(Uri uri, ColorScheme scheme, bool isDark) {
    final isQuestion = _selectedType == 'question';
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isQuestion) ...[
          _buildInfoRow(
            scheme,
            Icons.people_outline_rounded,
            'You can share this link with your friends.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            scheme,
            Icons.bug_report_outlined,
            'You can use this link to report any error in this question to the upsc wars team.',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  uri.toString(),
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(uri.toString()),
                icon: const Icon(Icons.copy_all_rounded, size: 20),
                tooltip: 'Copy',
                color: scheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            if (isQuestion) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showContactUsSheet(context),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('Contact Us'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  SharePlus.instance.share(ShareParams(uri: uri));
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Link'),
              ),
            ),
          ],
        ),
        if (!isQuestion) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(ColorScheme scheme, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ColorScheme scheme) {
    return Column(
      key: const ValueKey('error'),
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Failed to generate link',
          style: AppTextStyles.body().copyWith(color: scheme.error),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () => _generateLink(_selectedType),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.1)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.label().copyWith(
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
