/// Sort order for the subject topics list.
enum TopicListSortMode {
  /// Highest accuracy this season first; topics with no answers at the end.
  accuracy,

  /// Most Sure + Educated-guess wrongs this season first.
  dangerZone,

  /// By display name A–Z.
  alphabetical,
}
