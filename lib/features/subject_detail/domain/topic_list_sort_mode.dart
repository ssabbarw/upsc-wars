/// Sort order for the subject topics list.
enum TopicListSortMode {
  /// Lowest accuracy this season first; topics with no answers at the end.
  accuracy,

  /// Smallest share of tests finished first.
  coverage,

  /// By display name A–Z.
  alphabetical,
}
