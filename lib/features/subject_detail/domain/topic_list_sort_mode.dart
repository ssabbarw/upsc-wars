/// Sort order for the subject topics list.
enum TopicListSortMode {
  /// Lowest accuracy first; topics with no attempts at the end.
  accuracy,

  /// Most Danger Zone attempts (Sure + Educated-guess wrong, all-time) first.
  dangerZone,

  /// By display name A–Z.
  alphabetical,
}
