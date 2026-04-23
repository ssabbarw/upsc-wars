import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/session_summary.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../providers/subject_detail_providers.dart';
import '../widgets/subject_session_summary_row.dart';

/// Paginated completed-session list for one subject.
class SubjectHistoryScreen extends ConsumerStatefulWidget {
  const SubjectHistoryScreen({super.key, required this.subject});

  final String subject;

  static const int pageSize = 20;

  @override
  ConsumerState<SubjectHistoryScreen> createState() =>
      _SubjectHistoryScreenState();
}

class _SubjectHistoryScreenState extends ConsumerState<SubjectHistoryScreen> {
  final _scrollController = ScrollController();
  final _items = <SessionSummary>[];
  var _initialLoading = true;
  var _loadingMore = false;
  var _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadFirstPage());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _initialLoading || _error != null) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadFirstPage({bool isPullRefresh = false}) async {
    if (!isPullRefresh) {
      setState(() {
        _initialLoading = true;
        _error = null;
        _items.clear();
        _hasMore = true;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      final repo = ref.read(sessionHistoryRepositoryProvider);
      final page = await repo.getCompletedSessionSummariesPage(
        subject: widget.subject,
        limit: SubjectHistoryScreen.pageSize,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page);
        _hasMore = page.length >= SubjectHistoryScreen.pageSize;
        _initialLoading = false;
      });
      ref.invalidate(subjectCompletedSessionCountProvider(widget.subject));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!isPullRefresh) _error = e;
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _initialLoading) return;
    setState(() => _loadingMore = true);
    try {
      final repo = ref.read(sessionHistoryRepositoryProvider);
      final page = await repo.getCompletedSessionSummariesPage(
        subject: widget.subject,
        limit: SubjectHistoryScreen.pageSize,
        offset: _items.length,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length >= SubjectHistoryScreen.pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subjectDef = SubjectConstants.bySlug(widget.subject);
    final displayName = subjectDef?.displayName ?? widget.subject;
    final infoAsync = ref.watch(subjectInfoProvider(widget.subject));

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test history', style: AppTextStyles.h3()),
            Text(
              displayName,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFirstPage(isPullRefresh: true),
        child: _error != null && _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const SizedBox(height: AppSpacing.xxxl),
                  Icon(
                    Icons.error_outline,
                    size: 40,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Could not load history.',
                    style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: OutlinedButton(
                      onPressed: _loadFirstPage,
                      child: Text('Retry', style: AppTextStyles.label()),
                    ),
                  ),
                ],
              )
            : _initialLoading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.25,
                  ),
                  Icon(
                    Icons.history_outlined,
                    size: 40,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No completed sessions yet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label().copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Start a test to see your results here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: infoAsync.when(
                      data: (info) {
                        if (info == null) {
                          return const SizedBox.shrink();
                        }
                        return OutlinedButton(
                          onPressed: () {
                            showTestConfigBottomSheet(
                              context: context,
                              args: TestConfigSheetArgs(
                                subject: widget.subject,
                                subjectDisplayName: displayName,
                                availableQuestionCount: info.questionCount,
                                topicCountWhenSubjectOnly: info.topicCount,
                                onSessionCreated: (id) =>
                                    context.push('/test/$id'),
                              ),
                            );
                          },
                          child: Text('Start a test', style: AppTextStyles.label()),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                itemCount: _items.length + (_loadingMore || _hasMore ? 1 : 0),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.cardListGap),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    if (_loadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: () => unawaited(_loadMore()),
                          child: Text('Load more', style: AppTextStyles.label()),
                        ),
                      ),
                    );
                  }
                  return SubjectSessionSummaryRow(
                    session: _items[index],
                    borderColor: borderColor,
                  );
                },
              ),
      ),
    );
  }
}
