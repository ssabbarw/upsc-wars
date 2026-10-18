import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../test_series/data/test_series_promo_admin_service.dart';
import '../../test_series/providers/test_series_providers.dart';

final _dateTimeFmt = DateFormat('d MMM yyyy, h:mm a');
final _dateFmt = DateFormat('d MMM yyyy');

DateTime? _ts(Object? v) => v is Timestamp ? v.toDate() : null;

/// Super-user screen: promo codes that unlock the Prelims Test Series for free
/// (for example one per influencer). Each code can have a redemption limit and
/// an expiry date; after either, the app shows "Code expired" / "Code limit
/// reached". Tap a code to see who redeemed it.
class TestSeriesPromosAdminScreen extends HookConsumerWidget {
  const TestSeriesPromosAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(activeSeriesIdProvider);
    final service = useMemoized(TestSeriesPromoAdminService.new);

    return Scaffold(
      appBar: AppBar(title: const Text('Offer codes')),
      body: seriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Could not read the active series.\n$e')),
        data: (seriesId) => _CodeList(service: service),
      ),
      floatingActionButton: seriesAsync.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => unawaited(
                _createCode(context, service, seriesAsync.requireValue),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New code'),
            )
          : null,
    );
  }
}

Future<void> _createCode(
  BuildContext context,
  TestSeriesPromoAdminService service,
  String seriesId,
) async {
  final input = await showDialog<_CodeInput>(
    context: context,
    builder: (_) => const _CreateCodeDialog(),
  );
  if (input == null || !context.mounted) return;
  try {
    final code = await service.createCode(
      seriesId: seriesId,
      label: input.label,
      code: input.code,
      maxRedemptions: input.maxRedemptions,
      expiresAt: input.expiresAt,
    );
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      AppToast.showText(context, 'Created $code (copied to clipboard).');
    }
  } on Object catch (e) {
    if (context.mounted) {
      AppToast.showText(context, TestSeriesPromoAdminService.describe(e));
    }
  }
}

enum _CodeStatus { active, expired, limitReached, disabled }

class _CodeList extends StatelessWidget {
  const _CodeList({required this.service});

  final TestSeriesPromoAdminService service;

  @override
  Widget build(BuildContext context) {
    final promos = FirebaseFirestore.instance
        .collection('test_series_promos')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: promos,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Could not load codes: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No codes yet. Tap "New code", then give it to an influencer.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        var total = 0;
        for (final d in docs) {
          total += (d.data()['redemptionCount'] as num?)?.toInt() ?? 0;
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            96,
          ),
          children: [
            Text(
              '${docs.length} ${docs.length == 1 ? 'code' : 'codes'} · '
              '$total redeemed in total',
              style: AppTextStyles.caption(),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final d in docs) _CodeTile(doc: d, service: service),
          ],
        );
      },
    );
  }
}

class _CodeTile extends StatelessWidget {
  const _CodeTile({required this.doc, required this.service});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final TestSeriesPromoAdminService service;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final code = doc.id;
    final label = d['label']?.toString() ?? '';
    final count = (d['redemptionCount'] as num?)?.toInt() ?? 0;
    final max = (d['maxRedemptions'] as num?)?.toInt();
    final enabled = d['active'] == true;
    final expiresAt = _ts(d['expiresAt']);

    final status = !enabled
        ? _CodeStatus.disabled
        : (expiresAt != null && !expiresAt.isAfter(DateTime.now()))
        ? _CodeStatus.expired
        : (max != null && count >= max)
        ? _CodeStatus.limitReached
        : _CodeStatus.active;
    final live = status == _CodeStatus.active;
    final scheme = Theme.of(context).colorScheme;

    final (statusText, statusColor) = switch (status) {
      _CodeStatus.active => ('Active', AppColors.correct),
      _CodeStatus.expired => ('Expired', AppColors.wrong),
      _CodeStatus.limitReached => ('Limit reached', AppColors.warning),
      _CodeStatus.disabled => ('Disabled', scheme.onSurfaceVariant),
    };

