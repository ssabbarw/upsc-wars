import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Icon + accent for a practice topic. Keyword match first, then a stable
/// generic pair so the same topic always looks the same.
class PracticeTopicVisual {
  const PracticeTopicVisual({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;
}

PracticeTopicVisual practiceTopicVisual(String topic, {required bool isDark}) {
  final key = topic.toLowerCase();
  for (final rule in _rules) {
    if (rule.matches(key)) {
      return PracticeTopicVisual(
        icon: rule.icon,
        accent: isDark ? rule.accentDark : rule.accent,
      );
    }
  }
  final pair = _generic[topic.hashCode.abs() % _generic.length];
  return PracticeTopicVisual(
    icon: pair.icon,
    accent: isDark ? pair.accentDark : pair.accent,
  );
}

class _Rule {
  const _Rule(this.needles, this.icon, this.accent, this.accentDark);

  final List<String> needles;
  final IconData icon;
  final Color accent;
  final Color accentDark;

  bool matches(String key) {
    for (final needle in needles) {
      if (key.contains(needle)) return true;
    }
    return false;
  }
}

const _rules = <_Rule>[
  _Rule(
    [
      'climate',
      'sustain',
      'environment',
      'ecology',
      'biodiversity',
      'forest',
      'wildlife',
      'pollution',
      'conservation',
    ],
    Icons.eco_rounded,
    AppColors.correct,
    AppColors.correctTextDark,
  ),
  _Rule(
    ['agriculture', 'farm', 'crop', 'land reform', 'irrigation'],
    Icons.agriculture_rounded,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
  _Rule(
    [
      'capital market',
      'stock',
      'sebi',
      'share',
      'financial system',
      'financial market',
    ],
    Icons.show_chart_rounded,
    AppColors.info,
    AppColors.infoTextDark,
  ),
  _Rule(
    ['money', 'banking', 'rbi', 'monetary', 'credit', 'nbfc'],
    Icons.account_balance_rounded,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
  _Rule(
    [
      'external',
      'trade',
      'wto',
      'export',
      'import',
      'balance of payment',
      'forex',
      'fdi',
    ],
    Icons.public_rounded,
    AppColors.purple,
    AppColors.purpleTextDark,
  ),
  _Rule(
    ['budget', 'fiscal', 'tax', 'gst', 'public finance', 'deficit'],
    Icons.receipt_long_rounded,
    AppColors.info,
    AppColors.infoTextDark,
  ),
  _Rule(
    ['inflation', 'price', 'growth', 'gdp', 'national income', 'macro'],
    Icons.trending_up_rounded,
    AppColors.correct,
    AppColors.correctTextDark,
  ),
  _Rule(
    [
      'planning',
      'development',
      'niti',
      'five year',
      'poverty',
      'unemployment',
      'employment',
      'labour',
      'labor',
      'inclusive',
    ],
    Icons.account_tree_rounded,
    AppColors.info,
    AppColors.infoTextDark,
  ),
  _Rule(
    ['industry', 'manufacturing', 'infrastructure', 'msme', 'industrial'],
    Icons.factory_outlined,
    AppColors.gray600,
    AppColors.gray200,
  ),
  _Rule(
    ['constitution', 'preamble', 'amendment', 'basic structure'],
    Icons.menu_book_rounded,
    AppColors.info,
    AppColors.infoTextDark,
  ),
  _Rule(
    ['parliament', 'legislature', 'lok sabha', 'rajya sabha', 'bill'],
    Icons.account_balance_rounded,
    AppColors.purple,
    AppColors.purpleTextDark,
  ),
  _Rule(
    [
      'president',
      'prime minister',
      'executive',
      'council of minister',
      'governor',
    ],
    Icons.person_rounded,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
  _Rule(
    ['judiciary', 'supreme court', 'high court', 'judicial'],
    Icons.balance_rounded,
    AppColors.info,
    AppColors.infoTextDark,
  ),
  _Rule(
    ['rights', 'dpsp', 'duty', 'fundamental'],
    Icons.verified_rounded,
    AppColors.correct,
    AppColors.correctTextDark,
  ),
  _Rule(
    ['election', 'commission', 'franchise'],
    Icons.how_to_vote_rounded,
    AppColors.purple,
    AppColors.purpleTextDark,
  ),
  _Rule(
    [
      'federal',
      'centre-state',
      'center-state',
      'union',
      'panchayat',
      'municipality',
      'local government',
    ],
    Icons.location_city_rounded,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
  _Rule(
    ['emergency', 'schedule'],
    Icons.gavel_rounded,
    AppColors.wrong,
    AppColors.wrongTextDark,
  ),
  _Rule(
    [
      'river',
      'drainage',
      'ocean',
      'coast',
      'monsoon',
      'climate of',
      'atmosphere',
      'weather',
    ],
    Icons.water_drop_rounded,
    AppColors.info,
    AppColors.infoTextDark,
  ),
  _Rule(
    [
      'soil',
      'landform',
      'physiograph',
      'geomorph',
      'mountain',
      'plateau',
      'plain',
    ],
    Icons.terrain_rounded,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
  _Rule(
    ['population', 'settlement', 'migration', 'census', 'demograph'],
    Icons.groups_rounded,
    AppColors.purple,
    AppColors.purpleTextDark,
  ),
  _Rule(
    ['mineral', 'resource', 'energy', 'coal', 'petroleum'],
    Icons.diamond_outlined,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
  _Rule(
    ['map', 'location', 'india', 'world geography'],
    Icons.map_rounded,
    AppColors.correct,
    AppColors.correctTextDark,
  ),
  _Rule(
    ['dance', 'music', 'painting', 'art', 'theatre', 'craft'],
    Icons.palette_rounded,
    AppColors.purple,
    AppColors.purpleTextDark,
  ),
  _Rule(
    ['architecture', 'temple', 'stupa', 'monument'],
    Icons.account_balance_rounded,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
  _Rule(
    ['literature', 'language', 'script'],
    Icons.menu_book_rounded,
    AppColors.info,
    AppColors.infoTextDark,
  ),
  _Rule(
    ['religion', 'buddhism', 'jain', 'bhakti', 'sufi', 'philosophy'],
    Icons.self_improvement_rounded,
    AppColors.correct,
    AppColors.correctTextDark,
  ),
  _Rule(
    ['revolt', 'movement', 'freedom', 'nationalism', 'congress', 'gandhi'],
    Icons.flag_rounded,
    AppColors.wrong,
    AppColors.wrongTextDark,
  ),
  _Rule(
    [
      'empire',
      'dynasty',
      'sultan',
      'mughal',
      'kingdom',
      'chola',
      'maurya',
      'gupta',
    ],
    Icons.castle_rounded,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
  _Rule(
    ['society', 'caste', 'tribe', 'social'],
    Icons.groups_rounded,
    AppColors.purple,
    AppColors.purpleTextDark,
  ),
  _Rule(
    ['act', 'protocol', 'treaty', 'convention', 'law'],
    Icons.gavel_rounded,
    AppColors.info,
    AppColors.infoTextDark,
  ),
];

const _generic = <_Rule>[
  _Rule([], Icons.topic_outlined, AppColors.info, AppColors.infoTextDark),
  _Rule(
    [],
    Icons.auto_stories_outlined,
    AppColors.purple,
    AppColors.purpleTextDark,
  ),
  _Rule(
    [],
    Icons.school_outlined,
    AppColors.primary,
    AppColors.correctTextDark,
  ),
  _Rule(
    [],
    Icons.category_outlined,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
  _Rule(
    [],
    Icons.bookmark_outline_rounded,
    AppColors.correct,
    AppColors.correctTextDark,
  ),
  _Rule([], Icons.article_outlined, AppColors.info, AppColors.infoTextDark),
  _Rule(
    [],
    Icons.lightbulb_outline_rounded,
    AppColors.purple,
    AppColors.purpleTextDark,
  ),
  _Rule(
    [],
    Icons.inventory_2_outlined,
    AppColors.warning,
    AppColors.warningTextDark,
  ),
];
