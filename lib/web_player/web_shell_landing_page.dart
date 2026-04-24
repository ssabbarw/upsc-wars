import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:upsc_wars/core/constants/app_constants.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/shared/extensions/context_extensions.dart';
import 'package:upsc_wars/shared/widgets/app_toast.dart';
import 'package:upsc_wars/shared/widgets/contact_us_entry.dart';
import 'package:upsc_wars/web_player/web_player_ui_tokens.dart';

/// Marketing home for the Flutter web shell when the URL is not a `/share/…` link.
class WebShellLandingPage extends StatefulWidget {
  const WebShellLandingPage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  static String iosStoreUrl() {
    final u = AppConstants.appStoreUrl.trim();
    return u.isNotEmpty
        ? u
        : 'https://apps.apple.com/search?term=${Uri.encodeComponent(AppConstants.appDisplayName)}';
  }

  @override
  State<WebShellLandingPage> createState() => _WebShellLandingPageState();
}

class _WebShellLandingPageState extends State<WebShellLandingPage> {
  String _lang = 'en'; // en | hi

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || ok) return;
    AppToast.showText(context, 'Could not open link:\n$url');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final w = MediaQuery.sizeOf(context).width;
    final maxW = w >= 1100 ? 1000.0 : (w >= 820 ? 880.0 : 680.0);
    final padH = w >= 820 ? AppSpacing.xxl : AppSpacing.lg;
    final isHi = _lang == 'hi';

    Text heading(String en, String hi) => Text(
          isHi ? hi : en,
          textAlign: TextAlign.center,
          style: AppTextStyles.h1().copyWith(
            fontSize: w >= 820 ? 42 : 30,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.onSurfaceDark : AppColors.primaryDeep,
            letterSpacing: -0.8,
            height: 1.08,
          ),
        );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.transparent,
        actions: [
          if (w >= 520)
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  _LangChip(
                    label: 'English',
                    selected: _lang == 'en',
                    onTap: () => setState(() => _lang = 'en'),
                  ),
                  const SizedBox(width: 6),
                  _LangChip(
                    label: 'हिन्दी',
                    selected: _lang == 'hi',
                    onTap: () => setState(() => _lang = 'hi'),
                  ),
                ],
              ),
            ),
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.gray900 : const Color(0xFFFAF8F5),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                padH,
                AppSpacing.xxl,
                padH,
                AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroBlock(
                      isHi: isHi,
                      heading: heading,
                      scheme: scheme,
                      isDark: isDark,
                      onScrollToVideo: () {
                        AppToast.showText(
                          context,
                          isHi ? 'डेमो वीडियो जल्द आ रहा है' : 'Demo video coming soon',
                          duration: const Duration(seconds: 3),
                        );
                      },
                      onOpenPlayStore: () =>
                          unawaited(_openUrl(AppConstants.playStoreUrl)),
                    ),
                    const SizedBox(height: 36),
                    _StatsRow(isHi: isHi),
                    const SizedBox(height: 48),
                    _SectionHeader(
                      titleEn: 'Why UPSC Wars is Different',
                      titleHi: 'UPSC Wars क्यों अलग है',
                      subtitleEn:
                          "We don't just give you answers. We teach you how to think like the examiner.",
                      subtitleHi:
                          'हम केवल उत्तर नहीं देते। हम आपको परीक्षक की तरह सोचना सिखाते हैं।',
                      isHi: isHi,
                    ),
                    const SizedBox(height: 20),
                    _FeaturesGrid(isHi: isHi),
                    const SizedBox(height: 48),
                    _SectionHeader(
                      titleEn: 'What Aspirants Are Saying',
                      titleHi: 'Aspirants क्या कह रहे हैं',
                      subtitleEn: '',
                      subtitleHi: '',
                      isHi: isHi,
                      centerSubtitle: true,
                    ),
                    const SizedBox(height: 20),
                    _ReviewsGrid(isHi: isHi),
                    const SizedBox(height: 48),
                    _BottomCta(
                      isHi: isHi,
                      onOpenPlayStore: () =>
                          unawaited(_openUrl(AppConstants.playStoreUrl)),
                      onOpenIos: () =>
                          unawaited(_openUrl(WebShellLandingPage.iosStoreUrl())),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      '${AppConstants.appDisplayName} · ${AppConstants.releaseVersionLabel}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : AppColors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.35)
                : AppColors.transparent,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : AppColors.surfacePrimaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({
    required this.isHi,
    required this.heading,
    required this.scheme,
    required this.isDark,
    required this.onScrollToVideo,
    required this.onOpenPlayStore,
  });

  final bool isHi;
  final Text Function(String en, String hi) heading;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onScrollToVideo;
  final VoidCallback onOpenPlayStore;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  'UPSC\nWARS',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption().copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppConstants.appDisplayName,
                  style: AppTextStyles.h3().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isHi ? 'GS Paper 1 • 25,000+ प्रश्न' : 'GS Paper 1 • 25,000+ Questions',
                style: AppTextStyles.caption().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          heading(
            'Stop Memorizing.\nStart Understanding.',
            'रटना बंद करें।\nसमझना शुरू करें।',
          ),
          const SizedBox(height: 12),
          Text(
            isHi
                ? 'हर सवाल के साथ जाल विश्लेषण, elimination तर्क, और concept anchors। UPSC aspirants द्वारा, aspirants के लिए बनाया गया।'
                : 'Every question comes with trap breakdowns, elimination logic, and concept anchors. Built by UPSC aspirants, for aspirants.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: WebPlayerUiTokens.primaryCta(context),
            onPressed: onScrollToVideo,
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text(isHi ? 'देखें यह कैसे काम करता है' : 'Watch How It Works'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: WebPlayerUiTokens.outlineFullWidth(context),
            onPressed: onOpenPlayStore,
            icon: const Icon(Icons.download_rounded),
            label: Text(isHi ? 'Play Store से डाउनलोड करें' : 'Download on Play Store'),
          ),
          if (w < 520) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: WebPlayerUiTokens.outlineFullWidth(context),
              onPressed: () => unawaited(
                launchUrl(
                  Uri.parse(WebShellLandingPage.iosStoreUrl()),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              icon: const Icon(Icons.apple, size: 22),
              label: Text(isHi ? 'App Store' : 'App Store'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.isHi});

  final bool isHi;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 820 ? 3 : 2;
    final items = <(String, String, String)>[
      ('25,000+', isHi ? 'गहन व्याख्या के साथ प्रश्न' : 'Questions with Deep Explanations', '🎯'),
      ('100%', isHi ? 'GS Paper 1 कवरेज' : 'GS Paper 1 Coverage', '📚'),
      ('2', isHi ? 'भाषाएं (अंग्रेजी + हिंदी)' : 'Languages (English + Hindi)', '🌐'),
    ];
    final shown = cols == 2 ? items.take(2).toList() : items;

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      alignment: WrapAlignment.center,
      children: [
        for (final it in shown)
          SizedBox(
            width: cols == 3 ? 260 : 260,
            child: _CardShell(
              child: Column(
                children: [
                  Text(it.$3, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(
                    it.$1,
                    style: AppTextStyles.h2().copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    it.$2,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption().copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.titleEn,
    required this.titleHi,
    required this.subtitleEn,
    required this.subtitleHi,
    required this.isHi,
    this.centerSubtitle = false,
  });

  final String titleEn;
  final String titleHi;
  final String subtitleEn;
  final String subtitleHi;
  final bool isHi;
  final bool centerSubtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      children: [
        Text(
          isHi ? titleHi : titleEn,
          textAlign: TextAlign.center,
          style: AppTextStyles.h2().copyWith(
            fontSize: w >= 820 ? 30 : 24,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        if ((isHi ? subtitleHi : subtitleEn).trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            isHi ? subtitleHi : subtitleEn,
            textAlign: centerSubtitle ? TextAlign.center : TextAlign.center,
            style: AppTextStyles.body().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturesGrid extends StatelessWidget {
  const _FeaturesGrid({required this.isHi});

  final bool isHi;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 820 ? 2 : 1;
    final items = <({String icon, String titleEn, String titleHi, String bodyEn, String bodyHi})>[
      (
        icon: '🎯',
        titleEn: 'Trap Breakdowns',
        titleHi: 'जाल विश्लेषण',
        bodyEn:
            'Every distractor is dissected. Learn exactly why wrong options are designed to trap you—and how to spot them instantly.',
        bodyHi:
            'हर distractor का विश्लेषण। जानें कि गलत विकल्प आपको फंसाने के लिए कैसे डिज़ाइन किए गए हैं—और उन्हें तुरंत कैसे पहचानें।',
      ),
      (
        icon: '📊',
        titleEn: 'Elimination Logic',
        titleHi: 'Elimination तर्क',
        bodyEn:
            'Step-by-step elimination strategy for multi-statement questions. Master the art of arriving at the right answer methodically.',
        bodyHi:
            'बहु-कथन प्रश्नों के लिए चरण-दर-चरण elimination रणनीति। सही उत्तर पर पद्धतिगत रूप से पहुंचने की कला में महारत हासिल करें।',
      ),
      (
        icon: '🧠',
        titleEn: 'Concept Anchors',
        titleHi: 'Concept Anchors',
        bodyEn:
            'Every question is linked to core concepts. Build deep, interconnected knowledge—not isolated facts.',
        bodyHi: 'हर प्रश्न मुख्य अवधारणाओं से जुड़ा है। गहरा, आपस में जुड़ा हुआ ज्ञान बनाएं—अलग-थलग तथ्य नहीं।',
      ),
      (
        icon: '🔄',
        titleEn: 'Smart Revision Queue',
        titleHi: 'Smart Revision Queue',
        bodyEn:
            'Questions automatically enter revision until you get them right 3 times on separate days. No manual tracking needed.',
        bodyHi:
            'प्रश्न स्वचालित रूप से revision में आते हैं जब तक आप उन्हें अलग-अलग दिनों पर 3 बार सही नहीं करते। मैनुअल ट्रैकिंग की आवश्यकता नहीं।',
      ),
      (
        icon: '📖',
        titleEn: 'Learning Mode',
        titleHi: 'Learning Mode',
        bodyEn:
            'See explanations immediately as you practice. Tap to select, confirm your choice, then learn—all in one flow.',
        bodyHi:
            'अभ्यास करते समय तुरंत व्याख्या देखें। चुनने के लिए tap करें, अपनी पसंद की पुष्टि करें, फिर सीखें—सब एक flow में।',
      ),
      (
        icon: '🌐',
        titleEn: 'Full Bilingual Support',
        titleHi: 'पूर्ण द्विभाषी समर्थन',
        bodyEn:
            'Every question, explanation, and trap breakdown available in both English and Hindi. Switch anytime.',
        bodyHi:
            'हर प्रश्न, व्याख्या, और जाल विश्लेषण अंग्रेजी और हिंदी दोनों में उपलब्ध। कभी भी switch करें।',
      ),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += cols) {
      final slice = items.skip(i).take(cols).toList();
      rows.add(
        Row(
          children: [
            for (var j = 0; j < slice.length; j++) ...[
              Expanded(
                child: _CardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slice[j].icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 10),
                      Text(
                        isHi ? slice[j].titleHi : slice[j].titleEn,
                        style: AppTextStyles.h3().copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isHi ? slice[j].bodyHi : slice[j].bodyEn,
                        style: AppTextStyles.bodySm().copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (j != slice.length - 1) const SizedBox(width: AppSpacing.lg),
            ],
            if (slice.length < cols)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
      rows.add(const SizedBox(height: AppSpacing.lg));
    }
    if (rows.isNotEmpty) rows.removeLast();
    return Column(children: rows);
  }
}

class _ReviewsGrid extends StatelessWidget {
  const _ReviewsGrid({required this.isHi});

  final bool isHi;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 820 ? 3 : 1;
    final items = <String>[
      isHi
          ? '“Trap breakdowns game‑changing हैं. अब समझ आता है कि गलती क्यों होती थी.”'
          : '"The trap breakdowns are game-changing. I finally understand why I was getting questions wrong."',
      isHi
          ? '“Best explanation depth. Elimination logic section अकेले में worth it.”'
          : '"Best explanation depth I\'ve seen. The elimination logic section alone is worth it."',
      isHi
          ? '“Learning mode exactly वही है जो चाहिए था. Aspirant‑first app.”'
          : '"Finally an app that treats me like an aspirant, not just a test-taker. The learning mode is exactly what I needed."',
    ];

    Widget card(String text) => _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('★★★★★', style: AppTextStyles.bodySm().copyWith(color: const Color(0xFFFBBF24))),
              const SizedBox(height: 10),
              Text(
                text,
                style: AppTextStyles.bodySm().copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isHi ? '— Play Store Reviewer' : '— Play Store Reviewer',
                style: AppTextStyles.caption().copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

    if (cols == 1) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            card(items[i]),
            if (i != items.length - 1) const SizedBox(height: AppSpacing.lg),
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: card(items[i])),
          if (i != items.length - 1) const SizedBox(width: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.isHi,
    required this.onOpenPlayStore,
    required this.onOpenIos,
  });

  final bool isHi;
  final VoidCallback onOpenPlayStore;
  final VoidCallback onOpenIos;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final row = w >= 520;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Text(
            isHi ? 'अपनी तैयारी को बदलने के लिए तैयार हैं?' : 'Ready to Transform Your Prep?',
            textAlign: TextAlign.center,
            style: AppTextStyles.h2().copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: w >= 820 ? 30 : 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isHi
                ? 'हजारों aspirants से जुड़ें जिन्होंने रटना बंद किया और समझना शुरू किया।'
                : 'Join thousands of aspirants who stopped memorizing and started understanding.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body().copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (row)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: onOpenPlayStore,
                    child: Text(isHi ? 'Play Store' : 'Google Play'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: onOpenIos,
                    child: const Text('App Store'),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: onOpenPlayStore,
                  child: Text(isHi ? 'Play Store' : 'Google Play'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: onOpenIos,
                  child: const Text('App Store'),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            isHi
                ? 'Aspirants द्वारा, aspirants के लिए बनाया गया।'
                : 'Built by aspirants, for aspirants.',
            style: AppTextStyles.caption().copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Theme(
            data: Theme.of(context).copyWith(
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            child: const ContactUsTextButton(
              linkLabel: 'Contact us',
            ),
          ),
        ],
      ),
    );
  }
}