    final details = <String>[
      max == null ? '$count redeemed' : '$count of $max redeemed',
      if (expiresAt != null)
        status == _CodeStatus.expired
            ? 'expired ${_dateFmt.format(expiresAt)}'
            : 'valid till ${_dateFmt.format(expiresAt)}',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => unawaited(_showRedemptions(context, code, label)),
        title: Row(
          children: [
            Flexible(
              child: Text(
                code,
                style: AppTextStyles.h3().copyWith(
                  letterSpacing: 1,
                  color: live ? null : scheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Copy code',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) AppToast.showText(context, 'Copied $code');
              },
            ),
          ],
        ),
        subtitle: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$label\n'),
              TextSpan(
                text: statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: ' · $details'),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Switch(
          value: enabled,
          onChanged: (v) async {
            try {
              await service.setCodeActive(code, active: v);
            } on Object catch (e) {
              if (context.mounted) {
                AppToast.showText(
                  context,
                  TestSeriesPromoAdminService.describe(e),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _showRedemptions(
    BuildContext context,
    String code,
    String label,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _RedemptionsSheet(code: code, label: label),
    );
  }
}

class _RedemptionsSheet extends StatelessWidget {
  const _RedemptionsSheet({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('test_series_promos')
        .doc(code)
        .collection('redemptions')
        .orderBy('redeemedAt', descending: true)
        .limit(200)
        .snapshots();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('$code · $label', style: AppTextStyles.h3()),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Could not load: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Nobody has used this code yet.'),
                  );
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final at = _ts(d['redeemedAt']);
                    return ListTile(
                      dense: true,
                      title: Text(d['email']?.toString() ?? docs[i].id),
                      trailing: Text(
                        at == null ? '' : _dateTimeFmt.format(at),
                        style: AppTextStyles.caption(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create dialog
// ---------------------------------------------------------------------------

class _CodeInput {
  const _CodeInput({
    required this.label,
    this.code,
    this.maxRedemptions,
    this.expiresAt,
  });

  final String label;
  final String? code;
  final int? maxRedemptions;
  final DateTime? expiresAt;
}

/// Empty -> null. Otherwise a positive int, or null if it is not one.
int? _positiveInt(String raw) {
  final n = int.tryParse(raw.trim());
  return (n != null && n > 0) ? n : null;
}

class _CreateCodeDialog extends HookWidget {
  const _CreateCodeDialog();

  @override
  Widget build(BuildContext context) {
    final label = useTextEditingController();
    final code = useTextEditingController();
    final max = useTextEditingController();
    final lastDay = useState<DateTime?>(null);
    final error = useState<String?>(null);

    Future<void> pickDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: lastDay.value ?? now.add(const Duration(days: 30)),
        firstDate: now,
        lastDate: now.add(const Duration(days: 365 * 3)),
        helpText: 'Last day the code works',
      );
      if (picked != null) {
        lastDay.value = picked;
        error.value = null;
      }
    }

    void submit() {
      if (label.text.trim().isEmpty) {
        error.value = "Add a label, for example the influencer's name.";
        return;
      }
      if (max.text.trim().isNotEmpty && _positiveInt(max.text) == null) {
        error.value = 'Max people must be a whole number.';
        return;
      }
      // The chosen day is the last valid day: the code stops at its end.
      final d = lastDay.value;
      final expiresAt = d == null
          ? null
          : DateTime(d.year, d.month, d.day, 23, 59, 59);
      Navigator.of(context).pop(
        _CodeInput(
          label: label.text.trim(),
          code: code.text.trim().isEmpty ? null : code.text.trim(),
          maxRedemptions: _positiveInt(max.text),
          expiresAt: expiresAt,
        ),
      );
    }

    return AlertDialog(
      title: const Text('New offer code'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: label,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Label (who is it for?)',
                hintText: 'e.g. Rahul (YouTube)',
              ),
            ),
            TextField(
              controller: code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code (optional)',
                helperText: 'Leave empty to generate one, e.g. RAHUL50',
              ),
            ),
            TextField(
              controller: max,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max people (optional)',
                helperText: 'Empty means no limit',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    lastDay.value == null
                        ? 'No expiry date'
                        : 'Works till ${_dateFmt.format(lastDay.value!)}',
                  ),
                ),
                if (lastDay.value != null)
                  IconButton(
                    tooltip: 'Remove date',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => lastDay.value = null,
                  ),
                TextButton.icon(
                  onPressed: () => unawaited(pickDate()),
                  icon: const Icon(Icons.event_rounded),
                  label: Text(lastDay.value == null ? 'Set date' : 'Change'),
                ),
              ],
            ),
            if (error.value != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  error.value!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: submit, child: const Text('Create')),
      ],
    );
  }
}
