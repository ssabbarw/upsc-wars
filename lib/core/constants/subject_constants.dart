import 'package:flutter/material.dart';

/// Single source of truth for the six UPSC subjects (order, slugs, names, icons).
class SubjectDefinition {
  const SubjectDefinition({
    required this.slug,
    required this.displayName,
    required this.materialIcon,
  });

  final String slug;
  final String displayName;
  final IconData materialIcon;
}

abstract final class SubjectConstants {
  SubjectConstants._();

  /// Subject order aligned with shipped question bank data.
  static const List<SubjectDefinition> ordered = [
    SubjectDefinition(
      slug: 'Ancient History',
      displayName: 'Ancient History',
      materialIcon: Icons.history_edu_outlined,
    ),
    SubjectDefinition(
      slug: 'Medieval History',
      displayName: 'Medieval History',
      materialIcon: Icons.castle_outlined,
    ),
    SubjectDefinition(
      slug: 'Modern History',
      displayName: 'Modern History',
      materialIcon: Icons.account_balance_outlined,
    ),
    SubjectDefinition(
      slug: 'Art and Culture',
      displayName: 'Art and Culture',
      materialIcon: Icons.palette_outlined,
    ),
    SubjectDefinition(
      slug: 'Geography',
      displayName: 'Geography',
      materialIcon: Icons.public_outlined,
    ),
    SubjectDefinition(
      slug: 'Economy',
      displayName: 'Economy',
      materialIcon: Icons.trending_up_outlined,
    ),
    SubjectDefinition(
      slug: 'Environment',
      displayName: 'Environment',
      materialIcon: Icons.park_outlined,
    ),
    SubjectDefinition(
      slug: 'Polity',
      displayName: 'Polity',
      materialIcon: Icons.gavel_outlined,
    ),
  ];

  static SubjectDefinition? bySlug(String slug) {
    for (final s in ordered) {
      if (s.slug == slug) return s;
    }
    final normalized = slug.trim().toLowerCase();
    for (final s in ordered) {
      if (s.slug.toLowerCase() == normalized) return s;
    }
    return null;
  }
}
