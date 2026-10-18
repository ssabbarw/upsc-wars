import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../test_series/data/test_series_promo_admin_service.dart';
import '../../test_series/providers/test_series_providers.dart';

final _dateFmt = DateFormat('d MMM, h:mm a');

DateTime? _ts(Object? v) => v is Timestamp ? v.toDate() : null;

/// Super-user screen: give the Prelims Test Series away for free.
///
///  - "Free for everyone": opens an offer and pushes it to all installs.
///    Claiming it creates a permanent grant on the user's account.
///  - Promo codes (for example one per influencer) with live redemption counts
///    and the list of who redeemed.
class TestSeriesPromosAdminScreen extends HookConsumerWidget {
  const TestSeriesPromosAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(activeSeriesIdProvider);
    final service = useMemoized(TestSeriesPromoAdminService.new);

    return Scaffold(
      appBar: AppBar(title: const Text('Free test series')),
      body: seriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not read the active series.\n$e')),
        data: (seriesId) => _Body(seriesId: seriesId, service: service),
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

class _Body extends StatelessWidget {
  const _Body({required this.seriesId, required this.service});

  final String seriesId;
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
        final docs = snap.data?.docs ?? const [];
        var viaCodes = 0;
        var viaOffers = 0;
        for (final d in docs) {
          final n = (d.data()['redemptionCount'] as num?)?.toInt() ?? 0;
          if (d.data()['kind'] == 'open') {
            viaOffers += n;
          } else {
            viaCodes += n;
          }
        }
        final codes = docs.where((d) => d.data()['kind'] != 'open').toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            96,
          ),
          children: [
            Text('Series: $seriesId', style: AppTextStyles.caption()),
            const SizedBox(height: AppSpacing.md),
            _OfferCard(seriesId: seriesId, service: service),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: Text('Promo codes', style: AppTextStyles.h3())),
                Text(
                  '$viaCodes via codes · $viaOffers via offers',
                  style: AppTextStyles.caption(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (snap.hasError)
              Text('Could not load codes: ${snap.error}')
            else if (!snap.hasData)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (codes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'No codes yet. Tap "New code", then give it to an influencer.',
                  style: AppTextStyles.bodyMd(),
                ),
              )
            else
              for (final d in codes) _CodeTile(doc: d, service: service),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Free for everyone
// ---------------------------------------------------------------------------

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.seriesId, required this.service});

