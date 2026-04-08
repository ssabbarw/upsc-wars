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

  /// Polity → History → Geography → Economy → Environment → Science & Tech
  static const List<SubjectDefinition> ordered = [
    SubjectDefinition(
      slug: 'polity',
      displayName: 'Polity',
      materialIcon: Icons.account_balance_outlined,
    ),
    SubjectDefinition(
      slug: 'history',
      displayName: 'History',
      materialIcon: Icons.menu_book_outlined,
    ),
    SubjectDefinition(
      slug: 'geography',
      displayName: 'Geography',
      materialIcon: Icons.public_outlined,
    ),
    SubjectDefinition(
      slug: 'economy',
      displayName: 'Economy',
      materialIcon: Icons.trending_up_outlined,
    ),
    SubjectDefinition(
      slug: 'environment',
      displayName: 'Environment',
      materialIcon: Icons.park_outlined,
    ),
    SubjectDefinition(
      slug: 'science_tech',
      displayName: 'Science & Tech',
      materialIcon: Icons.science_outlined,
    ),
  ];

  static SubjectDefinition? bySlug(String slug) {
    for (final s in ordered) {
      if (s.slug == slug) return s;
    }
    return null;
  }
}
