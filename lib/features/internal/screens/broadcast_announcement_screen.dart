import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/broadcast_announcement_cloud_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../notifications/broadcast_announcement_defaults.dart';
import '../../notifications/long_html_document.dart';
import '../../push_spot_test/push_spot_test_constants.dart';
import '../../push_spot_test/widgets/push_notification_preview_card.dart';

enum _SendHtmlChoice { saveThenSend, sendOnly, cancel }

/// Super-user composer: one HTML page, then an optional push.
class BroadcastAnnouncementScreen extends HookConsumerWidget {
  const BroadcastAnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    const service = BroadcastAnnouncementCloudService();
    final titleCtrl = useTextEditingController(
      text: BroadcastAnnouncementDefaults.title,
    );
    final bodyCtrl = useTextEditingController(
      text: BroadcastAnnouncementDefaults.body,
    );
    final htmlCtrl = useTextEditingController();
    final pageTab = useTabController(initialLength: 2);
    final openLongHtml = useState(true);
    final busy = useState(false);
    final lastSavedHtml = useState('');
    final savedHint = useState('Checking saved page…');

    useListenable(titleCtrl);
    useListenable(bodyCtrl);
    useListenable(htmlCtrl);
    useListenable(pageTab);

    Future<void> refreshSaved({bool intoEditor = true}) async {
      try {
        final saved = await service.loadSavedHtml();
        if (saved.isEmpty) {
          savedHint.value = 'Nothing saved yet. Paste a fragment and save.';
          lastSavedHtml.value = '';
          return;
        }
        lastSavedHtml.value = saved.html;
        savedHint.value = 'This is the live Long_Html_Message page.';
        if (intoEditor) {
          htmlCtrl.text = saved.html;
          if (saved.title.isNotEmpty && titleCtrl.text.trim().isEmpty) {
            titleCtrl.text = saved.title;
          }
          pageTab.animateTo(1);
        }
      } catch (_) {
        savedHint.value = 'Could not load the saved page.';
      }
    }

    useEffect(() {
      unawaited(refreshSaved());
      return null;
    }, const []);

    Future<void> saveHtml() async {
      final html = htmlCtrl.text.trim();
      if (html.isEmpty) {
        AppToast.showText(context, 'Paste the HTML fragment first.');
        return;
      }
      if (busy.value) return;
      busy.value = true;
      try {
        final outcome = await service.saveHtml(
          html: html,
          title: titleCtrl.text.trim(),
        );
        if (outcome.ok) lastSavedHtml.value = html;
        if (!context.mounted) return;
        AppToast.showText(context, outcome.userFacingMessage);
        if (outcome.ok) {
          savedHint.value = 'Saved. You can send the notification next.';
          pageTab.animateTo(1);
        }
      } finally {
        busy.value = false;
      }
    }