  final String seriesId;
  final TestSeriesPromoAdminService service;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final offerStream = FirebaseFirestore.instance
        .collection('test_series_open_offer')
        .doc(seriesId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: offerStream,
      builder: (context, snap) {
        final offer = snap.data?.data();
        final active = offer != null && offer['active'] == true;
        final expiresAt = _ts(offer?['expiresAt']);
        final live = active && (expiresAt == null || expiresAt.isAfter(DateTime.now()));
        final code = offer?['promoCode']?.toString();
        final notifiedAt = _ts(offer?['notifiedAt']);

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: live ? AppColors.correct : scheme.outlineVariant,
            ),
            color: live
                ? AppColors.correct.withValues(alpha: 0.08)
                : scheme.surfaceContainerLow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    live ? Icons.celebration_rounded : Icons.public_rounded,
                    color: live ? AppColors.correct : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      live ? 'Free for everyone: LIVE' : 'Free for everyone',
                      style: AppTextStyles.h3(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!live)
                Text(
                  'Everyone sees "Claim free access" and gets a push. Each claim '
                  'is saved to their account for good, so you can stop the offer '
                  'any time without taking anything away.',
                  style: AppTextStyles.bodySm(),
                )
              else ...[
                if (code != null) _OfferStats(code: code),
                Text(
                  notifiedAt == null
                      ? 'Push not sent yet.'
                      : 'Push sent ${_dateFmt.format(notifiedAt)}.',
                  style: AppTextStyles.bodySm(),
                ),
                if (expiresAt != null)
                  Text(
                    'Ends ${_dateFmt.format(expiresAt)}.',
                    style: AppTextStyles.bodySm(),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (!live)
                    FilledButton.icon(
                      onPressed: () => unawaited(_announce(context)),
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('Make free + notify'),
                    )
                  else ...[
                    OutlinedButton.icon(
                      onPressed: () => unawaited(_resend(context)),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(notifiedAt == null ? 'Send push' : 'Send push again'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => unawaited(_close(context)),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop offer'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _announce(BuildContext context) async {
    final input = await showDialog<_OfferInput>(
      context: context,
      builder: (_) => const _AnnounceDialog(),
    );
    if (input == null || !context.mounted) return;
    try {
      final result = await service.announce(
        seriesId: seriesId,
        title: input.title,
        body: input.body,
        notify: input.notify,
        maxRedemptions: input.maxRedemptions,
        expiresAt: input.expiresAt,
      );
      if (!context.mounted) return;
      AppToast.showText(
        context,
        result.notified
            ? 'Offer is live and the push went out.'
            : input.notify
            ? 'Offer is live, but the push failed (${result.pushError ?? 'unknown'}). '
                  'Use "Send push".'
            : 'Offer is live (no push sent).',
      );
    } on Object catch (e) {
      if (context.mounted) {
        AppToast.showText(context, TestSeriesPromoAdminService.describe(e));
      }
    }
  }

  Future<void> _resend(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Send the push to everyone?',
      message: 'Everyone with the app gets the notification again.',
      action: 'Send',
    );
    if (!ok || !context.mounted) return;
    try {
      await service.resendPush(seriesId);
      if (context.mounted) AppToast.showText(context, 'Push sent.');
    } on Object catch (e) {
      if (context.mounted) {
        AppToast.showText(context, TestSeriesPromoAdminService.describe(e));
      }
    }
  }

  Future<void> _close(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Stop the free offer?',
      message:
          'Nobody can claim it after this. People who already claimed keep '
          'their access.',
      action: 'Stop offer',
    );
    if (!ok || !context.mounted) return;
    try {
      await service.closeOffer(seriesId);
      if (context.mounted) AppToast.showText(context, 'Offer stopped.');
    } on Object catch (e) {
      if (context.mounted) {
        AppToast.showText(context, TestSeriesPromoAdminService.describe(e));
      }
    }
  }
}

class _OfferStats extends StatelessWidget {
  const _OfferStats({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('test_series_promos')
          .doc(code)
          .snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data();
        final n = (d?['redemptionCount'] as num?)?.toInt() ?? 0;
        final max = (d?['maxRedemptions'] as num?)?.toInt();
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            max == null ? '$n claimed' : '$n of $max claimed',
            style: AppTextStyles.h2(),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Codes
// ---------------------------------------------------------------------------

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
    final active = d['active'] == true;
    final expiresAt = _ts(d['expiresAt']);
    final expired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    final scheme = Theme.of(context).colorScheme;

    final details = <String>[
      max == null ? '$count redeemed' : '$count of $max redeemed',
      if (expiresAt != null)
        expired ? 'expired ${_dateFmt.format(expiresAt)}' : 'ends ${_dateFmt.format(expiresAt)}',
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
                  color: active && !expired ? null : scheme.onSurfaceVariant,
                  decoration: active && !expired ? null : TextDecoration.lineThrough,
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
        subtitle: Text('$label\n$details'),
        isThreeLine: true,
        trailing: Switch(
          value: active,
          onChanged: (v) async {
            try {
              await service.setCodeActive(code, active: v);
            } on Object catch (e) {
              if (context.mounted) {
                AppToast.showText(context, TestSeriesPromoAdminService.describe(e));
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
                  return const Center(child: Text('Nobody has used this code yet.'));
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
                        at == null ? '' : _dateFmt.format(at),
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
// Dialogs
// ---------------------------------------------------------------------------

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Empty -> null. Otherwise a positive int, or null if it is not one.
int? _positiveInt(String raw) {
  final n = int.tryParse(raw.trim());
  return (n != null && n > 0) ? n : null;
}

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

class _CreateCodeDialog extends HookWidget {
  const _CreateCodeDialog();

  @override
  Widget build(BuildContext context) {
    final label = useTextEditingController();
    final code = useTextEditingController();
    final max = useTextEditingController();
    final days = useTextEditingController();
    final error = useState<String?>(null);

    void submit() {
      if (label.text.trim().isEmpty) {
        error.value = 'Add a label, for example the influencer\'s name.';
        return;
      }
      if (max.text.trim().isNotEmpty && _positiveInt(max.text) == null) {
        error.value = 'Max redemptions must be a whole number.';
        return;
      }
      final d = _positiveInt(days.text);
      if (days.text.trim().isNotEmpty && d == null) {
        error.value = 'Expiry must be a whole number of days.';
        return;
      }
      Navigator.of(context).pop(
        _CodeInput(
          label: label.text.trim(),
          code: code.text.trim().isEmpty ? null : code.text.trim(),
          maxRedemptions: _positiveInt(max.text),
          expiresAt: d == null ? null : DateTime.now().add(Duration(days: d)),
        ),
      );
    }

    return AlertDialog(
      title: const Text('New promo code'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                labelText: 'Max redemptions (optional)',
              ),
            ),
            TextField(
              controller: days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Expires in days (optional)',
              ),
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

class _OfferInput {
  const _OfferInput({
    required this.notify,
    this.title,
    this.body,
    this.maxRedemptions,
    this.expiresAt,
  });

  final bool notify;
  final String? title;
  final String? body;
  final int? maxRedemptions;
  final DateTime? expiresAt;
}

class _AnnounceDialog extends HookWidget {
  const _AnnounceDialog();

  @override
  Widget build(BuildContext context) {
    final title = useTextEditingController();
    final body = useTextEditingController();
    final max = useTextEditingController();
    final days = useTextEditingController();
    final notify = useState(true);
    final error = useState<String?>(null);

    void submit() {
      if (max.text.trim().isNotEmpty && _positiveInt(max.text) == null) {
        error.value = 'Limit must be a whole number.';
        return;
      }
      final d = _positiveInt(days.text);
      if (days.text.trim().isNotEmpty && d == null) {
        error.value = 'Duration must be a whole number of days.';
        return;
      }
      Navigator.of(context).pop(
        _OfferInput(
          notify: notify.value,
          title: title.text,
          body: body.text,
          maxRedemptions: _positiveInt(max.text),
          expiresAt: d == null ? null : DateTime.now().add(Duration(days: d)),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Make it free for everyone'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Send a push to everyone'),
              value: notify.value,
              onChanged: (v) => notify.value = v,
            ),
            if (notify.value) ...[
              TextField(
                controller: title,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Push title (optional)',
                  hintText: 'Prelims 2027 Test Series is free for you',
                ),
              ),
              TextField(
                controller: body,
                maxLength: 180,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Push message (optional)',
                  hintText: 'Every test is unlocked for you. Tap to claim it.',
                ),
              ),
            ],
            TextField(
              controller: max,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Only the first N people (optional)',
              ),
            ),
            TextField(
              controller: days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Offer lasts (days, optional)',
              ),
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
        FilledButton(
          onPressed: submit,
          child: Text(notify.value ? 'Go live + notify' : 'Go live'),
        ),
      ],
    );
  }
}
