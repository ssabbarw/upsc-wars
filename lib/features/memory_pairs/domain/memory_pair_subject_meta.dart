import 'package:flutter/material.dart';

import 'memory_pair_models.dart';

/// Visual identity for a memory-pairs subject bucket (catalog grouping key).
class MemoryPairSubjectVisual {
  const MemoryPairSubjectVisual({
    required this.icon,
    required this.accent,
    required this.subtitleEn,
    required this.subtitleHi,
  });

  final IconData icon;
  final Color accent;
  final String subtitleEn;
  final String subtitleHi;

  String subtitleForLang(String lang) => lang == 'hi' ? subtitleHi : subtitleEn;
}

const _kSubjectVisuals = <String, MemoryPairSubjectVisual>{
  'Polity': MemoryPairSubjectVisual(
    icon: Icons.account_balance_outlined,
    accent: Color(0xFF1D9E75),
    subtitleEn: 'Learn important topics of Polity through memory pairs',
    subtitleHi: 'मेमोरी पेयर्स से राज्यव्यवस्था के महत्वपूर्ण विषय सीखें',
  ),
  'Ancient History': MemoryPairSubjectVisual(
    icon: Icons.temple_hindu_outlined,
    accent: Color(0xFF7C3AED),
    subtitleEn: 'Match dynasties, sites, and eras from ancient India',
    subtitleHi: 'प्राचीन भारत के राजवंश, स्थल और कालखंड मिलाएँ',
  ),
  'Modern History': MemoryPairSubjectVisual(
    icon: Icons.history_outlined,
    accent: Color(0xFFD97B3A),
    subtitleEn: 'Revise movements, viceroys, and modern-era facts',
    subtitleHi: 'आंदोलन, वायसराय और आधुनिक काल के तथ्य दोहराएँ',
  ),
  'Geography': MemoryPairSubjectVisual(
    icon: Icons.public_outlined,
    accent: Color(0xFF378ADD),
    subtitleEn: 'Pair rivers, capitals, deserts, and world geography',
    subtitleHi: 'नदियाँ, राजधानियाँ, मरुस्थल और विश्व भूगोल मिलाएँ',
  ),
  'Environment': MemoryPairSubjectVisual(
    icon: Icons.park_outlined,
    accent: Color(0xFF16A34A),
    subtitleEn: 'National parks, species, and environment facts',
    subtitleHi: 'राष्ट्रीय उद्यान, प्रजातियाँ और पर्यावरण तथ्य',
  ),
  'Science': MemoryPairSubjectVisual(
    icon: Icons.biotech_outlined,
    accent: Color(0xFF639922),
    subtitleEn: 'Instruments, vitamins, missions, and science recall',
    subtitleHi: 'यंत्र, विटामिन, मिशन और विज्ञान की याद',
  ),
  'Economy': MemoryPairSubjectVisual(
    icon: Icons.trending_up_outlined,
    accent: Color(0xFF0F6E56),
    subtitleEn: 'Schemes, revolutions, and economic organisations',
    subtitleHi: 'योजनाएँ, क्रांतियाँ और आर्थिक संगठन',
  ),
  'Current Affairs': MemoryPairSubjectVisual(
    icon: Icons.campaign_outlined,
    accent: Color(0xFF6366F1),
    subtitleEn: 'Government schemes and ministries at a glance',
    subtitleHi: 'सरकारी योजनाएँ और मंत्रालय एक नज़र में',
  ),
  'Art & Culture': MemoryPairSubjectVisual(
    icon: Icons.palette_outlined,
    accent: Color(0xFFD4537E),
    subtitleEn: 'Classical dances, art forms, and cultural pairings',
    subtitleHi: 'शास्त्रीय नृत्य, कला रूप और सांस्कृतिक जोड़े',
  ),
};

MemoryPairSubjectVisual memoryPairSubjectVisual(String subjectKey) {
  return _kSubjectVisuals[subjectKey] ??
      const MemoryPairSubjectVisual(
        icon: Icons.grid_view_rounded,
        accent: Color(0xFF1D9E75),
        subtitleEn: 'Match terms to answers and train recall',
        subtitleHi: 'शब्दों को उत्तरों से मिलाएँ और याददाश्त मजबूत करें',
      );
}

String memoryPairSetBlurb(MemoryPairSetDefinition set, String lang) {
  final n = set.difficulty.pairCount.clamp(0, set.pairs.length);
  if (lang == 'hi') {
    return '$n जोड़े मिलाएँ — ${set.subjectLabelForLang(lang)}';
  }
  return 'Match $n pairs — ${set.subjectLabelForLang(lang)}';
}