    Future<_SendHtmlChoice> chooseSendHtml() async {
      if (!openLongHtml.value) return _SendHtmlChoice.sendOnly;
      final editor = htmlCtrl.text.trim();
      if (editor.isNotEmpty && editor != lastSavedHtml.value.trim()) {
        final choice = await showDialog<_SendHtmlChoice>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unsaved HTML page'),
            content: const Text(
              'The editor is different from the saved page. '
              'Save it first, send using the already-saved page, or cancel.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(_SendHtmlChoice.cancel),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(_SendHtmlChoice.sendOnly),
                child: const Text('Send without saving'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(_SendHtmlChoice.saveThenSend),
                child: const Text('Save and send'),
              ),
            ],
          ),
        );
        return choice ?? _SendHtmlChoice.cancel;
      }
      if (lastSavedHtml.value.isEmpty && editor.isEmpty) {
        AppToast.showText(
          context,
          'Save an HTML page first, or turn off “Open saved HTML when they tap”.',
        );
        return _SendHtmlChoice.cancel;
      }
      return _SendHtmlChoice.sendOnly;
    }

    Future<void> send(BroadcastAnnouncementTarget target) async {
      final title = titleCtrl.text.trim();
      final body = bodyCtrl.text.trim();
      if (title.isEmpty || body.isEmpty) {
        AppToast.showText(context, 'Title and lock-screen body are required.');
        return;
      }
      final html = htmlCtrl.text.trim();
      final choice = await chooseSendHtml();
      if (choice == _SendHtmlChoice.cancel) return;
      if (target == BroadcastAnnouncementTarget.broadcast) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Broadcast to everyone?'),
            content: Text(
              'This notifies every device subscribed to '
              '"${PushSpotTestConstants.broadcastFcmTopic}". '
              'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Broadcast'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
      if (busy.value) return;
      busy.value = true;
      try {
        final saveWithSend = choice == _SendHtmlChoice.saveThenSend;
        final outcome = await service.send(
          BroadcastAnnouncementRequest(
            title: title,
            body: body,
            html: saveWithSend ? html : '',
            openLongHtml: openLongHtml.value,
            saveHtml: saveWithSend,
            target: target,
          ),
        );
        if (outcome.ok && saveWithSend) {
          lastSavedHtml.value = html;
          savedHint.value = 'Saved. Notification sent.';
        }
        if (!context.mounted) return;
        AppToast.showText(context, outcome.userFacingMessage);
      } finally {
        busy.value = false;
      }
    }

    final html = htmlCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Text(
            'Paste one HTML fragment. That is the whole Long HTML screen. '
            'Save it, then send a notification separately if you want.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Long HTML page', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.xs),
          Text(
            savedHint.value,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  controller: pageTab,
                  tabs: const [
                    Tab(text: 'HTML'),
                    Tab(text: 'Preview'),
                  ],
                ),
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    controller: pageTab,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: TextField(
                          controller: htmlCtrl,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            alignLabelWithHint: true,
                            hintText:
                                'Paste a fragment. No <html>, <head>, or <title>.',
                          ),
                        ),
                      ),
                      ColoredBox(
                        color: scheme.surface,
                        child: html.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Text(
                                    'Paste a fragment in HTML, then open Preview.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySm().copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: HtmlWidget(
                                  LongHtmlDocument.forHtmlWidget(html),
                                  textStyle: AppTextStyles.bodySm().copyWith(
                                    color: scheme.onSurface,
                                  ),
                                  onTapUrl: (url) async {
                                    final uri = Uri.tryParse(url);
                                    if (uri == null) return false;
                                    return launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonalIcon(
                onPressed: busy.value ? null : () => unawaited(saveHtml()),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save page'),
              ),
              OutlinedButton(
                onPressed: busy.value
                    ? null
                    : () => unawaited(refreshSaved(intoEditor: true)),
                child: const Text('Load saved'),
              ),
              TextButton(
                onPressed: () => context.push('/notification/long-html'),
                child: const Text('Open as users see it'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Notification', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: titleCtrl,
            maxLength: 120,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Title',
              helperText: 'Shown in the notification tray',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: bodyCtrl,
            maxLength: 180,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Lock-screen body',
              helperText: 'One short line under the title',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tray preview', style: AppTextStyles.label()),
          const SizedBox(height: AppSpacing.sm),
          PushNotificationPreviewCard(
            title: titleCtrl.text,
            body: bodyCtrl.text,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: openLongHtml.value,
            onChanged: (v) => openLongHtml.value = v,
            title: Text(
              'Open saved HTML when they tap',
              style: AppTextStyles.label(),
            ),
            subtitle: Text(
              'Opens this one page. Saving the page and sending the push stay separate.',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: busy.value
                ? null
                : () => unawaited(send(BroadcastAnnouncementTarget.self)),
            icon: busy.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.phone_iphone_outlined),
            label: const Text('Send notification to my phone'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.wrong,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: busy.value
                ? null
                : () => unawaited(send(BroadcastAnnouncementTarget.broadcast)),
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Send notification to everyone'),
          ),
        ],
      ),
    );
  }
}
